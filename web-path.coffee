###
 copyright (c) 201{4,5} Jess Austin <jess.austin@gmail.com>, MIT license

 Node's built-in path module doesn't know how trailing slashes are used on the
 web. The replacement functions in this module know how to deal with trailing
 slashes. For example:

    > path.resolve('/a/b/c', 'd.html');
    '/a/b/c/d.html'
    > webPath.resolve('/a/b/c', 'd.html');
    '/a/b/d.html'
    > webPath.resolve('/a/b/c/', 'd.html');
    '/a/b/c/d.html'
###

path = require 'path'

# replace anything other than two periods after the last slash with a single
# period
trimBackToSlash = (str) ->    # this would be a one-liner if we had look-behind
  str.replace /(?:^)(?!\.\.$)[^/]*$/, '.'                  # there was no slash
    .replace /(?:\/)(?!\.\.$)[^/]*$/, '/.'                 # keep the slash

module.exports =
  resolve: (from..., to) ->
    (path.posix.resolve (trimBackToSlash f for f in from)..., to) +
    if to.match /.\/\.?\.?$/ then '/' else ''
  relative: (from, to) ->
    (path.posix.relative (trimBackToSlash from), to) or '.'
