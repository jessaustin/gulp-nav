gulp-nav
========

A [gulp](https://github.com/gulpjs/gulp) plugin to help build navigation or
breadcrumb elements implicitly from the file structure of your package. The
goal is to be useful with e.g. [Bootstrap .nav
classes](http://getbootstrap.com/components/#nav), and your favorite templating
system. (I like [Jade](http://jade-lang.com/)!) This plugin relies on the very
nice [gulp-filetree](https://github.com/0x01/gulp-filetree) to determine the
file structure of piped-in streams, and then it annotates each file in the
stream with its own particular nav information. Annotations are placed both at
`file.nav` and `file.data.nav` (for use with the new ["data
API"](https://github.com/colynb/gulp-data#note-to-gulp-plugin-authors)) file
properties, although either or both of these may be overridden via `options`.
