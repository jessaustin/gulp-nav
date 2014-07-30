# copyright 2014 Jess Austin, all rights reserved

gulp = require 'gulp'
jade = require 'gulp-jade'
map = require 'map-stream'
coffee = require 'gulp-coffee'

gulp.task 'coffee', ->
  gulp.src '../gulp-nav.coffee'
    .pipe coffee()
    .pipe gulp.dest '..'

gulp.task 'default', ['coffee'], ->
  nav  = require '..'
  gulp.src '**/*.jade'
    .pipe nav()
      # read the short_title and order vars from jade file
#       vars = /(?:^|\n) *- *(var [^\n]*)(?:$|\n)/.exec file.contents.toString()
#       eval vars[1]
    .pipe map (file, callback) ->
      console.log file.tree
      callback null, file
    .pipe jade pretty: true
    .pipe gulp.dest 'dist'
