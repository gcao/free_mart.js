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

  it "register/request should work if registered value is a function", ->
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
    FreeMart.register 'key', (_, arg1, arg2) -> "value #{arg1} #{arg2}"

    result = null
    FreeMart.requestAsync('key', 'a', 'b').then (value) ->
      result = value

    result.should.equal 'value a b'

  it "request should work with hash", ->
    FreeMart.register 'key', 'value'
    FreeMart.request($key: 'key').should.equal 'value'

  it "requestAsync should work with hash", ->
    FreeMart.register 'key', 'value'

    result = null
    FreeMart.requestAsync($key: 'key').then (value) ->
      result = value

    result.should.equal 'value'

  it "value/request should work", ->
    value = ->
    FreeMart.value 'key', value
    FreeMart.request('key').should.equal value

  it "value/requestAsync should work", ->
    value = ->
    FreeMart.value 'key', value

    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value

    result.should.equal value

  it "factory/request should work", ->
    FreeMart.factory 'key', ->
      @value = 'value'

    result = FreeMart.request('key')
    result.value.should.equal 'value'

  it "factory/requestAsync should work", ->
    FreeMart.factory 'key', ->
      @value = 'value'

    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value
    result.value.should.equal 'value'

  it "provider/request should work", ->
    FreeMart.provider
      $accept: 'key'
      $get:    'value'

    FreeMart.request('key').should.equal 'value'

  it "one-function provider/request should work", ->
    FreeMart.provider (options) ->
      if options.$key is 'key'
        'value'
      else
        FreeMart.NOT_FOUND

    FreeMart.request('key').should.equal 'value'

  it "one-function provider/requestAsync should work", ->
    FreeMart.provider (options) ->
      if options.$key is 'key'
        'value'
      else
        FreeMart.NOT_FOUND

    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value
    result.should.equal 'value'

  it "provider/requestAsync should work", ->
    FreeMart.provider
      $accept: 'key'
      $get:    'value'

    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value

    result.should.equal 'value'

  it "register a raw provider should work", ->
    FreeMart.register 'key', $get: -> 'value'
    FreeMart.request('key').should.equal 'value'

  it "register should take function as key", ->
    callback = (key) -> key is 'key'
    FreeMart.register callback, 'value'

    FreeMart.request('key').should.equal 'value'
    func = -> FreeMart.request('key1')
    expect(func).toThrow(new Error("NO PROVIDER: key1"))

  it "default should work", ->
    FreeMart.default (options) -> "default(#{options.$key})"

    FreeMart.request('key').should.equal 'default(key)'

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

  it "Used as router - is this a good idea?", ->
    FreeMart.default -> "404: Not Found"
    FreeMart.register "/"      , 'root'
    FreeMart.register "/first" , 'first page'
    FreeMart.register "/second", (_, params) -> "second page: #{JSON.stringify(params)}"

    FreeMart.request("/").should.equal 'root'
    FreeMart.request("/first").should.equal 'first page'
    FreeMart.request("/second", name: "John").should.equal 'second page: {"name":"John"}'

  it "registerAsync/requestAsync should work with promises", ->
    FreeMart.register 'a', 'aa'

    FreeMart.registerAsync 'key', (options, arg) ->
      FreeMart.requestAsync(arg).then (value) ->
        options.$deferred.resolve(value.toUpperCase())

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

    FreeMart.register 'key', (_, arg) -> arg

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

  it "register should take regular expression as key", ->
    FreeMart.register /key/, (options) ->
      if options.$key is 'key' then 'value'
      else if options.$key is 'key1' then 'value1'
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

  it "mix string and regular expression provider should work", ->
    FreeMart.register 'key', 'first'
    FreeMart.register /key/, -> 'second'
    FreeMart.request('key').should.equal 'second'

  it "nested requestAsync should work", ->
    FreeMart.register 'key', 'value'
    FreeMart.register 'key', -> FreeMart.requestAsync('key')

    result = null
    FreeMart.requestAsync('key').then (value) ->
      result = value

    result.should.equal 'value'

  it "requestAll should work", ->
    FreeMart.register 'key', 'first'
    FreeMart.register 'key', 'second'

    result = FreeMart.requestAll 'key'
    result[0].should.equal 'first'
    result[1].should.equal 'second'

  it "requestAll should work with async provider", ->
    deferred = new Deferred()
    FreeMart.register 'key', deferred
    FreeMart.register 'key', 'second'

    result = null
    FreeMart.requestAllAsync('key').then (value) ->
      result = value

    deferred.resolve 'first'
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

  it "options.$provider", ->
    FreeMart.register 'key', (options) ->
      provider = options.$provider
      provider.count ||= 2
      provider.count -= 1
      if provider.count <= 0 then provider.deregister()

      'value'

    FreeMart.request('key').should.equal 'value'
    FreeMart.request('key').should.equal 'value'

    func = -> FreeMart.request('key')
    expect(func).toThrow(new Error("NO PROVIDER: key"))

  it "options.$provider should not be available in callbacks if they are invoked after the value function returns", ->
    deferred = new Deferred()
    FreeMart.register 'key', (options) ->
      provider = options.$provider
      deferred.then ->
        # This callback is run after the parent function returns because deferred
        # is resolved later
        provider.should.exist
        (options.$provider is undefined).should.be.true

    FreeMart.request('key')
    deferred.resolve 'value'

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

  it "create should work", ->
    instance = FreeMart.create()
    instance.register 'key', 'value'
    instance.request('key').should.equal 'value'

