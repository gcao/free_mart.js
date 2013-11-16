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
    return it("requestAsync should work if provider is registered later", function() {
      FreeMart.requestAsync('key').then(function(result) {
        return result.should.equal('value');
      });
      return FreeMart.register('key', 'value');
    });
  });

}).call(this);
