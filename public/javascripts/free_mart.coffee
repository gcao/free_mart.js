class window.FreeMart
  queues = {}
  providers = {}

  @register: (name, value) ->
    providers[name] = value
    if queues.hasOwnProperty name
      queue = queues[name]
      delete queues[name]
      for item in queue
        deferred = item.shift()
        if typeof value is 'function'
          deferred.resolve value(item...)
        else if typeof value?.promise is 'function'
          value.done (result) -> deferred.resolve result
        else
          deferred.resolve value

  @request: (name, args...) ->
    value = providers[name]
    if typeof value is 'function'
      value(args...)
    else
      value

  @requestAsync: (name, args...) ->
    if providers.hasOwnProperty name
      value = providers[name]
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
      if queues.hasOwnProperty name
        queues[name].push args
      else
        queues[name] = [args]

      deferred

  @clear: ->
    providers = {}

  @providers: providers

