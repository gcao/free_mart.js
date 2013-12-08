NOT_FOUND       = {}
# will not look further if this is returned
NOT_FOUND_FINAL = {}
NO_PROVIDER     = {}

isDeferred = (o) -> typeof o?.promise is 'function'

extend = (dest, src) ->
  for own key, value of src
    dest[key] = value

toString = (obj...) ->
  result = JSON.stringify(obj).replace(/"/g, "'")
  result.substring(1, result.length - 1)

InUse =
  process: (key, options, args...) ->
    FreeMart.log "InUse.process(#{toString key, options, args...})"
    try
      @in_use_keys.push key
      @process_ key, options, args...
    finally
      @in_use_keys.splice(@in_use_keys.indexOf(key), 1)

  processing: (key) ->
    @in_use_keys.indexOf(key) >= 0

class Registry
  constructor: ->
    @storage = []

  clear: ->
    @storage = []

  add: (key, provider) ->
    last = if @storage.length > 0 then @storage[@storage.length - 1]
    if last instanceof HashRegistry and not last.accept key
      last[key] = provider
    else
      if typeof key is 'string'
        child_registry = new HashRegistry()
        child_registry[key] = provider
      else
        child_registry = new FuzzyRegistry key, provider
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
    FreeMart.log "Registry.process(#{toString key, options, args...})"

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

  constructor: ->
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
    FreeMart.log "HashRegistry.process_(#{toString key, options, args...})"
    provider = @[key]
    return NO_PROVIDER unless provider
    try
      options.provider = provider
      provider.process options, args...
    finally
      delete options.provider

class FuzzyRegistry
  extend @.prototype, InUse

  constructor: (@fuzzy_key, @provider) ->
    @in_use_keys = []

  accept: (key) ->
    FreeMart.log "FuzzyRegistry.accept(#{key})"
    if @fuzzy_key instanceof RegExp
      key.match @fuzzy_key
    else if Object.prototype.toString.call(@fuzzy_key) is '[object Array]'
      for item in @fuzzy_key
        if item instanceof String
          return true if item is key
        else
          return true if key.match(item)

  process_: (key, options, args...) ->
    FreeMart.log "FuzzyRegistry.process_(#{toString key, options, args...})"
    return NO_PROVIDER unless @accept key
    try
      options.provider = @provider
      @provider.process options, args...
    finally
      delete options.provider

class Provider
  constructor: (@value) ->
    FreeMart.log "Provider.constructor(#{toString @value})"

  process: (args...) ->
    FreeMart.log "Provider.process(#{toString args...})"
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

# Registrations are stored based on order
# fuzzy => hash => fuzzy
# Providers can be deregistered
class this.FreeMart
  queues = {}
  registry = new Registry()

  @register: (key, value) ->
    FreeMart.log "FreeMart.register(#{toString key, value})"
    provider = new Provider(value)
    registry.add key, provider
    if queues[key]
      for request in queues[key]
        FreeMart.log "Deferred request: #{toString key, request.args...}"
        result = registry.process key, {async: true}, request.args...
        FreeMart.log "Deferred request result: #{toString result}"
        if result is NOT_FOUND
          throw "NOT FOUND: #{key}"
        else if isDeferred result
          # Use a closure to ensure request in the callback is not changed
          # by the iterator to another
          func = (req) ->
            result.then (v) -> req.resolve(v)
          func(request)
        else
          request.resolve(result)
      delete queues[key]

    provider

  @deregister: (provider) ->
    FreeMart.log "FreeMart.deregistere(#{toString provider})"
    registry.removeProvider(provider)

  @request: (key, args...) ->
    FreeMart.log "FreeMart.request(#{toString key, args...})"
    result = registry.process key, {}, args...
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

  @requestAsync: (key, args...) ->
    FreeMart.log "FreeMart.requestAsync(#{toString key, args...})"
    result = registry.process key, {async: true}, args...
    if result is NO_PROVIDER
      request = createDeferredRequest key, args...
      queues[key] ||= []
      queues[key].push request
      request
    else if result is NOT_FOUND
      throw "NOT FOUND: #{key}"
    else
      result

  @requestMulti: (keyAndArgs...) ->
    FreeMart.log "FreeMart.requestMulti(#{toString keyAndArgs})"
    for keyAndArg in keyAndArgs
      if Object.prototype.toString.call(keyAndArg) is '[object Array]'
        @request keyAndArg...
      else
        @request keyAndArg

  @requestMultiAsync: (keyAndArgs...) ->
    FreeMart.log "FreeMart.requestAsyncMulti(#{toString keyAndArgs})"
    requests =
      for keyAndArg in keyAndArgs
        if typeof keyAndArg is 'object' and keyAndArg.length
          @requestAsync keyAndArg...
        else
          @requestAsync keyAndArg

    Deferred.when requests...

  @requestAll: (key, args...) ->
    FreeMart.log "FreeMart.requestAll(#{toString key, args...})"
    registry.process key, {all: true}, args...

  @requestAllAsync: (key, args...) ->
    FreeMart.log "FreeMart.requestAllAsync(#{toString key, args...})"
    result = new Deferred()

    requests = registry.process key, {all: true, async: true}, args...
    Deferred.when(requests...).then (results...) ->
      result.resolve(results)

    result

  @registerAsync: (key, value) ->
    FreeMart.log "FreeMart.registerAsync(#{toString key, value})"
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

  @clear: -> registry.clear()

  @log: ->

  @NOT_FOUND       = NOT_FOUND
  @NOT_FOUND_FINAL = NOT_FOUND_FINAL

  # aliases
  @req          : @request
  @reqAsync     : @requestAsync
  @reqMulti     : @requestMulti
  @reqMultiAsync: @requestMultiAsync
  @reqAll       : @requestAll
  @reqAllAsync  : @requestAllAsync

