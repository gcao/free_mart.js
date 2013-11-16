chai.should()

describe FreeMart, ->
  beforeEach -> FreeMart.clear()

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

  it "requestAsync should work with functions", ->
    FreeMart.register 'key', -> 'value'
    FreeMart.requestAsync('key').then (result) ->
      result.should.equal 'value'

  it "requestAsync should work with promises", ->
    deferred = new Deferred()
    FreeMart.register 'key', deferred

    FreeMart.requestAsync('key').then (result) ->
      result.should.equal 'value'

    deferred.resolve('value')

  it "requestAsync should work if provider is registered later", ->
    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value

    FreeMart.register 'key', 'value'
    result.should.equal 'value'

  it "requestAsync should work if provider is a function and is registered later", ->
    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value

    FreeMart.register 'key', -> 'value'
    result.should.equal 'value'

  it "requestAsync should work if provider is a deferred object and is registered later", ->
    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value

    deferred = new Deferred()
    FreeMart.register 'key', deferred
    deferred.resolve 'value'

    result.should.equal 'value'

  it "multiple requestAsync should work if provider is registered later", ->
    result_a = null
    FreeMart.requestAsync('key', 'a').then (value) ->
      result_a = value

    result_b = null
    FreeMart.requestAsync('key', 'b').then (value) ->
      result_b = value

    FreeMart.register 'key', (arg) -> arg

    result_c = null
    FreeMart.requestAsync('key', 'c').then (value) ->
      result_c = value

    result_a.should.equal 'a'
    result_b.should.equal 'b'
    result_c.should.equal 'c'
