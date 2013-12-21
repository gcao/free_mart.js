VERSION = '0.5.0'

NOT_FOUND       = {}
# will not look further if this is returned
NOT_FOUND_FINAL = {}
NO_PROVIDER     = {}

isDeferred = (o) -> typeof o?.promise is 'function'

extend = (dest, src) ->
  for own key, value of src
    dest[key] = value

stringifyCache = null
stringifyCallback = (key, value) ->
  if typeof value is "object" and value isnt null
    
    # Circular reference found, discard key
    return if stringifyCache.indexOf(value) >= 0
    
    # Store value in our collection
    stringifyCache.push value

  value

stringify = (o) ->
  stringifyCache = []
  result = JSON.stringify(o, stringifyCallback)
  stringifyCache = null
  result

toString = (obj...) ->
  result = stringify(obj)
  result.replace(/"/g, "'").substring(1, result.length - 1)

InUse =
  process: (key, options, args...) ->
    @market.log "InUse.process", key, options, args...
    try
      @in_use_keys.push key
      @process_ key, options, args...
    finally
      @in_use_keys.splice(@in_use_keys.indexOf(key), 1)

  processing: (key) ->
    @in_use_keys.indexOf(key) >= 0

class Registry
  constructor: (@market) ->
    @storage = []

  clear: ->
    @storage = []

  add: (key, provider) ->
    last = if @storage.length > 0 then @storage[@storage.length - 1]
    if last instanceof HashRegistry and not last.accept key
      last[key] = provider
    else
      if typeof key is 'string'
        child_registry = new HashRegistry(@market)
        child_registry[key] = provider
      else
        child_registry = new FuzzyRegistry(@market, key, provider)
      @storage.push child_registry

    provider

  removeProvider: (provider) ->
    for item, i in @storage
      if item instanceof HashRegistry
        item.removeProvider provider
        if item.isEmpty
          @storage.splice i, 1
      else if item.provider is provider
        @storage.splice(i, 1)

  accept: (key) ->
    for item in @storage
      if item.accept key then return true

  process: (key, options, args...) ->
    @market.log "Registry.process", key, options, args...

    if @storage.length is 0
      return NO_PROVIDER

    if options.all
      result = []
      processed = false
      for item in @storage
        continue unless item.accept key
        continue if item.processing key

        processed = true
        value = item.process key, options, args...
        result.push value unless value is NOT_FOUND

      if processed then result else NO_PROVIDER

    else
      processed = false
      for i in [@storage.length-1..0]
        item = @storage[i]
        continue unless item.accept key
        continue if item.processing key

        processed = true
        result = item.process key, options, args...
        if result is NOT_FOUND_FINAL
          break
        else if result isnt NOT_FOUND
          return result

      if processed then NOT_FOUND else NO_PROVIDER

class HashRegistry
  extend @.prototype, InUse

  constructor: (@market) ->
    @in_use_keys = []

  accept: (key) ->
    @[key]

  isEmpty: ->
    for own key of @
      return false if key isnt 'in_use_keys'
    true

  removeProvider: (provider) ->
    for own key, value of @
      if value is provider
        delete @[key]

  process_: (key, options, args...) ->
    @market.log "HashRegistry.process_", key, options, args...
    provider = @[key]
    return NO_PROVIDER unless provider
    try
      options.provider = provider
      provider.process options, args...
    finally
      delete options.provider

class FuzzyRegistry
  extend @.prototype, InUse

  constructor: (@market, @fuzzy_key, @provider) ->
    @in_use_keys = []

  accept: (key) ->
    @market.log "FuzzyRegistry.accept", key
    if @fuzzy_key instanceof RegExp
      key.match @fuzzy_key
    else if Object.prototype.toString.call(@fuzzy_key) is '[object Array]'
      for item in @fuzzy_key
        if item instanceof String
          return true if item is key
        else
          return true if key.match(item)

  process_: (key, options, args...) ->
    @market.log "FuzzyRegistry.process_", key, options, args...
    return NO_PROVIDER unless @accept key
    try
      options.provider = @provider
      @provider.process options, args...
    finally
      delete options.provider

class Provider
  constructor: (@market, @value) ->
    @market.log "Provider.constructor", @value

  process: (args...) ->
    @market.log "Provider.process", args...
    result =
      if typeof @value is 'function'
        @value args...
      else
        @value

    options = args[0]
    if options?.async
      if isDeferred result
        result
      else
        new Deferred().resolve(result)
    else
      result

  deregister: ->
    FreeMart.deregister @

class ValueProvider extends Provider
  process: (args...) ->
    @market.log "ValueProvider.process", args...
    result = @value

    options = args[0]
    if options?.async
      new Deferred().resolve(result)
    else
      result

# Registrations are stored based on order
# fuzzy => hash => fuzzy
# Providers can be deregistered
class FreeMartInternal
  constructor: (@name) ->
    @name ||= 'Black Market'
    @queues = {}
    @registry = new Registry(@)
    @disableLog()

  register: (key, value) ->
    @log 'register', key, value
    provider = new Provider(@, value)
    @registry.add key, provider
    if @queues[key]
      for request in @queues[key]
        @log 'register - deferred request', key, request.args...
        result = @registry.process key, {async: true}, request.args...
        @log 'register - deferred request result', result
        if result is NOT_FOUND
          throw "NOT FOUND: #{key}"
        else if isDeferred result
          # Use a closure to ensure request in the callback is not changed
          # by the iterator to another
          func = (req) ->
            result.then(
              (v...) -> req.resolve(v...)
            , (v...) -> req.reject(v...)
            )
          func(request)
        else
          request.resolve(result)
      delete @queues[key]

    provider

  value: (key, value) ->
    @log 'value', key, value
    provider = new ValueProvider(@, value)
    @registry.add key, provider
    if @queues[key]
      for request in @queues[key]
        @log 'register - deferred request', key, request.args...
        result = @registry.process key, {async: true}, request.args...
        @log 'register - deferred request result', result
        if result is NOT_FOUND
          throw "NOT FOUND: #{key}"
        else if isDeferred result
          # Use a closure to ensure request in the callback is not changed
          # by the iterator to another
          func = (req) ->
            result.then(
              (v...) -> req.resolve(v...)
            , (v...) -> req.reject(v...)
            )
          func(request)
        else
          request.resolve(result)
      delete @queues[key]

    provider

  deregister: (provider) ->
    @log 'deregister', provider
    @registry.removeProvider(provider)

  request: (key, args...) ->
    @log 'request', key, args...
    result = @registry.process key, {}, args...
    if result is NO_PROVIDER
      throw "NO PROVIDER: #{key}"
    else if result is NOT_FOUND
      throw "NOT FOUND: #{key}"
    else
      result

  createDeferredRequest = (key, args...) ->
    request = new Deferred()
    request.key = key
    request.args = args
    request

  requestAsync: (key, args...) ->
    @log 'requestAsync', key, args...
    result = @registry.process key, {async: true}, args...
    if result is NO_PROVIDER
      request = createDeferredRequest key, args...
      @queues[key] ||= []
      @queues[key].push request
      request
    else if result is NOT_FOUND
      throw "NOT FOUND: #{key}"
    else
      result

  requestMulti: (keyAndArgs...) ->
    @log 'requestMulti', keyAndArgs...
    for keyAndArg in keyAndArgs
      if Object.prototype.toString.call(keyAndArg) is '[object Array]'
        @request keyAndArg...
      else
        @request keyAndArg

  requestMultiAsync: (keyAndArgs...) ->
    @log 'requestMultiAsync', keyAndArgs...
    requests =
      for keyAndArg in keyAndArgs
        if typeof keyAndArg is 'object' and keyAndArg.length
          @requestAsync keyAndArg...
        else
          @requestAsync keyAndArg

    Deferred.when requests...

  requestAll: (key, args...) ->
    @log 'requestAll', key, args...
    @registry.process key, {all: true}, args...

  requestAllAsync: (key, args...) ->
    @log 'requestAllAsync', key, args...
    result = new Deferred()

    requests = @registry.process key, {all: true, async: true}, args...
    Deferred.when(requests...).then(
      (results...) -> result.resolve(results)
    , (results...) -> result.reject(results)
    )

    result

  registerAsync: (key, value) ->
    @log 'registerAsync', key, value
    @register key, (args...) ->
      if isDeferred value
        return value

      result = new Deferred()

      if typeof value is 'function'
        options = args[0]
        options.deferred = result
        value(args...)
      else
        result.resolve(value)

      result

  clear: -> @registry.clear()

  log: (args...) ->
    operation = args.shift()
    console.log "#{@name} - #{operation}: #{toString args...}"

  disableLog: ->
    unless @log_
      @log_ = @log
      @log  = ->

  enableLog: ->
    if @log_
      @log = @log_
      delete @log_

  NOT_FOUND      : NOT_FOUND
  NOT_FOUND_FINAL: NOT_FOUND_FINAL
  VERSION        : VERSION

# aliases
FreeMartInternal.prototype.req           = FreeMartInternal.prototype.request
FreeMartInternal.prototype.reqAsync      = FreeMartInternal.prototype.requestAsync
FreeMartInternal.prototype.reqMulti      = FreeMartInternal.prototype.requestMulti
FreeMartInternal.prototype.reqMultiAsync = FreeMartInternal.prototype.requestMultiAsync
FreeMartInternal.prototype.reqAll        = FreeMartInternal.prototype.requestAll
FreeMartInternal.prototype.reqAllAsync   = FreeMartInternal.prototype.requestAllAsync

@FreeMart       = new FreeMartInternal('Free Mart')
@FreeMart.clone = (name) -> new FreeMartInternal(name)

