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
      FreeMart.register('key', function(_, arg1, arg2) {
        return "value " + arg1 + " " + arg2;
      });
      return FreeMart.request('key', 'a', 'b').should.equal('value a b');
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
        return 'value';
      });
      result = null;
      FreeMart.requestAsync('key').then(function(value) {
        return result = value;
      });
      return result.should.equal('value');
    });
    return it("requestAsync should work with promises", function() {
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
  });

}).call(this);
