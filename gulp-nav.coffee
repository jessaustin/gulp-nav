###
 copyright (c) 2014 Jess Austin <jess.austin@gmail.com>, MIT license

 gulp-nav is a gulp plugin to help build navigation elements. gulp-nav adds
 "nav" objects to vinyl file objects. nav objects contain relative links,
 titles, parents, children, and siblings. (The last two properties are lists,
 which may optionally be ordered. If you'd like other than default behavior,
 call the exported function with an object that defines one or more of the
 following options:

   sources
   targets
   titles
   orders
   hrefPost
###

path = require 'path'
through = require 'through2'
  .obj
inspect = require 'util'
  .inspect

# example: error @emit, "problem with #{file.relative}"
error = do (util = require 'gulp-util') ->
  (emitter, message) ->
    emitter util.PluginError 'gulp-nav', message

files = []

module.exports = ({sources, targets, titles, orders, hrefPost}={}) ->
  # defaults
  sources  ?= ['data', 'frontMatter']
  targets  ?= ['nav', 'data.nav']
  titles   ?= ['short_title', 'title']
  orders   ?= 'order'
  hrefPost ?= '.html'
  # single options don't have to come wrapped in an Array
  sources = [ sources ] unless Array.isArray sources
  targets = [ targets ] unless Array.isArray targets
  titles =  [ titles ]  unless Array.isArray titles
  orders =  [ orders ]  unless Array.isArray orders

  through (file, encoding, transformCallback) ->
    # if vinyl objects have different properties, take first defined
    source = (file[prop] for prop in sources).reduce (x, y) -> x ?= y
    source ?= file      # just look for title and order on the vinyl obj itself
    title = (source[prop] for prop in titles).reduce (x, y) -> x ?= y
    order = (source[prop] for prop in orders).reduce (x, y) -> x ?= y
    # sensible fallback
    title ?= path.basename file.relative.replace /\/?index[^/]*$/, ''
      .toLowerCase()
      .replace /\.[^.]*$/, ''                    # remove extension
      .replace /(?:^|[-._])[a-z]/g, (first) ->
        first.toUpperCase()                      # capitalize words
      .replace /[-._]/g, ' '                     # change punctuation to spaces
      .replace /^$/, '/'
    order ?= null                   # XXX is setting this necessary?
    # now insert into the node tree
    nav = insertNav file.relative, title, order, hrefPost
    # now set properties of vinyl object
    for prop in []    # XXX use targets!
      tgt = file
      for part in (prop.split '.')[...-1]
        console.log part
        tgt[part] ?= {}
        tgt = tgt[part]
      tgt[(prop.split '.')[-1]] = nav
    file['data'] =    # XXX use targets!
      nav: nav
    file['nav'] = nav
    # delay until we've seen them all...
    files.push file
    transformCallback()
  , (flushCallback) ->
    # ...and now we've seen them all
    @push file for file in files
    flushCallback()

navTree =
  children: {}
insertNav = (relativePath, title, order, post) ->
  _path = path.resolve '/', relativePath
  current = navTree
  for element in _path.split path.sep
    if element.match /^index\./
      break
    unless element of current.children
      current.children[element] = children: {}
    parent = current
    current = current.children[element]
  current.title = title
  current.parent = parent
  current.order = order
  visitedNav current, post, [_path]

# this function creates the objects that we actually put 
visitedNav = (nav, post, context) ->
  console.log context
  nav and Object.defineProperties
    title: nav.title
    href: path.relative context[0], path.resolve context...
    active: context.length is 1
  , # the following properties are accessors in order to get lazy evaluation
    parent:
      enumerable: yes                 # these properties should be easy to find
      get: ->
        visitedNav nav?.parent, post, context.concat '..'
    children:
      enumerable: yes
      get: -> # XXX ordering
        (visitedNav child, post, context.concat name for name, child of nav.children)
    siblings:
      enumerable: yes
      get: ->
        (visitedNav sibling, post, context.concat name for name, sibling of nav?.parent.children)
