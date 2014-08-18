###
 copyright (c) 2014 Jess Austin <jess.austin@gmail.com>, MIT license

 gulp-nav is a gulp plugin to help build navigation elements. gulp-nav adds
 "nav" objects to vinyl file objects. nav objects contain relative links,
 titles, parents, children, and siblings. (The last two properties are lists,
 which may optionally be ordered. For other than default behavior, call the
 exported function with an object that defines one or more of the following
 options:

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

files = []

module.exports =
  ({sources, targets, titles, orders, hrefExtension, demoteTopIndex,
  root}={}) ->
    # defaults
    sources ?= ['data', 'frontMatter']
    targets ?= ['nav', 'data.nav']
    titles ?= ['short_title', 'title']
    orders ?= 'order'
    hrefExtension ?= 'html'
    demoteTopIndex ?= yes     # XXX implement this!
    root ?= '/'               # XXX finish implementing this!
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
      # ...and now we've seen them all
      @push file for file in files
      console.log (require 'util').inspect navTree, depth: null
      flushCallback()

navTree =
  parent: null
  children: {}
  exists: no
  title: null

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
  current.title = title if title   # overwrite defaults
  current.order = order if order
  navInContext current, root, [_path.join '']

# create nav object with  
navInContext = (nav, root, context) ->
  if nav
    isDir = context[-1..][0][-1..] is '/'            # is this nav a directory?
    href = webPath.relative context[0], webPath.resolve context...
    Object.defineProperties
      title: nav.title
      href: href if nav.exists
      active: if isDir then href is '.' else href is context[-1..][0]
    ,
      parent:
        enumerable: yes           # these properties should be easy to find
        get: ->                   # they're accessors because we need lazy eval
          navInContext nav.parent, root,
          context.concat if isDir then '..' else '.'
      children:
        enumerable: yes
        get: ->
          (navInContext child, root, context.concat name for name, child of nav
            .children)
      siblings:
        enumerable: yes
        get: ->
          @parent.children
      root:
        enumerable: yes
        get: ->
          webPath.relative context[0], root
