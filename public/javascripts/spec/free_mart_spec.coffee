chai.should()

describe FreeMart, ->
  beforeEach ->
    FreeMart.clear()

  it "register/request should work", ->
    FreeMart.register 'key', 'value'
    FreeMart.request('key').should.equal 'value'

  it "register/request should invoke function with arguments", ->
    FreeMart.register 'key', (_, arg1, arg2) -> "value #{arg1} #{arg2}"
    FreeMart.request('key', 'a', 'b').should.equal 'value a b'

  it "requestAsync should work with simple value", ->
    FreeMart.register 'key', 'value'
    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value
    result.should.equal 'value'

  it "requestAsync should work with functions", ->
    FreeMart.register 'key', -> 'value'
    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value
    result.should.equal 'value'

  it "requestAsync should work with promises", ->
    deferred = new Deferred()
    FreeMart.register 'key', deferred

    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value

    deferred.resolve('value')
    result.should.equal 'value'

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
    resultA = null
    deferredA = new Deferred()
    requestA = FreeMart.requestAsync('key', deferredA).then (value) ->
      resultA = value

    resultB = null
    FreeMart.requestAsync('key', 'b').then (value) ->
      resultB = value

    FreeMart.register 'key', (_, arg) ->
      arg

    resultC = null
    FreeMart.requestAsync('key', 'c').then (value) ->
      resultC = value

    deferredA.resolve 'a'
    resultA.should.equal 'a'
    resultB.should.equal 'b'
    resultC.should.equal 'c'

  #it "multiple requestAsync in Deferred.when should work", ->
  #  FreeMart.register 'a', 'aa'
  #  FreeMart.register 'b', 'bb'

  #  resultA = null
  #  resultB = null
  #  Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b'))
  #    .then (valueA, valueB) ->
  #      resultA = valueA
  #      resultB = valueB

  #  resultA.should.equal 'aa'
  #  resultB.should.equal 'bb'

  #it "multiple requestAsync in Deferred.when should work with deferred objects", ->
  #  deferredA = new Deferred(0)
  #  FreeMart.register 'a', deferredA
  #  FreeMart.register 'b', 'bb'

  #  resultA = null
  #  resultB = null
  #  Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b'))
  #    .then (valueA, valueB) ->
  #      resultA = valueA
  #      resultB = valueB

  #  deferredA.resolve('aa')

  #  resultA.should.equal 'aa'
  #  resultB.should.equal 'bb'

  ##it "multiple requestAsync in Deferred.when should work if providers are registered later", ->
  ##  resultA = null
  ##  resultB = null
  ##  Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b', 'bb'))
  ##    .then (valueA, valueB) ->
  ##      resultA = valueA
  ##      resultB = valueB

  ##  deferredA = new Deferred(0)
  ##  FreeMart.register 'a', deferredA
  ##  FreeMart.register 'b', (arg) -> arg

  ##  deferredA.resolve('aa')

  ##  resultA.should.equal 'aa'
  ##  resultB.should.equal 'bb'

  #xit "register can take regular expression as key", ->

  #xit "order of registration should be kept", ->
  #  FreeMart.register /a.*/, -> 'first'
  #  FreeMart.register /ab.*/, -> 'second'
  #  FreeMart.request('abc').should.equal 'first'

