###
 copyright (c) 2014 Jess Austin <jess.austin@gmail.com>, MIT license

 gulp-nav is a gulp plugin to help build navigation elements. gulp-nav adds
 "nav" objects to vinyl file objects. nav objects contain titles, (relative)
 href links, active flags, parents, children, and siblings. The last two
 properties are lists, which may optionally be ordered. For other than default
 behavior, call the exported function with an object that defines one or more
 of the following options (the first five can be a single property name, or an
 array of property names):

   sources
   targets
   titles
   orders
   skips
   hrefExtension
   demoteTopIndex
###

path    = require 'path'
through = require 'through2'
webPath = require './web-path'

root = rootName = null                            # global vars easier for this

module.exports = ({sources, targets, titles, orders, skips, hrefExtension,
  demoteTopIndex}={}) ->
    # defaults -- the first five are just arrays of property names
    sources ?= ['data', 'frontMatter']
    targets ?= ['nav', 'data.nav']
    titles  ?= ['short_title', 'title']
    orders  ?= 'order'
    skips   ?= 'skipThis'
    hrefExtension ?= 'html'
    demoteTopIndex ?= no
    # single options don't have to come wrapped in an Array
    sources = [ sources ] unless Array.isArray sources
    targets = [ targets ] unless Array.isArray targets
    titles  = [ titles ]  unless Array.isArray titles
    orders  = [ orders ]  unless Array.isArray orders
    skips   = [ skips ]   unless Array.isArray skips

    # scaffolding for crawling the directory structure
    files = []
    navTree =
      parent: null
      children: {}
      exists: no
      title: null
    orderGen = 9999

    through.obj (file, encoding, transformCallback) ->
      # if vinyl objects have different properties, take first that exists
      source = (file[source] for source in sources).reduce (x, y) -> x ?= y
      source ?= file         # just look for properties on the vinyl obj itself
      title = (source[title] for title in titles).reduce (x, y) -> x ?= y
      order = (source[order] for order in orders).reduce (x, y) -> x ?= y
      # skip this file?
      for skip in skips
        if skip of source and source[skip]
          @push file
          return transformCallback()
      # normalize the path and break it into its constituent elements
      _path = path.resolve '/', file.relative
        .replace /index\.[^/]+$/, ''          # index identified with directory
        .replace /\.[^./]+$/, '.' + hrefExtension     # e.g. '.jade' -> '.html'
        .split /([^/]*\/)/                    # e.g. '/a/b' -> ['/', 'a/', 'b']
        .filter (element) -> element isnt ''
      # find the right spot for the new resource
      current = navTree
      for element in _path
        current = current.children[element] ?= # recurse down the path, filling
          parent: current                      # in tree with missing elements
          children: {}
          exists: no                           # for directories without index
          title: path.basename element.replace /\/?index[^/]*$/, ''
            .toLowerCase()
            .replace /\.[^.]*$/, ''                    # remove extension
            .replace /(?:^|[-._])[a-z]/g, (first) ->
              first.toUpperCase()                      # capitalize each word
            .replace /[-._]/g, ' '                     # punctuation to spaces
            .replace /^$/, '/'                         # root needs a title too
          order: orderGen++
      # clean up the leaf
      current.exists = yes         # if we're here, this resource *does* exist!
      current.title = title ? current.title # overwrite defaults with non-nulls
      current.order = order ? current.order
      # use leaf to make the nav object
      nav = navInContext current, [_path.join '']
      # set properties of vinyl object XXX does this need error handling?
      for target in targets
        obj = file
        [properties..., last] = target.split '.'      # for nested target props
        obj = obj[property] ?= {} for property in properties
        obj[last] = nav
      # delay until we've seen them all...
      files.push file
      transformCallback()
    , (flushCallback) ->                   # (still in the call to through.obj)
      for name, child of navTree.children                    # there's only one
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
        postFix = if context[-1..][0][-1..] in ['/', '.'] then '..' else '.'
        navInContext nav.parent, context.concat postFix
    children:
      enumerable: yes
      get: ->
        (navInContext child, context.concat name for [child, name] in (
          [child, name] for name, child of nav.children)
            .sort ([a, ...], [b, ...]) -> a.order - b.order)
    siblings:
      enumerable: yes
      get: ->
        @parent.children
    root:
      enumerable: yes
      get: ->
        navInContext root, context.concat rootName
