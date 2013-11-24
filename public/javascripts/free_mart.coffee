InUse =
  process: (key, options, args...) ->
    try
      @in_use_keys << key
      process_ key, options, args...
    finally
      @in_use_keys.splice(@in_use_keys.indexOf(key), 1)

  processing: (key) ->
    @in_use_keys.indexOf(key) >= 0

  in_use_keys: ->
    @in_use ||= []

class Registry extends Array
  add: (key, provider) ->
    if last instanceof HashRegistry and not last.accept key
      last[key] = provider
    else
      if key instanceof String
        child_registry = new HashRegistry()
        child_registry[key] = provider
      else
        child_registry = new FuzzyRegistry key, provider
      push child_registry

  accept: (key) ->
    for item in @
      if item.accept key then return true

  process: (key, options, args...) ->
    for i in [@length-1..0]
      item = this[0]
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
    @[key] = value

  accept: (key) ->
    @[key]

  process_: (key, options, args...) ->
    provider = self[key]
    return NOT_FOUND unless provider
    provider.call options, args...

class FuzzyRegistry
  for own key, value of InUse
    @[key] = value

  constructor: (@fuzzy_key, @provider) ->

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

# Registration are stored based on order
# regexp => hash => regexp
# Providers can be deregistered
class window.FreeMart
  queues = {}
  providers = {}

  @register: (key, value) ->
    providers[key] = value
    if queues.hasOwnProperty key
      queue = queues[key]
      delete queues[key]
      for item in queue
        deferred = item.shift()
        if typeof value is 'function'
          result = value(item...)
          if typeof result?.promise is 'function'
            # Save a reference to deferred because it might be changed
            deferred2 = deferred
            result.done (newResult) ->
              deferred2.resolve newResult
          else
            deferred.resolve result
        else if typeof value?.promise is 'function'
          value.done (result) ->
            deferred.resolve result
        else
          deferred.resolve value

  @request: (key, args...) ->
    value = providers[key]
    if typeof value is 'function'
      value(args...)
    else
      value

  @requestAsync: (key, args...) ->
    if providers.hasOwnProperty key
      value = providers[key]
      if typeof value is 'function'
        result = value(args...)
        if typeof result?.promise is 'function'
          result
        else
          new Deferred().resolve result
      else if typeof value?.promise is 'function'
        value
      else
        new Deferred().resolve value
    else
      deferred = new Deferred()

      args.unshift deferred
      if queues.hasOwnProperty key
        queues[key].push args
      else
        queues[key] = [args]

      deferred

  @clear: ->
    providers = {}

  @providers: providers

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
