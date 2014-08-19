# copyright (c) 2014 Jess Austin <jess.austin@gmail.com>, MIT license

gulp = require 'gulp'
coffee = require 'gulp-coffee'
jade = require 'gulp-jade'
connect = require 'gulp-connect'

gulp.task 'coffee', ->
  gulp.src '../*.coffee'
    .pipe coffee()
    .pipe gulp.dest '..'

gulp.task 'test', ['coffee'], ->
  nav  = require '..' # more convenient during development
  42

gulp.task 'build', ['coffee'], ->
  nav  = require '..' # more convenient during development
  gulp.src '**/*.jade'
    .pipe nav()
    .pipe jade pretty: true
    .pipe gulp.dest 'dist'

gulp.task 'default', ['build'], ->
  connect.server root: 'dist'
