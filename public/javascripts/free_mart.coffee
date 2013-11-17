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

  @processValue: (deferred, value, args...) ->
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
