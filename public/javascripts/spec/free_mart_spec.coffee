chai.should()

describe FreeMart, ->
  beforeEach ->
    FreeMart.clear()

    FreeMart.log = ->
    #FreeMart.log = (msg) -> console.log msg

  it "register/request should work", ->
    FreeMart.register 'key', 'value'
    FreeMart.request('key').should.equal 'value'

  it "register/req should work", ->
    FreeMart.register 'key', 'value'
    FreeMart.req('key').should.equal 'value'

  it "register/request should invoke function with arguments", ->
    FreeMart.register 'key', (_, arg1, arg2) -> "value #{arg1} #{arg2}"
    FreeMart.request('key', 'a', 'b').should.equal 'value a b'

  it "register/request should work with promises", ->
    deferred = new Deferred()
    FreeMart.register 'key', deferred

    result = null
    FreeMart.request('key').then (value) ->
      result = value

    deferred.resolve('value')
    result.should.equal 'value'

  it "requestAsync should work with simple value", ->
    FreeMart.register 'key', 'value'
    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value
    result.should.equal 'value'

  it "requestAsync should work with functions", ->
    FreeMart.register 'key', (_, args...) -> "value #{args.join(' ')}"
    result = null
    FreeMart.requestAsync('key', 'a', 'b').then (value) ->
      result = value
    result.should.equal 'value a b'

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

  it "multiple requestAsync in Deferred.when should work", ->
    FreeMart.register 'a', 'aa'
    FreeMart.register 'b', 'bb'

    resultA = null
    resultB = null
    Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b'))
      .then (valueA, valueB) ->
        resultA = valueA
        resultB = valueB

    resultA.should.equal 'aa'
    resultB.should.equal 'bb'

  it "multiple requestAsync in Deferred.when should work with deferred objects", ->
    deferredA = new Deferred(0)
    FreeMart.register 'a', deferredA
    FreeMart.register 'b', 'bb'

    resultA = null
    resultB = null
    Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b'))
      .then (valueA, valueB) ->
        resultA = valueA
        resultB = valueB

    deferredA.resolve('aa')

    resultA.should.equal 'aa'
    resultB.should.equal 'bb'

  it "multiple requestAsync in Deferred.when should work if providers are registered later", ->
    resultA = null
    resultB = null
    Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b', 'bb'))
      .then (valueA, valueB) ->
        resultA = valueA
        resultB = valueB

    deferredA = new Deferred(0)
    FreeMart.register 'a', deferredA
    FreeMart.register 'b', (_, arg) -> arg

    deferredA.resolve('aa')

    resultA.should.equal 'aa'
    resultB.should.equal 'bb'

  it "register can take regular expression as key", ->
    FreeMart.register /key/, -> 'value'
    FreeMart.request('key').should.equal 'value'
    FreeMart.request('key1').should.equal 'value'

  it "order of registration should be kept", ->
    FreeMart.register 'key', 'first'
    FreeMart.register 'key', 'second'
    FreeMart.request('key').should.equal 'second'

  it "nested request should work", ->
    FreeMart.register 'key', 'value'
    FreeMart.register 'key', -> FreeMart.request('key')
    FreeMart.request('key').should.equal 'value'

  it "nested requestAsync should work", ->
    FreeMart.register 'key', 'value'
    FreeMart.register 'key', -> FreeMart.requestAsync('key')

    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value
    result.should.equal 'value'

  it "requestMulti should work", ->
    FreeMart.register 'a', 'aa'
    FreeMart.register 'b', 'bb'
    result = FreeMart.requestMulti('a', 'b')
    result[0].should.equal 'aa'
    result[1].should.equal 'bb'

  it "requestMultiAsync should work", ->
    FreeMart.register 'a', 'aa'
    FreeMart.register 'b', 'bb'

    result = FreeMart.requestMultiAsync('a', 'b')
    result1 = null
    result2 = null
    result.then (value1, value2) ->
      result1 = value1
      result2 = value2
    result1.should.equal 'aa'
    result2.should.equal 'bb'

  it "requestAll should work", ->
    FreeMart.register 'key', 'first'
    FreeMart.register 'key', 'second'

    result = FreeMart.requestAll 'key'
    result[0].should.equal 'first'
    result[1].should.equal 'second'

  it "requestAllAsync should work", ->
    FreeMart.register 'key', 'first'
    FreeMart.register 'key', 'second'

    result = null
    FreeMart.requestAllAsync('key').then (value) ->
      result = value
    result[0].should.equal 'first'
    result[1].should.equal 'second'

  it "deregister should work", ->
    provider = FreeMart.register 'key', 'value'
    FreeMart.deregister provider
    func = -> FreeMart.request('key')
    expect(func).toThrow(new Error("NO PROVIDER: key"))

  it "self-destruction should work", ->
    FreeMart.log = (msg) -> console.log msg
    FreeMart.register 'key', (options) ->
      'value'

    FreeMart.request('key').should.equal 'value'

    func = -> FreeMart.request('key')
    expect(func).toThrow(new Error("NO PROVIDER: key"))

