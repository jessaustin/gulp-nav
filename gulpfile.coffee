# copyright (c) 2014 Jess Austin <jess.austin@gmail.com>, MIT license

gulp    = require 'gulp'
coffee  = require 'gulp-coffee'
data    = require 'gulp-data'
jade    = require 'gulp-jade'
connect = require 'gulp-connect'

gulp.task 'coffee', ->
  gulp.src ['*.coffee', '!gulpfile.coffee']
    .pipe coffee()
    .pipe gulp.dest '.'

gulp.task 'build', ['coffee'], ->
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
    .pipe gulp.dest 'test/dist'

gulp.task 'default', ['build'], ->
  connect.server root: 'test/dist'
