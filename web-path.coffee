###
 copyright (c) 2014 Jess Austin <jess.austin@gmail.com>, MIT license

 Node's built-in path module doesn't deal with trailing slashes the way that
 web browsers and servers do. This module provides three functions: join,
 resolve, and relative. Each of these is equivalent to its respective function
 in the built-in path module, except that it does deal with trailing slashes
 the way that web browsers and servers do. 
###

path = require 'path'

# replace anything other than two periods after the last slash with a single
# period
trimBackToSlash = (str) ->    # this would be a one-liner if we had look-behind
  str.replace /(?:^)(?!\.\.$)[^/]*$/, '.'         # there was no slash
    .replace /(?:\/)(?!\.\.$)[^/]*$/, '/.'        # keep the slash

module.exports =
  join: (paths...) ->
    last = paths.pop()
    path.join (trimBackToSlash p for p in paths)..., last
  resolve: (from..., to) ->
    (path.resolve (trimBackToSlash f for f in from)..., to) +
    if to.match /\/\.?\.?$/ then '/' else ''
  relative: (from, to) ->
    (path.relative (trimBackToSlash from), to) or '.'
