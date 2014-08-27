# copyright (c) 2014 Jess Austin <jess.austin@gmail.com>, MIT license

gulp    = require 'gulp'
coffee  = require 'gulp-coffee'
data    = require 'gulp-data'
jade    = require 'gulp-jade'
filter  = require 'gulp-filter'
spy     = require 'through2-spy'
  .obj
test    = require 'tape'
connect = require 'gulp-connect'

gulp.task 'coffee', ->
  gulp.src ['*.coffee', '!gulpfile.coffee']
    .pipe coffee bare: true
    .pipe gulp.dest '.'

processJade = ->                                                          # DRY
  nav  = require './gulp-nav' # convenient during development to wait until now
  gulp.src 'test/**/*.jade'
    .pipe data (file) ->
      for line in (
           file.contents.toString().match /(?:^|\n) *- *(var [^\n]*)(?:$|\n)/g)
        # instead of this eval stuff you might want to use something like
        # gulp-frontmatter
        eval line.replace /(?:\n|^) *-? */g, ''
      title: title
      order: order
    .pipe nav()
    .pipe jade pretty: true

gulp.task 'build', ['coffee'], ->
  processJade()
    .pipe gulp.dest 'test/dist'

gulp.task 'test', ['coffee'], ->
  processJade()
    .pipe filter 'latin/b.html'
    .pipe spy (file) ->
      console.log file.nav.title
      console.log file.nav.href
      console.log file.nav.parent
      console.log file.nav.siblings
      console.log file.nav.children
      console.log file.nav.root
      test (tape) ->
        tape.plan 1
        tape.equal 0, 0

gulp.task 'default', ['build'], ->
  connect.server root: 'test/dist'
