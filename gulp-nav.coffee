###
 copyright (c) 2014 Jess Austin <jess.austin@gmail.com>, MIT license

 gulp-nav is a gulp plugin to help build navigation elements. gulp-nav adds
 "nav" objects to vinyl file objects. nav objects contain titles, (relative)
 href links, active flags, parents, children, and siblings. The last two
 properties are lists, which may optionally be ordered. For other than default
 behavior, call the exported function with an object that defines one or more
 of the following options:

   sources
   targets
   titles
   orders
   hrefExtension
   demoteTopIndex
   root
###

path = require 'path'
webPath = require './web-path'
through = require 'through2'
  .obj

module.exports =
  ({sources, targets, titles, orders, hrefExtension, demoteTopIndex,
  root}={}) ->
    # defaults
    sources ?= ['data', 'frontMatter']
    targets ?= ['nav', 'data.nav']
    titles ?= ['short_title', 'title']
    orders ?= 'order'
    hrefExtension ?= 'html'
    demoteTopIndex ?= no
    root ?= '/'               # XXX finish implementing this!
    # single options don't have to come wrapped in an Array
    sources = [ sources ] unless Array.isArray sources
    targets = [ targets ] unless Array.isArray targets
    titles  = [ titles ]  unless Array.isArray titles
    orders  = [ orders ]  unless Array.isArray orders

    files = []

    through (file, encoding, transformCallback) ->
      # if vinyl objects have different properties, take first defined
      source = (file[source] for source in sources).reduce (x, y) -> x ?= y
      source ?= file    # just look for title and order on the vinyl obj itself
      title = (source[title] for title in titles).reduce (x, y) -> x ?= y
      order = (source[order] for order in orders).reduce (x, y) -> x ?= y
      # insert new nav into the tree
      nav = insertNavIntoTree file.relative, hrefExtension, title, order, root
      # set properties of vinyl object XXX does this need error handling?
      for target in targets
        obj = file
        [properties..., last] = target.split '.' # for nested target properties
        obj = obj[property] ?= {} for property in properties
        obj[last] = nav
      # delay until we've seen them all...
      files.push file
      transformCallback()
    , (flushCallback) ->
      for name, child of navTree.children
        root = child
        rootName = name
      if demoteTopIndex       # top-level index becomes sibling of its children
        for name, child of root.children
          navTree.children[webPath.resolve rootName, name] = child
          child.parent = navTree
        root.children = {}
      # ...and now we've seen them all
      @push file for file in files
      flushCallback()

navTree =
  parent: null
  children: {}
  exists: no
  title: null

root = null
rootName = null

orderGen = 9999

insertNavIntoTree = (relativePath, extension, title, order, root) ->
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
  current.exists = yes             # if we're here, this resource *does* exist!
  current.title = title ? current.title     # overwrite defaults with non-nulls
  current.order = order ? current.order
  navInContext current, [_path.join '']

# Create the actual nav object that will be exposed to user code. This object
# knows (and the objects that it creates, in turn, know) the context in which
# it is exposed, so that it can expose accurate link information. Accessor
# properties are used because the structure is circular so we need some
# laziness.
navInContext = (nav, context) ->
  Object.defineProperties
    title: nav.title
    # how you get here from there, but only if here is an actual place
    href: webPath.relative context[0], webPath.resolve context... if nav.exists
    active: context[0] is webPath.resolve context... # ending where we started?
  ,
    parent:
      enumerable: yes             # these properties should be easy to find
      get: ->                     # they're accessors because we need lazy eval
        # if in a directory, go up a level
        postFix = if context[-1..][0][-1..] is '/' then '..' else '.'
        navInContext nav.parent, context.concat postFix
    children:
      enumerable: yes
      get: ->
        (navInContext child, context.concat name for [child, name] in (
          [child, name] for name, child of nav.children)
            .sort ([a, _], [b, __]) -> a.order - b.order)
    siblings:
      enumerable: yes
      get: ->
        @parent.children
    root:
      enumerable: yes
      get: ->
        navInContext root, context.concat rootName
