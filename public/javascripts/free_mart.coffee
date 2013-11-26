NOT_FOUND   = {}
NO_PROVIDER = {}

toString = (obj...) ->
  result = JSON.stringify(obj).replace(/"/g, "'")
  result.substring(1, result.length - 1)

isDeferred = (o) -> typeof o?.promise is 'function'

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
        return result unless result is NOT_FOUND

      if processed then NOT_FOUND else NO_PROVIDER

    #if options.all
    #  result = []
    #  for item in @
    #    item_result = item.process key, options, args...
    #    result.push item_result unless item_result == NOT_FOUND
    #  result
    #else
    #  reverse_each do |item|
    #    next if item.processing? key
    #    result = item.process key, options, *args
    #    return result unless result == NOT_FOUND
    #  end
    #  NOT_FOUND

class HashRegistry
  for own key, value of InUse
    @.prototype[key] = value

  constructor: ->
    @in_use_keys = []

  accept: (key) ->
    @[key]

  process_: (key, options, args...) ->
    FreeMart.log "HashRegistry.process_(#{toString key, options, args...})"
    provider = @[key]
    return NO_PROVIDER unless provider
    provider.process options, args...

class FuzzyRegistry
  for own key, value of InUse
    @.prototype[key] = value

  constructor: (@fuzzy_key, @provider) ->
    @in_use_keys = []

  accept: (key) ->
    FreeMart.log "FuzzyRegistry.accept(#{key})"
    if @fuzzy_key instanceof RegExp
      key.match @fuzzy_key
    else if @fuzzy_key instanceof Array
      for item in @fuzzy_key
        if item instanceof String
          return true if item is key
        else
          return true if key.match(item)

  process_: (key, options, args...) ->
    FreeMart.log "FuzzyRegistry.process_(#{toString key, options, args...})"
    return NO_PROVIDER unless @accept key
    @provider.process options, args...

class Provider
  constructor: (@key, @value) ->
    FreeMart.log "Provider.constructor(#{toString @key, @value})"

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

# Registration are stored based on order
# regexp => hash => regexp
# Providers can be deregistered
class this.FreeMart
  queues = {}
  registry = new Registry()

  @register: (key, value) ->
    FreeMart.log "FreeMart.register(#{toString key, value})"
    registry.add key, new Provider(key, value)
    if queues[key]
      for request in queues[key]
        FreeMart.log "Deferred request: #{toString key, request.args...}"
        result = registry.process key, {async: true}, request.args...
        FreeMart.log "Deferred request result: #{toString result}"
        if result is NOT_FOUND
          throw "NOT FOUND: #{key}"
        else if isDeferred result
          # How do we ensure request in the callback is not changed
          # by the iterator to another
          func = (req) ->
            result.then (v) -> req.resolve(v)
          func(request)
        else
          request.resolve(result)
      delete queues[key]
    #if queues.hasOwnProperty key
    #  queue = queues[key]
    #  delete queues[key]
    #  for item in queue
    #    deferred = item.shift()
    #    if typeof value is 'function'
    #      result = value(item...)
    #      if typeof result?.promise is 'function'
    #        # Save a reference to deferred because it might be changed
    #        deferred2 = deferred
    #        result.done (newResult) ->
    #          deferred2.resolve newResult
    #      else
    #        deferred.resolve result
    #    else if typeof value?.promise is 'function'
    #      value.done (result) ->
    #        deferred.resolve result
    #    else
    #      deferred.resolve value

  @request: (key, args...) ->
    FreeMart.log "FreeMart.request(#{toString key, args...})"
    registry.process key, {}, args...

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

    #if registry.hasOwnProperty key
    #  value = registry[key]
    #  if typeof value is 'function'
    #    result = value(args...)
    #    if typeof result?.promise is 'function'
    #      result
    #    else
    #      new Deferred().resolve result
    #  else if typeof value?.promise is 'function'
    #    value
    #  else
    #    new Deferred().resolve value
    #else
    #  deferred = new Deferred()

    #  args.unshift deferred
    #  if queues.hasOwnProperty key
    #    queues[key].push args
    #  else
    #    queues[key] = [args]

    #  deferred

  @requestMulti: (keyAndArgs...) ->
    FreeMart.log "FreeMart.requestMulti(#{toString keyAndArgs})"
    for keyAndArg in keyAndArgs
      if typeof keyAndArg is 'object' and keyAndArg.length
        @request keyAndArg...
      else
        @request keyAndArg

  @requestAsyncMulti: (keyAndArgs...) ->
    FreeMart.log "FreeMart.requestAsyncMulti(#{toString keyAndArgs})"
    requests =
      for keyAndArg in keyAndArgs
        if typeof keyAndArg is 'object' and keyAndArg.length
          @requestAsync keyAndArg...
        else
          @requestAsync keyAndArg

    Deferred.when requests

  @requestAll: (key, args...) ->
    FreeMart.log "FreeMart.requestAll(#{toString key, args...})"
    registry.process key, {all: true}, args...

  @requestAllAsync: (key, args...) ->
    FreeMart.log "FreeMart.requestAllAsync(#{toString key, args...})"
    registry.process key, {all: true, async: true}, args...

  @clear: -> registry.clear()

  @registry: registry

  #@processValue: (deferred, value, args...) ->
  #  if typeof value is 'function'
  #    result = value(args...)
  #    if typeof result?.promise is 'function'
  #      result
  #    else
  #      new Deferred().resolve result
  #  else if typeof value?.promise is 'function'
  #    value
  #  else
  #    new Deferred().resolve value

  @log: ->

