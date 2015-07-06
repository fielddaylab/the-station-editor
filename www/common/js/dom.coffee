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

# Function for creating, initializing, and appending DOM elements.
appendTo = (parents, haml = '', attrs = {}, init = (->)) ->
  {tag, classes, id} = parseElement haml
  for c in classes
    attrs.class ?= ''
    attrs.class += " #{c}"
  attrs.id = id if id?
  children = for p in parents
    p = $(p)
    child = $("<#{tag} />", attrs)
    init child
    p.append ' '
    p.append child
    p.append ' '
    child
  if children.length is 1
    $(children[0])
  else
    $(children)

window.appendTo = appendTo

entityMap =
  '&': '&amp;'
  '<': '&lt;'
  '>': '&gt;'
  '"': '&quot;'
  "'": '&#39;'
  '/': '&#x2F;'

escapeHTML = (str) ->
  String(str).replace(/[&<>"'\/]/g, (s) -> entityMap[s])

window.escapeHTML = escapeHTML
