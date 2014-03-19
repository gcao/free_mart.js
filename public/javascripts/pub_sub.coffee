callbacks = {}

@subscribe = (event, callback) ->
  if callbacks.hasOwnProperty(event)
    callbacks[event].push callback
  else
    callbacks[event] = [callback]

@unsubscribe = (event, callback) ->
  if callbacks[event]
    index = callbacks[event].indexOf(callback)
    if index >= 0
      callbacks[event].splice index, 1

    if callbacks[event].length is 0
      delete callbacks[event]

@publish = (event, args...) ->
  # check callbacks before triggering the event
  myCallbacks = callbacks[event]

  if myCallbacks and myCallbacks.length > 0
    for callback, i in myCallbacks by -1
      if callback.removeIf and callback.removeIf()
        myCallbacks.splice(i, 1)

    if myCallbacks.length > 0
      for callback in myCallbacks
        callback(event, args...)
    else
      delete callbacks[event]

