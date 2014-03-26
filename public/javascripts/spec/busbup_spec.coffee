chai.should()

describe Busbup, ->
  it 'works', ->
    triggered = false
    Busbup.subscribe 'event', -> triggered = true
    Busbup.publish 'event'
    triggered.should.equal true

  it 'attaches to object', ->
    o = {}
    Busbup.create(o)

    triggered = false
    o.subscribe 'event', -> triggered = true
    o.publish 'event'
    triggered.should.equal true

