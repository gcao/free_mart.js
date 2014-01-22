chai.should()

describe FreeMart, ->
  beforeEach ->
    FreeMart.clear()
    FreeMart.disableLog()

  it "register/request should work", ->
    FreeMart.register 'key', 'value'
    FreeMart.request('key').should.equal 'value'

  it "register/req should work", ->
    FreeMart.register 'key', 'value'
    FreeMart.req('key').should.equal 'value'

  it "register/request should invoke function with arguments", ->
    FreeMart.register 'key', (_, arg1, arg2) -> "value #{arg1} #{arg2}"
    FreeMart.request('key', 'a', 'b').should.equal 'value a b'

  it "should work if registered value is a function", ->
    value = ->
    FreeMart.register 'key', -> value
    FreeMart.request('key').should.equal value

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

  it "requestAsync should work if registered value is a function", ->
    value = ->
    FreeMart.register 'key', -> value

    result = null
    FreeMart.requestAsync('key').then (v) ->
      result = v

    result.should.equal value

  it "requestAsync should work with functions", ->
    FreeMart.register 'key', (_, args...) -> "value #{args.join(' ')}"
    result = null
    FreeMart.requestAsync('key', 'a', 'b').then (value) ->
      result = value
    result.should.equal 'value a b'

  it "value/request should work", ->
    FreeMart.value 'key', -> 'value'
    FreeMart.request('key')().should.equal 'value'

  it "value/requestAsync should work", ->
    FreeMart.value 'key', -> 'value'
    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value()
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

  it "requestAsync used for flow control - is this a good idea?", ->
    FreeMart.register 'task', ->
      FreeMart.register 'taskProcessed'

    processed = false
    FreeMart.requestAsync('taskProcessed').then ->
      processed = true

    processed.should.equal false
    FreeMart.request 'task'
    processed.should.equal true

  it "registerAsync/requestAsync should work with promises", ->
    FreeMart.register 'a', 'aa'

    FreeMart.registerAsync 'key', (options, arg) ->
      FreeMart.requestAsync(arg).then (value) ->
        options.deferred.resolve(value.toUpperCase())

      # What is returned does not matter
      return

    result = null
    FreeMart.requestAsync('key', 'a').then (value) ->
      result = value
    result.should.equal 'AA'

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
    FreeMart.register /key/, (options) ->
      if options.key is 'key' then 'value'
      else if options.key is 'key1' then 'value1'
      else FreeMart.NOT_FOUND

    FreeMart.request('key').should.equal 'value'
    FreeMart.request('key1').should.equal 'value1'
    func = -> FreeMart.request('key2')
    expect(func).toThrow(new Error("NOT FOUND: key2"))

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

  it "requestMulti should work with multiple keys and args", ->
    FreeMart.register 'a', 'aa'
    FreeMart.register 'b', (_, arg) -> arg
    result = FreeMart.requestMulti('a', ['b', 'arg'])
    result[0].should.equal 'aa'
    result[1].should.equal 'arg'

  it "requestMultiAsync should work", ->
    FreeMart.register 'a', 'aa'
    FreeMart.register 'b', (_, arg) -> arg

    result1 = null
    result2 = null
    FreeMart.requestMultiAsync('a', ['b', 'arg']).then (value1, value2) ->
      result1 = value1
      result2 = value2
    result1.should.equal 'aa'
    result2.should.equal 'arg'

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

  it "provider.deregister should work", ->
    provider = FreeMart.register 'key', 'value'
    provider.deregister()
    func = -> FreeMart.request('key')
    expect(func).toThrow(new Error("NO PROVIDER: key"))

  it "self-destruction should work", ->
    provider = FreeMart.register 'key', ->
      provider.count -= 1
      if provider.count <= 0 then provider.deregister()

      'value'

    provider.count = 2

    FreeMart.request('key').should.equal 'value'
    FreeMart.request('key').should.equal 'value'

    func = -> FreeMart.request('key')
    expect(func).toThrow(new Error("NO PROVIDER: key"))

  it "options.provider", ->
    FreeMart.register 'key', (options) ->
      provider = options.provider
      provider.count ||= 2
      provider.count -= 1
      if provider.count <= 0 then provider.deregister()

      'value'

    FreeMart.request('key').should.equal 'value'
    FreeMart.request('key').should.equal 'value'

    func = -> FreeMart.request('key')
    expect(func).toThrow(new Error("NO PROVIDER: key"))

  it "defining provider value separately should work", ->
    provider = FreeMart.register 'key'
    provider.value = 'value'
    FreeMart.request('key').should.equal 'value'

  it "continue to other providers if NOT_FOUND", ->
    FreeMart.register 'key', 'value'
    FreeMart.register 'key', FreeMart.NOT_FOUND
    FreeMart.request('key').should.equal 'value'

  it "stop looking further if NOT_FOUND_FINAL", ->
    FreeMart.register 'key', 'value'
    FreeMart.register 'key', FreeMart.NOT_FOUND_FINAL
    func = -> FreeMart.request('key')
    expect(func).toThrow(new Error("NOT FOUND: key"))

  it "clone should work", ->
    instance = FreeMart.clone()
    instance.register 'key', 'value'
    instance.request('key').should.equal 'value'

