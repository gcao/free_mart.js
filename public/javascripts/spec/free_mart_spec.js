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
      FreeMart.register('key', 'value');
      return FreeMart.requestAsync('key').then(function(result) {
        return result.should.equal('value');
      });
    });
    it("requestAsync should work with functions", function() {
      FreeMart.register('key', function() {
        return 'value';
      });
      return FreeMart.requestAsync('key').then(function(result) {
        return result.should.equal('value');
      });
    });
    it("requestAsync should work with promises", function() {
      var deferred;
      deferred = new Deferred();
      FreeMart.register('key', deferred);
      FreeMart.requestAsync('key').then(function(result) {
        return result.should.equal('value');
      });
      return deferred.resolve('value');
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
    return it("multiple requestAsync should work if provider is registered later", function() {
      var result_a, result_b, result_c;
      result_a = null;
      FreeMart.requestAsync('key', 'a').then(function(value) {
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
      result_a.should.equal('a');
      result_b.should.equal('b');
      return result_c.should.equal('c');
    });
  });

}).call(this);
