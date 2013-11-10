chai.should()

describe FreeMart, ->
  it "should work", ->
    FreeMart.register 'key', 'value'
    FreeMart.request('key').should.equal 'value'

