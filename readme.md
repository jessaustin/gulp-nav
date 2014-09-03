gulp-nav
========

[![Build Status](https://travis-ci.org/jessaustin/gulp-nav.svg?branch=master)](https://travis-ci.org/jessaustin/gulp-nav "Travis")
[![Dependency Status](https://david-dm.org/jessaustin/gulp-nav.svg)](https://david-dm.org/jessaustin/gulp-nav "David")
[![devDependency Status](https://david-dm.org/jessaustin/gulp-nav/dev-status.svg)](https://david-dm.org/jessaustin/gulp-nav#info=devDependencies "David for dev dependencies")
[![NPM](https://nodei.co/npm/gulp-nav.png)](https://nodei.co/npm/gulp-nav/ "npmjs")

A [gulp](http://gulpjs.com/) plugin to help build navigation or breadcrumb
elements implicitly from the file structure of our package. The goal is to be
useful with e.g. [Bootstrap .nav
classes](http://getbootstrap.com/components/#nav) and our favorite templating
system. (I like [Jade](http://jade-lang.com/)!)

Imagine we have some source files in a directory hierarchy:
```
  .
  ├── greek
  │   ├── alpha.jade
  │   ├── beta.jade
  │   └── gamma.jade
  ├── index.jade
  ├── latin
  │   ├── b.jade
  │   ├── c.jade
  │   ├── index.jade
  │   └── letter-a.jade
  ├── one.jade
  ├── three.jade
  └── two.jade
```
We know how to [`.pipe`](http://nodejs.org/api/stream.html#stream_readable_pipe_destination_options)
these through appropriate plugins and transforms, leaving us with a bunch of
output pages in a similar directory hierarchy. What about links between those
pages, however? We don't want to hardcode that stuff! While each file is piped
through, an object stored as a property of the [vinyl
file object](https://github.com/wearefractal/vinyl#file), which knows where
other files are located and what they are called, could be really useful to
template plugins. With that information, a template could be written to build
navbars, breadcrumbs, or whatever we want on our generated page.

What would this look like? If we had this in our
([coffeescript](http://coffeescript.org/)) gulpfile...

```coffeescript
  gulp = require 'gulp'
  data = require 'gulp-data'
  matter = require 'jade-var-matter'
  nav = require 'gulp-nav'
  jade = require 'gulp-jade'

  gulp.task 'default', ->
    gulp.src 'test/**/*.jade'
      .pipe data (file) ->
        matter String file.contents
      .pipe nav()
      .pipe jade pretty: true
      .pipe gulp.dest 'dist'
```

...and our template file had something like this...

```jade
    nav
      ul.nav.nav-tabs
        for sibling in nav.siblings
          li
            a(href=sibling.href)= sibling.title
```

...that would be enough to generate easy, maintainable navbars! [This slightly
more elaborate template file](test/index.jade) generates the nav for [the demo
site](http://jessaustin.github.io/gulp-nav/).

The `nav` object referenced above has the following properties:

|          |                                                                  |
| -------- | ---------------------------------------------------------------- |
| title    | Identifier for this resource.                                    |
| href     | Relative link to this resource. `null` for a directory without an index. |
| active   | Is this resource the current one? `true` or `false`.             |
| parent   | `nav` object representing this resource's parent. `null` for the root resource. |
| children | Array of `nav` objects representing this resource's children. Empty when this resource isn't a directory. |
| siblings | Array of `nav` objects representing this resource's parent's children. Includes this resource. |
| root     | `nav` object representing the ancestor of all streamed resources. |

There are a bunch of options we can pass into the plugin (in an object), which
are currently undocumented because they have sensible defaults and they might
change. If you want to know all about the options then [read the
source](gulp-nav.coffee#L27-L35).

One current default is to expose the nav data at both the `nav` and `data.nav`
(the latter for use with the new ["data
API"](https://github.com/colynb/gulp-data#note-to-gulp-plugin-authors))
properties of the [vinyl file
object](https://github.com/wearefractal/vinyl#file), although either or both of
these may be overridden via the `targets` option.
