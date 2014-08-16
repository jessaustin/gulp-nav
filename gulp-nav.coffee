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
   hrefExtension
   demoteTopIndex
###

path = require 'path'
webPath = require './web-path'
through = require 'through2'
  .obj

files = []

module.exports =
  ({sources, targets, titles, orders, hrefExtension, demoteTopIndex}={}) ->
    # defaults
    sources ?= ['data', 'frontMatter']
    targets ?= ['nav', 'data.nav']
    titles ?= ['short_title', 'title']
    orders ?= 'order'
    hrefExtension ?= 'html'
    demoteTopIndex ?= yes     # XXX implement this!
    # single options don't have to come wrapped in an Array
    sources = [ sources ] unless Array.isArray sources
    targets = [ targets ] unless Array.isArray targets
    titles  = [ titles ]  unless Array.isArray titles
    orders  = [ orders ]  unless Array.isArray orders

    through (file, encoding, transformCallback) ->
      # if vinyl objects have different properties, take first defined
      source = (file[prop] for prop in sources).reduce (x, y) -> x ?= y
      source ?= file    # just look for title and order on the vinyl obj itself
      title = (source[prop] for prop in titles).reduce (x, y) -> x ?= y
      order = (source[prop] for prop in orders).reduce (x, y) -> x ?= y
      # insert new nav into the tree
      nav = insertNav file.relative, hrefExtension, title, order
      # set properties of vinyl object
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
      #console.log (require 'util').inspect navTree, depth: null
      flushCallback()

navTree =
  exists: no
  title: null
  parent: null
  children: {}

orderGen = 9999

insertNav = (relativePath, extension, title, order) ->
  _path = path.resolve '/', relativePath
    .replace /index\.[^/]+$/, ''
    .replace /\.[^./]+$/, '.' + extension
    .split /([^/]*\/)/
    .filter (element) -> element isnt ''
  current = navTree
  for element in _path
    current = current.children[element] ?=   # recurse down, filling in missing
      children: {}
      parent: current
      exists: no                             # for directories without an index
      title: path.basename element.replace /\/?index[^/]*$/, ''
        .toLowerCase()
        .replace /\.[^.]*$/, ''                  # remove extension
        .replace /(?:^|[-._])[a-z]/g, (first) -> # capitalize words
          first.toUpperCase()
        .replace /[-._]/g, ' '                   # change punctuation to spaces
        .replace /^$/, '/'                       # root needs a title too
      order: orderGen++
  current.exists = yes                            # this resource *does* exist!
  if title
    current.title = title
  if order
    current.order = order
  visitednav current, _path

# this function creates the objects that we actually put 
visitednav = (nav, context) ->
  nav and Object.defineProperties
    title: nav.title
    href: if nav.exists
      webPath.relative context[0], webPath.resolve context...
    active: context.length is 1
  ,
    parent:    # these properties are accessors in order to get lazy evaluation
      enumerable: yes                 # these properties should be easy to find
      get: ->
        #console.log nav.parent, context
        visitednav nav.parent, context.concat '.'
    children:
      enumerable: yes
      get: ->
        sorted = ([name, child] for name, child of nav.children)
          .sort ([_, a], [__, b]) ->
            a.order - b.order
        (for [name, child] in sorted
          visitednav child, context.concat name + '/')
    siblings:
      enumerable: yes
      get: ->
        for name, sibling of nav.parent.children
          visitednav sibling, context.concat name
