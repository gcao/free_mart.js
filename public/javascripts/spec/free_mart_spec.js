// Generated by CoffeeScript 1.4.0
(function() {

  chai.should();

  describe(FreeMart, function() {
    beforeEach(function() {
      return FreeMart.clear();
    });
    it("register/request should work", function() {
      FreeMart.register('key', 'value');
      return FreeMart.request('key').should.equal('value');
    });
    it("register/request should invoke function with arguments", function() {
      FreeMart.register('key', function(arg1, arg2) {
        return "value " + arg1 + " " + arg2;
      });
      return FreeMart.request('key', 'a', 'b').should.equal('value a b');
    });
    it("requestAsync should work simple value", function() {
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
        return 'value';
      });
      result = null;
      FreeMart.requestAsync('key').then(function(value) {
        return result = value;
      });
      return result.should.equal('value');
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
      var deferred_a, result_a, result_b, result_c;
      result_a = null;
      deferred_a = new Deferred();
      FreeMart.requestAsync('key', deferred_a).then(function(value) {
        return result_a = value;
      });
      result_b = null;
      FreeMart.requestAsync('key', 'b').then(function(value) {
        return result_b = value;
      });
      FreeMart.register('key', function(arg) {
        return arg;
      });
      result_c = null;
      FreeMart.requestAsync('key', 'c').then(function(value) {
        return result_c = value;
      });
      deferred_a.resolve('a');
      result_a.should.equal('a');
      result_b.should.equal('b');
      return result_c.should.equal('c');
    });
    it("multiple requestAsync in Deferred.when should work", function() {
      var result_a, result_b;
      FreeMart.register('a', 'aa');
      FreeMart.register('b', 'bb');
      result_a = null;
      result_b = null;
      Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b')).then(function(value_a, value_b) {
        result_a = value_a;
        return result_b = value_b;
      });
      result_a.should.equal('aa');
      return result_b.should.equal('bb');
    });
    it("multiple requestAsync in Deferred.when should work with deferred objects", function() {
      var deferred_a, result_a, result_b;
      deferred_a = new Deferred(0);
      FreeMart.register('a', deferred_a);
      FreeMart.register('b', 'bb');
      result_a = null;
      result_b = null;
      Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b')).then(function(value_a, value_b) {
        result_a = value_a;
        return result_b = value_b;
      });
      deferred_a.resolve('aa');
      result_a.should.equal('aa');
      return result_b.should.equal('bb');
    });
    it("multiple requestAsync in Deferred.when should work if providers are registered later", function() {
      var deferred_a, result_a, result_b;
      result_a = null;
      result_b = null;
      Deferred.when(FreeMart.requestAsync('a'), FreeMart.requestAsync('b', 'bb')).then(function(value_a, value_b) {
        result_a = value_a;
        return result_b = value_b;
      });
      deferred_a = new Deferred(0);
      FreeMart.register('a', deferred_a);
      FreeMart.register('b', function(arg) {
        return arg;
      });
      deferred_a.resolve('aa');
      result_a.should.equal('aa');
      return result_b.should.equal('bb');
    });
    it("register can take regular expression as key", function() {});
    it("provider can optionally take key requested as first arg", function() {});
    return it("order of registration should be kept", function() {});
  });

}).call(this);
