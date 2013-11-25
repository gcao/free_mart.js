chai.should()

describe FreeMart, ->
  beforeEach -> FreeMart.clear()

  #it "register/request should work", ->
  #  FreeMart.register 'key', 'value'
  #  FreeMart.request('key').should.equal 'value'

  #it "register/request should invoke function with arguments", ->
  #  FreeMart.register 'key', (_, arg1, arg2) -> "value #{arg1} #{arg2}"
  #  FreeMart.request('key', 'a', 'b').should.equal 'value a b'

  it "requestAsync should work with simple value", ->
    FreeMart.register 'key', 'value'
    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value
    result.should.equal 'value'

  #it "requestAsync should work with functions", ->
  #  FreeMart.register 'key', -> 'value'
  #  result = null
  #  FreeMart.requestAsync('key').then (value) ->
  #    result = value
  #  result.should.equal 'value'

  #it "requestAsync should work with promises", ->
  #  deferred = new Deferred()
  #  FreeMart.register 'key', deferred

  #  result = null
  #  FreeMart.requestAsync('key').then (value) ->
  #    result = value

  #  deferred.resolve('value')
  #  result.should.equal 'value'

  ##it "requestAsync should work if provider is registered later", ->
  ##  result = null
  ##  FreeMart.requestAsync('key').then (value) ->
  ##    result = value

  ##  FreeMart.register 'key', 'value'
  ##  result.should.equal 'value'

  ##it "requestAsync should work if provider is a function and is registered later", ->
  ##  result = null
  ##  FreeMart.requestAsync('key').then (value) ->
  ##    result = value

  ##  FreeMart.register 'key', -> 'value'
  ##  result.should.equal 'value'

  ##it "requestAsync should work if provider is a deferred object and is registered later", ->
  ##  result = null
  ##  FreeMart.requestAsync('key').then (value) ->
  ##    result = value

  ##  deferred = new Deferred()
  ##  FreeMart.register 'key', deferred
  ##  deferred.resolve 'value'

  ##  result.should.equal 'value'

  ##it "multiple requestAsync should work if provider is registered later", ->
  ##  result_a = null
  ##  deferred_a = new Deferred()
  ##  FreeMart.requestAsync('key', deferred_a).then (value) ->
  ##    result_a = value

  ##  result_b = null
  ##  FreeMart.requestAsync('key', 'b').then (value) ->
  ##    result_b = value

  ##  FreeMart.register 'key', (arg) -> arg

  ##  result_c = null
  ##  FreeMart.requestAsync('key', 'c').then (value) ->
  ##    result_c = value

  ##  deferred_a.resolve 'a'
  ##  result_a.should.equal 'a'
  ##  result_b.should.equal 'b'
  ##  result_c.should.equal 'c'

  #it "multiple requestAsync in Deferred.when should work", ->
  #  FreeMart.register 'a', 'aa'
  #  FreeMart.register 'b', 'bb'

  #  result_a = null
  #  result_b = null
  #  Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b'))
  #    .then (value_a, value_b) ->
  #      result_a = value_a
  #      result_b = value_b

  #  result_a.should.equal 'aa'
  #  result_b.should.equal 'bb'

  #it "multiple requestAsync in Deferred.when should work with deferred objects", ->
  #  deferred_a = new Deferred(0)
  #  FreeMart.register 'a', deferred_a
  #  FreeMart.register 'b', 'bb'

  #  result_a = null
  #  result_b = null
  #  Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b'))
  #    .then (value_a, value_b) ->
  #      result_a = value_a
  #      result_b = value_b

  #  deferred_a.resolve('aa')

  #  result_a.should.equal 'aa'
  #  result_b.should.equal 'bb'

  ##it "multiple requestAsync in Deferred.when should work if providers are registered later", ->
  ##  result_a = null
  ##  result_b = null
  ##  Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b', 'bb'))
  ##    .then (value_a, value_b) ->
  ##      result_a = value_a
  ##      result_b = value_b

  ##  deferred_a = new Deferred(0)
  ##  FreeMart.register 'a', deferred_a
  ##  FreeMart.register 'b', (arg) -> arg

  ##  deferred_a.resolve('aa')

  ##  result_a.should.equal 'aa'
  ##  result_b.should.equal 'bb'

  #xit "register can take regular expression as key", ->

  #xit "order of registration should be kept", ->
  #  FreeMart.register /a.*/, -> 'first'
  #  FreeMart.register /ab.*/, -> 'second'
  #  FreeMart.request('abc').should.equal 'first'

