NOT_FOUND = {}

toString = (obj, options = {}) ->
  result = JSON.stringify(obj).replace(/"/g, "'")
  if options.strip_brackets and result[0] is '['
    result = result.substring(1, result.length - 1)
  result

isDeferred = (o) -> typeof o?.promise is 'function'

InUse =
  process: (key, options, args...) ->
    try
      @in_use_keys << key
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
    console.log "Registry.process(#{key})"
    for i in [@storage.length-1..0]
      item = @storage[0]
      continue unless item.accept key
      continue if item.processing key
      result = item.process key, options, args...
      return result unless result is NOT_FOUND

    NOT_FOUND
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
    console.log "HashRegistry.process_(#{key})"
    provider = @[key]
    return NOT_FOUND unless provider
    provider.process options, args...

class FuzzyRegistry
  for own key, value of InUse
    @.prototype[key] = value

  constructor: (@fuzzy_key, @provider) ->
    @in_use_keys = []

  accept: (key) ->
    if @fuzzy_key instanceof RegExp
      @fuzzy_key.match(key)
    else if @fuzzy_key instanceof Array
      for item in @fuzzy_key
        if item instanceof String
          return true if item is key
        else
          return true if key.match(item)

  process_: (key, options, args...) ->
    return NOT_FOUND unless @accept key
    @provider.process options, args...

class Provider
  constructor: (@key, @value, @options) ->
    console.log 'Provider.constructor'

  process: (args...) ->
    console.log "Provider.process(#{toString(args, strip_brackets: true)})"
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

## Deferred requests - will be processed once a provider is registered
#class DeferredRequest
#  constructor: (@key, @args...) ->

# Registration are stored based on order
# regexp => hash => regexp
# Providers can be deregistered
class window.FreeMart
  #queues = {}
  registry = new Registry()

  @register: (key, value) ->
    registry.add key, new Provider(key, value)
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
    registry.process key, {}, args...

  @requestAsync: (key, args...) ->
    registry.process key, {async: true}, args...
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
