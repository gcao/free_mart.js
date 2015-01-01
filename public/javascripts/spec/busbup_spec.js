// Generated by CoffeeScript 1.7.1
(function() {
  chai.should();

  describe(Busbup, function() {
    it('works', function() {
      var triggered;
      triggered = false;
      Busbup.subscribe('event', function() {
        return triggered = true;
      });
      Busbup.publish('event');
      return triggered.should.equal(true);
    });
    return it('attaches to object', function() {
      var o, triggered;
      o = {};
      Busbup.create(o);
      triggered = false;
      o.subscribe('event', function() {
        return triggered = true;
      });
      o.publish('event');
      return triggered.should.equal(true);
    });
  });

}).call(this);