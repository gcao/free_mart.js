class window.FreeMart
  @register: (name, value) ->
    @providers ||= {}
    @providers[name] = value

  @request: (name, args...) ->
    value = @providers[name]
    if typeof value is 'function'
      value(args...)
    else
      value

  @requestAsync: (name, args...) ->
    deferred = new Deferred()
    value = @providers[name]
    if typeof value is 'function'
      value(args...)
    else
      deferred.resolve value
    deferred
