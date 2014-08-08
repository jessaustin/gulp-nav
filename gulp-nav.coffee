###
 copyright 2014 Jess Austin <jess.austin@gmail.com>, MIT license

 gulp-nav is a gulp plugin to help build navigation elements. gulp-nav adds
 "nav" objects to vinyl file objects. nav objects contain relative links,
 titles, parents, children, and siblings. (The last two properties are lists,
 which may optionally be ordered. If you'd like other than default behavior,
 call the exported function with an object that defines one or more of the
 following options:

   sourceProps
   destProps
   titleProps
   orderProps
   linkPre
   linkPost
###

path = require 'path'
through = require 'through2'
  .obj
util = require 'gulp-util'
inspect = require 'util'
  .inspect

files = []

module.exports =
  ({sourceProps, destProps, titleProps, orderProps, linkPre, linkPost}={}) ->
    # defaults
    sourceProps ?= ['data', 'frontMatter']
    destProps   ?= ['nav', 'data.nav']
    titleProps  ?= ['short_title', 'title']
    orderProps  ?= 'order'
    linkPre     ?= '/'
    linkPost    ?= '.html'
    # single options don't have to come wrapped in an Array
    sourceProps = [ sourceProps ] unless Array.isArray sourceProps
    destProps = [ destProps ] unless Array.isArray destProps
    titleProps = [ titleProps ] unless Array.isArray titleProps
    orderProps = [ orderProps ] unless Array.isArray orderProps

    through (file, encoding, callback) ->
      # if vinyl objects have different properties, take first defined
      source = (file[prop] for prop in sourceProps).reduce (x, y) -> x ?= y
      source ?= file    # just look for title and order on the vinyl obj itself
      title = (source[prop] for prop in titleProps).reduce (x, y) -> x ?= y
      order = (source[prop] for prop in orderProps).reduce (x, y) -> x ?= y
      # http://stackoverflow.com/questions/17200640/javascript-capitalize-first-letter-of-each-word-in-a-string-only-if-lengh-2
      title ?= path.basename file.relative
        .toLowerCase()
        .replace /([^a-z]|^)([a-z])(?=[a-z]{2})/g, (_, g1, g2) ->
          g1 + g2.toUpperCase()                             # sensible fallback
      order ?= null                            # XXX is setting this necessary?
      # now insert into the node tree and set properties of vinyl object
      obj = insertNode file.relative, title, order
      for prop in destProps
        current = file
        for part in prop.split '.'
          current[part] ?= {}
          current = current[part]
        current[part] = obj
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

insertNode = (relativePath, title, order) ->
  children = nodes
  current = null                               # XXX is setting this necessary?
  for pathElement in (path.normalize path.sep + relativePath).split path.sep
    if 0 is pathElement.lastIndexOf 'index'  # a pun! (index goes one level up)
      break
    unless pathElement of children  # if this path element is missing create it
      children[pathElement] =
        children: {}
        nav: {}
    parent = current
    current = children[pathElement]
    children = current.children
  current.nav.title = title
  current.nav.order = order
  do (parent, children) ->                             # XXX is 'do' necessary?
    Object.defineProperties current.nav,
      parent:
        enumerable: yes               # these properties should be easy to find
        # closures!
        get: ->
          parent?.nav
      children:
        enumerable: yes
        get: ->
          (child.nav for label, child of children)
            .sort (a, b) ->
              a.order ?= 999999
              b.order ?= 999999
              a.order - b.order
      siblings:
        enumerable: yes
        get: ->
          parent?.nav.children
    current.nav
