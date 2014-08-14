###
 copyright (c) 2014 Jess Austin <jess.austin@gmail.com>, MIT license

 gulp-nav is a gulp plugin to help build navigation elements. gulp-nav adds
 "nav" objects to vinyl file objects. nav objects contain relative links,
 titles, parents, children, and siblings. (The last two properties are lists,
 which may optionally be ordered. If you'd like other than default behavior,
 call the exported function with an object that defines one or more of the
 following options:

   sources
   destinations
   titles
   orders
   hrefPost
###

path = require 'path'
through = require 'through2'
  .obj
util = require 'gulp-util'
inspect = require 'util'
  .inspect

files = []

module.exports = ({sources, destinations, titles, orders, hrefPost}={}) ->
  # defaults
  sources      ?= ['data', 'frontMatter']
  destinations ?= ['nav', 'data.nav']
  titles       ?= ['short_title', 'title']
  orders       ?= 'order'
  hrefPost     ?= '.html'
  # single options don't have to come wrapped in an Array
  sources =      [ sources ]      unless Array.isArray sources
  destinations = [ destinations ] unless Array.isArray destinations
  titles =       [ titles ]       unless Array.isArray titles
  orders =       [ orders ]       unless Array.isArray orders

  through (file, encoding, callback) ->
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
    order ?= null                   # XXX is setting this necessary?
    # now insert into the node tree and set properties of vinyl object
    obj = insertNode file.relative, title, order, hrefPost
    for prop in []    # XXX use destinations!
      current = file
      for part in (prop.split '.')[...-1]
        console.log part
        current[part] ?= {}
        current = current[part]
      current[(prop.split '.')[-1]] = obj
    file['data'] =    # XXX use destinations!
      nav: obj
    file['nav'] = obj
    # delay until we've seen them all...
    files.push file
    callback()
  , (callback) ->
    # ...and now we've seen them all
    @push file for file in files
    callback()

# XXX how to include file? anyway shouldn't the result be returned?
error = (file, message) ->
  util.PluginError 'gulp-nav', message

nodes = {}

relativeNavFunc = (relativePath, hrefPost) ->
  relativeNav = (there, therePath, relativeFunc=relativeNav) ->
    there and obj =
      href:                        # goofy 3-line because of v1.7.1 parsing bug
        path.relative relativePath, therePath
          .replace /\.[^./]*$/, hrefPost
      active: relativePath is therePath
      title: there.title
      children: there?.child_set

insertNode = (relativePath, title, order, hrefPost) ->
  relativePath = path.resolve '/', relativePath
  children = nodes
  current = null                               # XXX is setting this necessary?
  for pathElement in relativePath.split path.sep
    if 0 is pathElement.lastIndexOf 'index'  # a pun! (index goes one level up)
      break
    unless pathElement of children  # if this path element is missing create it
      children[pathElement] = {}
      Object.defineProperty children[pathElement], 'child_set', value: {}
    parent = current
    current = children[pathElement]
    children = current.child_set
  current.title = title
  current.order = order
  do (parent, children) ->                             # XXX is 'do' necessary?
    Object.defineProperties current,
      parent:
        enumerable: yes               # these properties should be easy to find
        get: ->                       # closures!
          relativeNav parent, path.dirname relativePath
      children:
        enumerable: yes
        get: ->
          (relativeNav child for child in (child for label, child of children)
            .sort (a, b) ->
              a.order ?= 999999
              b.order ?= 999999
              a.order - b.order)
      siblings:
        enumerable: yes
        get: ->
          parent?.children
    current
