class window.FreeMart
  deferreds = {}
  providers = {}

  @register: (name, value) ->
    providers[name] = value

  @request: (name, args...) ->
    value = providers[name]
    if typeof value is 'function'
      value(args...)
    else
      value

  @requestAsync: (name, args...) ->
    value = providers[name]
    if typeof value is 'function'
      result = value(args...)
      if typeof result.promise is 'function'
        result
      else
        new Deferred().resolve result
    else if typeof value?.promise is 'function'
      value
    else
      new Deferred().resolve value

  @clear: ->
    providers = {}

  @providers: providers

