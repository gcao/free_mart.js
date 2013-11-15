chai.should()

describe FreeMart, ->
  it "register/request should work", ->
    FreeMart.register 'key', 'value'
    FreeMart.request('key').should.equal 'value'

  it "register/request should invoke function with arguments", ->
    FreeMart.register 'key', (arg1, arg2) -> "value #{arg1} #{arg2}"
    FreeMart.request('key', 'a', 'b').should.equal 'value a b'

  it "requestAsync should work simple value", ->
    FreeMart.register 'key', 'value'
    FreeMart.requestAsync('key').then (result) ->
      result.should.equal 'value'

  it "requestAsync should work with deferred object", ->
    deferred = new Deferred()
    FreeMart.register 'key', (arg) -> deferred.resolve(arg)
    FreeMart.requestAsync('key', 'value').then (result) ->
      result.should.equal 'value'

