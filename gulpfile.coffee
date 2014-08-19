# copyright (c) 2014 Jess Austin <jess.austin@gmail.com>, MIT license

gulp    = require 'gulp'
coffee  = require 'gulp-coffee'
jade    = require 'gulp-jade'
connect = require 'gulp-connect'

gulp.task 'coffee', ->
  gulp.src ['*.coffee', '!gulpfile.coffee']
    .pipe coffee()
    .pipe gulp.dest '.'

gulp.task 'test', ['coffee'], ->
  42

gulp.task 'build', ['coffee'], ->
  nav  = require './gulp-nav' # convenient during development to wait until now
  gulp.src 'test/**/*.jade'
    .pipe nav()
    .pipe jade pretty: true
    .pipe gulp.dest 'example'

gulp.task 'default', ['build'], ->
  connect.server root: 'example'
