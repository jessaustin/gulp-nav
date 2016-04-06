###
 copyright © 201{4,5,6} Jess Austin <jess.austin@gmail.com>, MIT license

 gulp-nav is a gulp plugin to help build navigation elements. gulp-nav adds
 "nav" objects to vinyl file objects. nav objects contain titles, (relative)
 href links, active flags, parents, children, and siblings. The last two
 properties are arrays, which optionally may be ordered. For other than default
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

{basename} = require 'path'
through = require 'through2'

module.exports = ({ sources=['data', 'frontMatter'],
  targets=['nav', 'data.nav'], titles=['short_title', 'title'], orders='order',
  skips='skipThis', hrefExtension='html', demoteTopIndex=no }={}) ->
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
    root = {}

    through.obj (file, encoding, transformCallback) ->
      # if vinyl objects have different properties, take first that exists
      source = (file[source] for source in sources).reduce soak
      source ?= file         # just look for properties on the vinyl obj itself
      title = (source[title] for title in titles).reduce soak
      order = (source[order] for order in orders).reduce soak
      # skip this file?
      for skip in skips
        if skip of source and source[skip]
          return transformCallback null, file
      # normalize the path and break it into its constituent elements
      path = resolve '/', file.relative.replace /\\/g, '/'
        .replace /index\.[^/]+$/, ''          # index identified with directory
        .replace /\.[^./]+$/, '.' + hrefExtension     # e.g. '.jade' -> '.html'
      # find the right spot for the new resource
      current = navTree
      for element in (path.split /([^/]*\/)/  # e.g. '/a/b' -> ['/', 'a/', 'b']
          .filter (element) -> element isnt '')
        current = current.children[element] ?= # recurse down the path, filling
          parent: current                      # in tree with missing elements
          children: {}
          exists: no                           # for directories without index
          order: orderGen++
          title: basename element.replace /\/?index[^/]*$/, ''
            .toLowerCase()
            .replace /\.[^.]*$/, ''                    # remove extension
            .replace /[-._]/g, ' '                     # punctuation to spaces
            .replace /\b\w/g, (first) ->
              first.toUpperCase()                      # capitalize each word
            .replace /^$/, '/'                         # root needs a title too
      # clean up the leaf
      current.exists = yes         # if we're here, this resource *does* exist!
      current.title = title ? current.title # overwrite defaults with non-nulls
      current.order = order ? current.order
      # use leaf to make the nav object
      nav = navInContext current, [path], root
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
        root.obj = child
        root.name = name
      if demoteTopIndex       # top-level index becomes sibling of its children
        for name, child of root.obj.children
          navTree.children[resolve root.name, name] = child
          child.parent = navTree
        root.obj.children = {}
      # ...and now we've seen them all
      # XXX should put debug() call here
      @push file for file in files
      flushCallback()

# Create the actual nav object that will be exposed to user code. This object
# knows (and the objects that it creates, in turn, know) the context in which
# it is exposed, so that it can expose accurate link information. Accessor
# properties are used because the structure is circular so we need some
# laziness.
navInContext = (nav, context, root) ->
  postFix = if context[-1..][0][-1..] in ['/', '.'] then '..' else '.'
  Object.defineProperties
    title: nav.title
    # how you get here from there, but only if here is an actual place
    href: relative context[0], resolve context... if nav.exists
    active: context[0] is resolve context... # ending where we started?
  ,
    parent:
      enumerable: yes             # these properties should be easy to find
      get: ->                     # they're accessors because we need lazy eval
        navInContext nav.parent, context.concat(postFix), root
    children:
      enumerable: yes
      get: ->
        (navInContext child, context.concat(name), root for [child, name] in (
          [child, name] for name, child of nav.children)
            .sort ([a, ...], [b, ...]) -> a.order - b.order)
    siblings:
      enumerable: yes
      get: ->
        @parent.children
    root:
      enumerable: yes
      get: ->
        navInContext root.obj, context.concat(root.name), root

# relative() and resolve() are just like the path functions, except trailing
# slashes are significant since we're dealing with URLs
relative = (source, target) ->
  source = source.split '/'
  target = target.split '/'
  target.shift() while source.length and source.shift() is last = target[0]
  ('..' for _ in source)                              # ascend out of remaining
    .concat if target.length then target else last    # descend into remaining
    .join '/'
    .replace /(^|\.\/)$/, '.'

url = require 'url'
# allow url.resolve() to take more than two args
resolve = (parts...) ->
  parts.reduce url.resolve

soak = (x, y) ->
  x ? y
