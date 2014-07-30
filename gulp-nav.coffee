# copyright 2014 Jess Austin, released under MIT license

# need parent, children, and siblings
# actually parent.children *is* siblings
# also need href, (sub?)title

path    = require 'path'
error   = require 'gulp-util'
  .PluginError
through = require 'through2'
  .obj
inspect = require 'util'
  .inspect

tree = {}

setNode = (relativePath, node) ->
  t = tree
  for pathElement in path.normalize path.sep + relativePath
  .split path.sep
    if 0 is pathElement.lastIndexOf 'index'    # a pun!
      break
    unless pathElement of t
      t[pathElement] =
        children: {}
    last = t[pathElement]
    t = last?.children
  console.log last, t
  if last
    for attr of node
      last[attr] = node[attr]


module.exports = (options={}) ->
  through (file, encoding, callback) ->
    setNode file.relative,
    #nodes[file.relative] =
      title: file.relative
        #  parent:
      #file: file
    callback()
  , (callback) ->
    # add .children
    #for node, props of nodes
    #  file = props.file
    #  props.
    #  file.nav = props
    console.log inspect tree, depth: null
    callback()
