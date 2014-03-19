chai.should()

describe Busbup, ->
  it 'works', ->
    triggered = false
    Busbup.subscribe 'event', -> triggered = true
    Busbup.publish 'event'
    triggered.should.equal true

