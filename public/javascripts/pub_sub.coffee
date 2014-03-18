VERSION = "0.5.0"

# http://arbiterjs.com/
create_arbiter = ->
  subscriptions = {}
  wildcard_subscriptions = {}
  persistent_messages = {}
  id_lookup = {}
  new_id = 1

  create: ->
    create_arbiter()

  subscribe: ->
    msg = undefined
    messages = undefined
    subscription_list = undefined
    persisted_subscription_list = undefined
    subscription = undefined
    func = undefined
    options = {}
    context = undefined
    wildcard = false
    priority = 0
    id = undefined
    return_ids = []
    return null  if arguments_.length < 2
    messages = arguments_[0]
    func = arguments_[arguments_.length - 1] # Function is always last argument
    options = arguments_[1] or {}  if arguments_.length > 2
    context = arguments_[2]  if arguments_.length > 3
    priority = options.priority  if options.priority
    messages = messages.split(/[,\s]+/)  if typeof messages is "string"
    i = 0

    while i < messages.length
      msg = messages[i]
      
      # If the message ends in *, it's a wildcard subscription
      if /\*$/.test(msg)
        wildcard = true
        msg = msg.replace(/\*$/, "")
        subscription_list = wildcard_subscriptions[msg]
        wildcard_subscriptions[msg] = subscription_list = []  unless subscription_list
      else
        subscription_list = subscriptions[msg]
        subscriptions[msg] = subscription_list = []  unless subscription_list
      id = new_id++
      subscription =
        id: id
        f: func
        p: priority
        self: context
        options: options

      id_lookup[id] = subscription
      subscription_list.push subscription
      
      # Sort the list by priority
      subscription_list = subscription_list.sort((a, b) ->
        (if a.p > b.p then -1 else (if a.p is b.p then 0 else 1))
      )
      
      # Put it back in after sorting
      if wildcard
        wildcard_subscriptions[msg] = subscription_list
      else
        subscriptions[msg] = subscription_list
      return_ids.push id
      
      # Check to see if there are any persistent messages that need
      # to be fired immediately
      if not options.persist and persistent_messages[msg]
        persisted_subscription_list = persistent_messages[msg]
        j = 0

        while j < persisted_subscription_list.length
          subscription.f.call subscription.self, persisted_subscription_list[j],
            persist: true

          j++
      i++
    
    # Return an array of id's, or just 1
    return return_ids  if messages.length > 0
    return_ids[0]

  publish: (msg, data, options) ->
    async_timeout = 10
    result = undefined
    overall_result = true
    cancelable = true
    internal_data = {}
    subscriber = undefined
    wildcard_msg = undefined
    subscription_list = subscriptions[msg] or []
    options = options or {}
    
    # Look through wildcard subscriptions to find any that apply
    for wildcard_msg of wildcard_subscriptions
      subscription_list = subscription_list.concat(wildcard_subscriptions[wildcard_msg])  if msg.indexOf(wildcard_msg) is 0
    if options.persist is true
      persistent_messages[msg] = []  unless persistent_messages[msg]
      persistent_messages[msg].push data
    return overall_result  if subscription_list.length is 0
    cancelable = options.cancelable  if typeof options.cancelable is "boolean"
    i = 0

    while i < subscription_list.length
      subscriber = subscription_list[i]
      continue  if subscriber.unsubscribed # Ignore unsubscribed listeners
      try
        
        # Publisher OR subscriber may request async
        if options.async is true or (subscriber.options and subscriber.options.async)
          setTimeout ((inner_subscriber) ->
            ->
              inner_subscriber.f.call inner_subscriber.self, data, msg, internal_data
              return
          )(subscriber), async_timeout++
        else
          result = subscriber.f.call(subscriber.self, data, msg, internal_data)
          break  if cancelable and result is false
      catch e
        overall_result = false
      i++
    overall_result

  unsubscribe: (id) ->
    if id_lookup[id]
      id_lookup[id].unsubscribed = true
      return true
    false

@Arbiter = create_arbiter()

