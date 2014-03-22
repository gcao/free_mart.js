// Generated by CoffeeScript 1.7.1
(function() {
  chai.should();

  describe(FreeMart, function() {
    beforeEach(function() {
      FreeMart.clear();
      return FreeMart.disableLog();
    });
    it("register/request should work", function() {
      FreeMart.register('key', 'value');
      return FreeMart.request('key').should.equal('value');
    });
    it("register/req should work", function() {
      FreeMart.register('key', 'value');
      return FreeMart.req('key').should.equal('value');
    });
    it("register/request should invoke function with arguments", function() {
      FreeMart.register('key', function(_, arg1, arg2) {
        return "value " + arg1 + " " + arg2;
      });
      return FreeMart.request('key', 'a', 'b').should.equal('value a b');
    });
    it("should work if registered value is a function", function() {
      var value;
      value = function() {};
      FreeMart.register('key', function() {
        return value;
      });
      return FreeMart.request('key').should.equal(value);
    });
    it("register/request should work with promises", function() {
      var deferred, result;
      deferred = new Deferred();
      FreeMart.register('key', deferred);
      result = null;
      FreeMart.request('key').then(function(value) {
        return result = value;
      });
      deferred.resolve('value');
      return result.should.equal('value');
    });
    it("requestAsync should work with simple value", function() {
      var result;
      FreeMart.register('key', 'value');
      result = null;
      FreeMart.requestAsync('key').then(function(value) {
        return result = value;
      });
      return result.should.equal('value');
    });
    it("requestAsync should work if registered value is a function", function() {
      var result, value;
      value = function() {};
      FreeMart.register('key', function() {
        return value;
      });
      result = null;
      FreeMart.requestAsync('key').then(function(v) {
        return result = v;
      });
      return result.should.equal(value);
    });
    it("requestAsync should work with functions", function() {
      var result;
      FreeMart.register('key', function(_, arg1, arg2) {
        return "value " + arg1 + " " + arg2;
      });
      result = null;
      FreeMart.requestAsync('key', 'a', 'b').then(function(value) {
        return result = value;
      });
      return result.should.equal('value a b');
    });
    it("value/request should work", function() {
      var value;
      value = function() {};
      FreeMart.value('key', value);
      return FreeMart.request('key').should.equal(value);
    });
    it("value/requestAsync should work", function() {
      var result, value;
      value = function() {};
      FreeMart.value('key', value);
      result = null;
      FreeMart.requestAsync('key').then(function(value) {
        return result = value;
      });
      return result.should.equal(value);
    });
    it("requestAsync should work with promises", function() {
      var deferred, result;
      deferred = new Deferred();
      FreeMart.register('key', deferred);
      result = null;
      FreeMart.requestAsync('key').then(function(value) {
        return result = value;
      });
      deferred.resolve('value');
      return result.should.equal('value');
    });
    it("requestAsync should work if provider is registered later", function() {
      var result;
      result = null;
      FreeMart.requestAsync('key').then(function(value) {
        return result = value;
      });
      FreeMart.register('key', 'value');
      return result.should.equal('value');
    });
    it("requestAsync should work if provider is a function and is registered later", function() {
      var result;
      result = null;
      FreeMart.requestAsync('key').then(function(value) {
        return result = value;
      });
      FreeMart.register('key', function() {
        return 'value';
      });
      return result.should.equal('value');
    });
    it("requestAsync should work if provider is a deferred object and is registered later", function() {
      var deferred, result;
      result = null;
      FreeMart.requestAsync('key').then(function(value) {
        return result = value;
      });
      deferred = new Deferred();
      FreeMart.register('key', deferred);
      deferred.resolve('value');
      return result.should.equal('value');
    });
    it("requestAsync used for flow control - is this a good idea?", function() {
      var processed;
      FreeMart.register('task', function() {
        return FreeMart.register('taskProcessed');
      });
      processed = false;
      FreeMart.requestAsync('taskProcessed').then(function() {
        return processed = true;
      });
      processed.should.equal(false);
      FreeMart.request('task');
      return processed.should.equal(true);
    });
    it("registerAsync/requestAsync should work with promises", function() {
      var result;
      FreeMart.register('a', 'aa');
      FreeMart.registerAsync('key', function(options, arg) {
        FreeMart.requestAsync(arg).then(function(value) {
          return options.$deferred.resolve(value.toUpperCase());
        });
      });
      result = null;
      FreeMart.requestAsync('key', 'a').then(function(value) {
        return result = value;
      });
      return result.should.equal('AA');
    });
    it("multiple requestAsync should work if provider is registered later", function() {
      var deferredA, requestA, resultA, resultB, resultC;
      resultA = null;
      deferredA = new Deferred();
      requestA = FreeMart.requestAsync('key', deferredA).then(function(value) {
        return resultA = value;
      });
      resultB = null;
      FreeMart.requestAsync('key', 'b').then(function(value) {
        return resultB = value;
      });
      FreeMart.register('key', function(_, arg) {
        return arg;
      });
      resultC = null;
      FreeMart.requestAsync('key', 'c').then(function(value) {
        return resultC = value;
      });
      deferredA.resolve('a');
      resultA.should.equal('a');
      resultB.should.equal('b');
      return resultC.should.equal('c');
    });
    it("multiple requestAsync in Deferred.when should work", function() {
      var resultA, resultB;
      FreeMart.register('a', 'aa');
      FreeMart.register('b', 'bb');
      resultA = null;
      resultB = null;
      Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b')).then(function(valueA, valueB) {
        resultA = valueA;
        return resultB = valueB;
      });
      resultA.should.equal('aa');
      return resultB.should.equal('bb');
    });
    it("multiple requestAsync in Deferred.when should work with deferred objects", function() {
      var deferredA, resultA, resultB;
      deferredA = new Deferred(0);
      FreeMart.register('a', deferredA);
      FreeMart.register('b', 'bb');
      resultA = null;
      resultB = null;
      Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b')).then(function(valueA, valueB) {
        resultA = valueA;
        return resultB = valueB;
      });
      deferredA.resolve('aa');
      resultA.should.equal('aa');
      return resultB.should.equal('bb');
    });
    it("multiple requestAsync in Deferred.when should work if providers are registered later", function() {
      var deferredA, resultA, resultB;
      resultA = null;
      resultB = null;
      Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b', 'bb')).then(function(valueA, valueB) {
        resultA = valueA;
        return resultB = valueB;
      });
      deferredA = new Deferred(0);
      FreeMart.register('a', deferredA);
      FreeMart.register('b', function(_, arg) {
        return arg;
      });
      deferredA.resolve('aa');
      resultA.should.equal('aa');
      return resultB.should.equal('bb');
    });
    it("register can take regular expression as key", function() {
      var func;
      FreeMart.register(/key/, function(options) {
        if (options.$key === 'key') {
          return 'value';
        } else if (options.$key === 'key1') {
          return 'value1';
        } else {
          return FreeMart.NOT_FOUND;
        }
      });
      FreeMart.request('key').should.equal('value');
      FreeMart.request('key1').should.equal('value1');
      func = function() {
        return FreeMart.request('key2');
      };
      return expect(func).toThrow(new Error("NOT FOUND: key2"));
    });
    it("order of registration should be kept", function() {
      FreeMart.register('key', 'first');
      FreeMart.register('key', 'second');
      return FreeMart.request('key').should.equal('second');
    });
    it("nested request should work", function() {
      FreeMart.register('key', 'value');
      FreeMart.register('key', function() {
        return FreeMart.request('key');
      });
      return FreeMart.request('key').should.equal('value');
    });
    it("mix string and regular expression provider should work", function() {
      FreeMart.register('key', 'first');
      FreeMart.register(/key/, function() {
        return 'second';
      });
      return FreeMart.request('key').should.equal('second');
    });
    it("nested requestAsync should work", function() {
      var result;
      FreeMart.register('key', 'value');
      FreeMart.register('key', function() {
        return FreeMart.requestAsync('key');
      });
      result = null;
      FreeMart.requestAsync('key').then(function(value) {
        return result = value;
      });
      return result.should.equal('value');
    });
    it("requestAll should work", function() {
      var result;
      FreeMart.register('key', 'first');
      FreeMart.register('key', 'second');
      result = FreeMart.requestAll('key');
      result[0].should.equal('first');
      return result[1].should.equal('second');
    });
    it("requestAllAsync should work", function() {
      var result;
      FreeMart.register('key', 'first');
      FreeMart.register('key', 'second');
      result = null;
      FreeMart.requestAllAsync('key').then(function(value) {
        return result = value;
      });
      result[0].should.equal('first');
      return result[1].should.equal('second');
    });
    it("deregister should work", function() {
      var func, provider;
      provider = FreeMart.register('key', 'value');
      FreeMart.deregister(provider);
      func = function() {
        return FreeMart.request('key');
      };
      return expect(func).toThrow(new Error("NO PROVIDER: key"));
    });
    it("provider.deregister should work", function() {
      var func, provider;
      provider = FreeMart.register('key', 'value');
      provider.deregister();
      func = function() {
        return FreeMart.request('key');
      };
      return expect(func).toThrow(new Error("NO PROVIDER: key"));
    });
    it("self-destruction should work", function() {
      var func, provider;
      provider = FreeMart.register('key', function() {
        provider.count -= 1;
        if (provider.count <= 0) {
          provider.deregister();
        }
        return 'value';
      });
      provider.count = 2;
      FreeMart.request('key').should.equal('value');
      FreeMart.request('key').should.equal('value');
      func = function() {
        return FreeMart.request('key');
      };
      return expect(func).toThrow(new Error("NO PROVIDER: key"));
    });
    it("options.$provider", function() {
      var func;
      FreeMart.register('key', function(options) {
        var provider;
        provider = options.$provider;
        provider.count || (provider.count = 2);
        provider.count -= 1;
        if (provider.count <= 0) {
          provider.deregister();
        }
        return 'value';
      });
      FreeMart.request('key').should.equal('value');
      FreeMart.request('key').should.equal('value');
      func = function() {
        return FreeMart.request('key');
      };
      return expect(func).toThrow(new Error("NO PROVIDER: key"));
    });
    it("defining provider value separately should work", function() {
      var provider;
      provider = FreeMart.register('key');
      provider.value = 'value';
      return FreeMart.request('key').should.equal('value');
    });
    it("continue to other providers if NOT_FOUND", function() {
      FreeMart.register('key', 'value');
      FreeMart.register('key', FreeMart.NOT_FOUND);
      return FreeMart.request('key').should.equal('value');
    });
    it("stop looking further if NOT_FOUND_FINAL", function() {
      var func;
      FreeMart.register('key', 'value');
      FreeMart.register('key', FreeMart.NOT_FOUND_FINAL);
      func = function() {
        return FreeMart.request('key');
      };
      return expect(func).toThrow(new Error("NOT FOUND: key"));
    });
    it("create should work", function() {
      var instance;
      instance = FreeMart.create();
      instance.register('key', 'value');
      return instance.request('key').should.equal('value');
    });
    it("request should work with hash", function() {
      FreeMart.register('key', 'value');
      return FreeMart.request({
        $key: 'key'
      }).should.equal('value');
    });
    return it("requestAsync should work with hash", function() {
      var result;
      FreeMart.register('key', 'value');
      result = null;
      FreeMart.requestAsync({
        $key: 'key'
      }).then(function(value) {
        return result = value;
      });
      return result.should.equal('value');
    });
  });

}).call(this);
