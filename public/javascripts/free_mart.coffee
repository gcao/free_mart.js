class window.FreeMart
  @register: (name, value) ->
    @providers ||= {}
    @providers[name] = value

  @request: (name) ->
    @providers[name]

