gulp-nav
========

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
You know how to `gulp.pipe` these through appropriate plugins and transforms, leaving you with a bunch of output pages in a similar directory hierarchy. What about links between those pages, however? You don't want to hardcode that stuff. It might be really useful if, while each file was being piped through some plugin, that plugin had access to an object that told it where other files were located and what they were called. With that information, a template could be written to build navbars, breadcrumbs, or whatever you want on your generated page. If this sounds good to you, you're in the right place.




to determine the
file structure of piped-in streams, and then it annotates each file in the
stream with its own particular nav information. Annotations are placed both at
`file.nav` and `file.data.nav` (for use with the new ["data
API"](https://github.com/colynb/gulp-data#note-to-gulp-plugin-authors)) file
properties, although either or both of these may be overridden via `options`.
