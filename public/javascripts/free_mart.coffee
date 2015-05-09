VERSION = '0.5.0'

NOT_FOUND       = {}
# will not look further if this is returned
NOT_FOUND_FINAL = {}
NO_PROVIDER     = {}

isDeferred = (o) -> typeof o?.promise is 'function'

extend = (dest, src) ->
  for own key, value of src
    dest[key] = value

stringifyCache    = null
stringifyCallback = (key, value) ->
  if typeof value is "object" and value isnt null

    # Circular reference found, discard key
    return if stringifyCache.indexOf(value) >= 0

    # Store value in our collection
    stringifyCache.push value

  value

stringify = (o) ->
  stringifyCache = []
  result         = JSON.stringify(o, stringifyCallback)
  stringifyCache = null
  result

toString = (obj...) ->
  result = stringify(obj)
  result.replace(/"/g, "'").substring(1, result.length - 1)

InUse =
  process: (options, args...) ->
    @market.log "InUse.process", options, args...
    try
      @in_use_keys.push options.$key
      @process_ options, args...
    finally
      @in_use_keys.splice(@in_use_keys.indexOf(options.$key), 1)

  processing: (key) ->
    @in_use_keys.indexOf(key) >= 0

class Registry
  constructor: (@market) ->
    @storage = []

  clear: ->
    @storage = []
    delete @default

  add: (key, provider) ->
    last = if @storage.length > 0 then @storage[@storage.length - 1]
    # TODO: draw a diagram and refactor this to make the logic more clear
    if last instanceof HashRegistry and typeof key is 'string' and not last.accept key
      last[key] = provider
    else
      if typeof key is 'string'
        child_registry = new HashRegistry(@market)
        child_registry[key] = provider
      else if typeof key is 'function'
        child_registry = new CallbackRegistry(@market, key, provider)
      else if typeof key is 'undefined'
        child_registry = new SimpleRegistry(@market, provider)
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

  process: (options, args...) ->
    @market.log "Registry.process", options, args...

    if @storage.length is 0
      if @default
        if @default.hasOwnProperty 'value'
          return @default.value
        else if @default.hasOwnProperty 'callback'
          return @default.callback(options, args...)
        else if @default.hasOwnProperty 'factory'
          return new @default.factory(@options, args...)

      return NO_PROVIDER

    if options.$all
      result    = []
      processed = false
      for item in @storage
        if item.accept
          continue unless item.accept options.$key
          continue if item.processing options.$key

          processed = true
          value = item.process options, args...
          result.push value unless value is NOT_FOUND
        else
          # the provider uses one function to match key and return result
          # TODO

      if processed then result else NO_PROVIDER

    else
      processed = false
      for i in [@storage.length-1..0]
        item = @storage[i]
        continue if item.processing options.$key

        if item.accept
          continue unless item.accept options.$key

          processed = true
          result    = item.process options, args...
          if result is NOT_FOUND_FINAL
            break
          else if result isnt NOT_FOUND
            return result

        else
          # the provider uses one function to match key and return result
          result = item.process options, args...
          if result is NOT_FOUND_FINAL
            processed = true
            break
          else if result isnt NOT_FOUND
            processed = true
            return result

      if @default
        return @default(options, args...)

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

  process_: (options, args...) ->
    @market.log "HashRegistry.process_", options, args...
    provider = @[options.$key]
    return NO_PROVIDER unless provider
    try
      options.$provider = provider
      provider.process options, args...
    finally
      delete options.$provider

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

  process_: (options, args...) ->
    @market.log "FuzzyRegistry.process_", options, args...
    return NO_PROVIDER unless @accept options.$key
    try
      options.$provider = @provider
      @provider.process options, args...
    finally
      delete options.$provider

class CallbackRegistry
  extend @.prototype, InUse

  constructor: (@market, @callback, @provider) ->
    @in_use_keys = []

  accept: (key) ->
    @market.log "CallbackRegistry.accept", key
    @callback(key)

  process_: (options, args...) ->
    @market.log "CallbackRegistry.process_", options, args...
    return NO_PROVIDER unless @accept options.$key
    try
      options.$provider = @provider
      @provider.process options, args...
    finally
      delete options.$provider

class SimpleRegistry
  extend @.prototype, InUse

  constructor: (@market, @provider) ->
    @in_use_keys = []

  process_: (options, args...) ->
    @market.log "SimpleRegistry.process_", options, args...
    try
      options.$provider = @provider
      @provider.process options, args...
    finally
      delete options.$provider

class Provider
  constructor: (@market, @options, @value) ->
    @market.log "Provider.constructor", @options, @value

    if @options.$async and @options.$type
      console.log "Bad provider: $async=#{@options.$async}, $type=#{@options.$type}"

    if @options.$async
      value = @value
      @value = (args...) ->
        result = new Deferred()

        if typeof value is 'function'
          options = args[0]
          options.$deferred = result
          value(args...)
        else
          result.resolve(value)

        result

    return

  process: (args...) ->
    @market.log "Provider.process", args...
    result =
      if @options.$type is 'value'
        @value
      else if @options.$type is 'factory' and typeof @value is 'function'
        new @value args...
      #else if (typeof @value is 'object' or typeof @value is 'function') and typeof @value.$get is 'function'
      #  @value.$get(args...)
      else if typeof @value is 'function'
        @value args...
      else
        @value

    options = args[0]
    if options?.$async
      if isDeferred result
        result
      else
        new Deferred().resolve(result)
    else
      result

  deregister: ->
    @market.registry.removeProvider @

# Registrations are stored based on order
# fuzzy => hash => fuzzy
# Providers can be deregistered
class FreeMartInternal
  constructor: (@name) ->
    @name   ||= 'Black Market'
    @queues   = {}
    @registry = new Registry(@)
    @disableLog()

  register: (key, options, value) ->
    @log 'register', key, options, value

    if arguments.length is 1
      options = {}
    else if arguments.length is 2
      value = options
      options = {}

    provider = new Provider(@, options, value)
    @registry.add key, provider

    if @queues[key]
      for request in @queues[key]
        @log 'register - deferred request', key, request.args...
        result = @registry.process {$key: key, $async: true}, request.args...
        @log 'register - deferred request result', result
        if result is NOT_FOUND
          throw "NOT FOUND: #{key}"
        else if isDeferred result
          do (request) ->
            successCallback = (v...) -> request.resolve(v...)
            failureCallback = (v...) -> request.reject(v...)
            result.then successCallback, failureCallback
        else
          request.resolve(result)

      delete @queues[key]

    provider

  value: (key, value) ->
    @log 'value', key, value
    @register key, {$type: 'value'}, value

  factory: (key, value) ->
    @log 'factory', key, value
    @register key, {$type: 'factory'}, value

  #provider: (provider) ->
  #  @log 'provider', provider

  #  if typeof provider is 'function'
  #    return @register undefined, {}, provider

  #  unless provider.hasOwnProperty('$accept') and provider.hasOwnProperty('$get')
  #    throw 'Invalid provider: $accept and $get are required'

  #  key = provider.$accept
  #  key = key.bind(provider) if typeof key is 'function'

  #  options = {}
  #  options.$async = provider.$async if provider.hasOwnProperty '$async'
  #  options.$type  = provider.$type  if provider.hasOwnProperty '$type'

  #  value = provider.$get
  #  value = value.bind(provider) if typeof value is 'function'

  #  @register key, options, value

  default: (callback) ->
    @registry.default = callback

  registerAsync: (key, value) ->
    @log 'registerAsync', key, value
    @register key, {$async: true}, value

  handleFirstArg = (arg, all, async) ->
    options = {}
    if typeof arg is 'string'
      options.$key = arg
    else
      for own key, value of arg
        if key.indexOf('$') isnt 0 or ['$key', '$all', '$async'].indexOf(key) >= 0
          options[key] = value

    # requestAll/requestAsync/requestAllAsync
    if all or async
      delete options.$all
      delete options.$async
      if all   then options.$all   = true
      if async then options.$async = true

    options

  request: (key, args...) ->
    @log 'request', key, args...
    result = @registry.process handleFirstArg(key), args...
    if result is NO_PROVIDER
      throw "NO PROVIDER: #{key}"
    else if result is NOT_FOUND
      throw "NOT FOUND: #{key}"
    else
      result

  createDeferredRequest = (key, args...) ->
    request      = new Deferred()
    request.key  = key
    request.args = args
    request

  requestAsync: (key, args...) ->
    @log 'requestAsync', key, args...
    result = @registry.process handleFirstArg(key, false, true), args...
    if result is NO_PROVIDER
      request = createDeferredRequest key, args...
      @queues[key] ||= []
      @queues[key].push request
      request
    else if result is NOT_FOUND
      throw "NOT FOUND: #{key}"
    else
      result

  requestAll: (key, args...) ->
    @log 'requestAll', key, args...
    @registry.process handleFirstArg(key, true, false), args...

  requestAllAsync: (key, args...) ->
    @log 'requestAllAsync', key, args...
    result = new Deferred()

    requests = @registry.process handleFirstArg(key, true, true), args...
    Deferred.when(requests...).then(
      (results...) -> result.resolve(results)
    , (results...) -> result.reject(results)
    )

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
FreeMartInternal.prototype.reg           = FreeMartInternal.prototype.register
FreeMartInternal.prototype.regAsync      = FreeMartInternal.prototype.registerAsync
FreeMartInternal.prototype.req           = FreeMartInternal.prototype.request
FreeMartInternal.prototype.reqAsync      = FreeMartInternal.prototype.requestAsync
FreeMartInternal.prototype.reqAll        = FreeMartInternal.prototype.requestAll
FreeMartInternal.prototype.reqAllAsync   = FreeMartInternal.prototype.requestAllAsync

@FreeMart        = new FreeMartInternal('Free Mart')
@FreeMart.create = (name) -> new FreeMartInternal(name)

