// Generated by CoffeeScript 1.4.0
(function() {
  var __slice = [].slice;

  chai.should();

  describe(FreeMart, function() {
    beforeEach(function() {
      FreeMart.clear();
      return FreeMart.log = function() {};
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
    it("requestAsync should work with functions", function() {
      var result;
      FreeMart.register('key', function() {
        var args, _;
        _ = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        return "value " + (args.join(' '));
      });
      result = null;
      FreeMart.requestAsync('key', 'a', 'b').then(function(value) {
        return result = value;
      });
      return result.should.equal('value a b');
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
      FreeMart.register(/key/, function() {
        return 'value';
      });
      FreeMart.request('key').should.equal('value');
      return FreeMart.request('key1').should.equal('value');
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
    it("requestMulti should work", function() {
      var result;
      FreeMart.register('a', 'aa');
      FreeMart.register('b', 'bb');
      result = FreeMart.requestMulti('a', 'b');
      result[0].should.equal('aa');
      return result[1].should.equal('bb');
    });
    it("requestMultiAsync should work", function() {
      var result, result1, result2;
      FreeMart.register('a', 'aa');
      FreeMart.register('b', 'bb');
      result = FreeMart.requestMultiAsync('a', 'b');
      result1 = null;
      result2 = null;
      result.then(function(value1, value2) {
        result1 = value1;
        return result2 = value2;
      });
      result1.should.equal('aa');
      return result2.should.equal('bb');
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
    return it("self-destruction should work", function() {
      var func, provider;
      provider = FreeMart.register('key', function() {
        provider.count -= 1;
        if (provider.count <= 0) {
          FreeMart.deregister(provider);
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
  });

}).call(this);
