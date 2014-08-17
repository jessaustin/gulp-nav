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
      source = (file[source] for source in sources).reduce (x, y) -> x ?= y
      source ?= file    # just look for title and order on the vinyl obj itself
      title = (source[title] for title in titles).reduce (x, y) -> x ?= y
      order = (source[order] for order in orders).reduce (x, y) -> x ?= y
      # insert new nav into the tree
      nav = insertNavIntoTree file.relative, hrefExtension, title, order
      # set properties of vinyl object
      for target in targets
        obj = file
        [props..., lastProp] = target.split '.'         # handle nested targets
        obj = obj[prop] ?= {} for prop in props
        obj[lastProp] = nav
      # delay until we've seen them all...
      files.push file
      transformCallback()
    , (flushCallback) ->
      # ...and now we've seen them all
      @push file for file in files
      console.log file for file in files
      #console.log (require 'util').inspect navTree, depth: null
      flushCallback()

navTree =
  parent: null
  children: {}
  exists: no
  title: null

orderGen = 9999

insertNavIntoTree = (relativePath, extension, title, order) ->
  _path = path.resolve '/', relativePath
    .replace /index\.[^/]+$/, ''              # index identified with directory
    .replace /\.[^./]+$/, '.' + extension     # e.g. '.jade' -> '.html'
    .split /([^/]*\/)/                        # e.g. '/a/b' -> ['/', 'a/', 'b']
    .filter (element) -> element isnt ''
  current = navTree
  for element in _path
    current = current.children[element] ?=   # recurse down, filling in missing
      parent: current
      children: {}
      exists: no                             # for directories without an index
      title: path.basename element.replace /\/?index[^/]*$/, ''
        .toLowerCase()
        .replace /\.[^.]*$/, ''                        # remove extension
        .replace /(?:^|[-._])[a-z]/g, (first) ->
          first.toUpperCase()                          # capitalize each word
        .replace /[-._]/g, ' '                         # punctuation to spaces
        .replace /^$/, '/'                             # root needs a title too
      order: orderGen++
  current.exists = yes                            # this resource *does* exist!
  if title
    current.title = title
  if order
    current.order = order
  navInContext current, _path

# create nav object with  
navInContext = (nav, context) ->
  nav and Object.defineProperties
    title: nav.title
    href: if nav.exists
      webPath.relative context[0], webPath.resolve context...
    active: context.length is 1
  ,
    parent:
      enumerable: yes             # these properties should be easy to find
      get: ->                     # they're accessors because we need lazy eval
        navInContext nav.parent, context.concat if context.slice(-1).slice(-1) is '/' then '..' else '.'
    children:
      enumerable: yes
      get: ->
        sorted = ([name, child] for name, child of nav.children)
          .sort ([_, a], [__, b]) ->
            a.order - b.order
        (navInContext child, context.concat name for [name, child] in sorted)
    siblings:
      enumerable: yes
      get: ->
        for name, sibling of nav.parent.children
          navInContext sibling, context.concat name
