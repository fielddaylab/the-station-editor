React = require 'react'
update = require 'react-addons-update'

# Parses a string like "tag#id.class1.class2" into its separate parts.
parseElement = (str) ->
  eatWord = ->
    hash = str.indexOf '#'
    dot  = str.indexOf '.'
    hash = 9999 if hash is -1
    dot  = 9999 if dot  is -1
    word = str[... Math.min(hash, dot)]
    str = str[word.length ..]
    word
  tag = eatWord() or 'div'
  classes = []
  id = null
  until str is ''
    if str[0] is '.'
      str = str[1..]
      classes.push eatWord()
    else if str[0] is '#'
      str = str[1..]
      id = eatWord()
    else
      return false
  {tag, classes, id}

# Why yes, the following functions form an imperative layer (writer monad) over a functional layer (React) over an imperative layer (DOM manipulation) over a functional layer (HTML), problem?
make = (fact, arg1, arg2) ->
  if arg1?
    if typeof arg1 is 'function'
      startProps = {}
      fn = arg1
    else
      startProps = arg1
      fn = arg2 ? (->)
  else
    startProps = {}
    fn = (->)
  prevParent = window.theParent
  if typeof fact is 'string'
    {tag, classes, id} = parseElement fact
    factory = tag
    startProps = update startProps,
      className:
        if classes.length > 0
          $apply: (oldClasses) -> "#{oldClasses ? ''} #{classes.join(' ')}"
        else
          {}
      id: if id? then $set: id else {}
  else
    factory = fact
  window.theParent =
    props: startProps
    children: []
  fn()
  me = React.createElement factory, window.theParent.props, window.theParent.children...
  window.theParent = prevParent
  me
child = (args...) ->
  me = make args...
  window.theParent = update window.theParent,
    children: $push: [me]
raw = (raws...) ->
  window.theParent = update window.theParent,
    children: $push: raws
props = (obj) ->
  window.theParent = update window.theParent,
    props: $merge: obj
addClass = (classes...) ->
  classes = [].concat.apply([], classes) # flatten into an array of strings
  window.theParent = update window.theParent,
    props:
      className:
        $apply: (oldClasses) -> "#{oldClasses ? ''} #{classes.join(' ')}"

for k, v of {make, child, raw, props, addClass}
  exports[k] = v
