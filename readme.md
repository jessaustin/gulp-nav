gulp-nav
========

[![Build Status](https://travis-ci.org/jessaustin/gulp-nav.svg?branch=master)](https://travis-ci.org/jessaustin/gulp-nav "Travis")
[![Dependency Status](https://david-dm.org/jessaustin/gulp-nav.svg)](https://david-dm.org/jessaustin/gulp-nav "David")
[![devDependency Status](https://david-dm.org/jessaustin/gulp-nav/dev-status.svg)](https://david-dm.org/jessaustin/gulp-nav#info=devDependencies "David for dev dependencies")
[![NPM](https://nodei.co/npm/gulp-nav.png)](https://nodei.co/npm/gulp-nav/ "npmjs")

A [gulp](https://github.com/gulpjs/gulp) plugin to help build navigation or
breadcrumb elements implicitly from the file structure of your package. The
goal is to be useful with e.g. [Bootstrap .nav
classes](http://getbootstrap.com/components/#nav), and your favorite templating
system. (I like [Jade](http://jade-lang.com/)!) This plugin is inspired by the
very nice [gulp-filetree](https://github.com/0x01/gulp-filetree) package. (I
actually had a few sites with something cobbled together with gulp-filetree
before I decided to make gulp-nav.)

Imagine you have some source files in a directory hierarchy:
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
You know how to `gulp.pipe` these through appropriate plugins and transforms,
leaving you with a bunch of output pages in a similar directory hierarchy. What
about links between those pages, however? You don't want to hardcode that
stuff. It might be really useful if, while each file was being piped through
some plugin, that plugin had access to an object that told it where other files
were located and what they were called. With that information, a template could
be written to build navbars, breadcrumbs, or whatever you want on your
generated page. If this sounds good to you, you're in the right place.

If we had this in our ([coffeescript](http://coffeescript.org/)) gulpfile...

```coffeescript
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
...and a [really simple jade template like this](test/index.jade), that would
be enough to add robust navigation to the site, [like
this](http://jessaustin.github.io/gulp-nav/).

There are a bunch of options you can pass into the plugin in an object, which
are currently undocumented because they have sensible defaults and they might
change. If you want to know all about the options then [read the
source](gulp-nav.coffee#L27-L35).

One current default is to expose the nav data at both the `nav` and `data.nav`
(the latter for use with the new ["data
API"](https://github.com/colynb/gulp-data#note-to-gulp-plugin-authors))
properties of the vinyl file object, although either or both of these may be
overridden via the `target` option.
