class App
  constructor: ->
    $(document).ready =>

  # Calls a function from the Aris v2 API.
  # The callback receives the entire JSON-decoded response.
  callAris: (func, json, cb) ->
    req = new XMLHttpRequest
    req.onreadystatechange = =>
      if req.readyState is 4
        if req.status is 200
          cb JSON.parse req.responseText
        else
          cb false
    req.open 'POST', "#{ARIS_URL}/json.php/v2.#{func}", true
    req.setRequestHeader 'Content-Type', 'application/x-www-form-urlencoded'
    req.send JSON.stringify json

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

appendTo = (parent, haml = '', attrs = {}, init = (->)) ->
  {tag, classes, id} = parseElement haml
  for c in classes
    attrs.class ?= ''
    attrs.class += " #{c}"
  attrs.id = id if id?
  child = $("<#{tag} />", attrs)
  init child
  parent.append ' '
  parent.append child
  parent.append ' '
  child

app = new App
window.app = app
