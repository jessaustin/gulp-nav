# copyright (c) 201{4,5} Jess Austin <jess.austin@gmail.com>, MIT license

gulp = require 'gulp'
matter = require 'jade-var-matter'
through = require 'through2'
test = require 'tape'
{connect, data, filter, jade, stream} = (require 'gulp-load-plugins')()

processBegin = ->
  nav = require './gulp-nav'  # convenient during development to wait until now
  gulp.src 'test/**/*.jade'
    .pipe data (file) ->
      matter String file.contents
    .pipe nav()

gulp.task 'build', ->
  processBegin()
    .pipe jade pretty: true
    .pipe gulp.dest 'test/dist'

gulp.task 'default', ['build'], ->
  connect.server root: 'test/dist'

gulp.task 'test', ->
  runTest 'Buffer', processBegin()
  runTest 'Stream', processBegin().pipe stream()

runTest = (label, src) ->
  src.pipe filter '*/latin/b.jade'
    .pipe through.obj (file) ->
      titleMsg = 'Nav should have this title.'
      hrefMsg = 'Nav should have this href.'
      activeMsg = 'Nav should be active.'
      notActiveMsg = 'Nav shouldn\'t be active.'

      test "Self-#{label}", (assert) ->
        assert.plan 3
        assert.is file.nav.title, 'B', titleMsg
        assert.is file.nav.href, 'b.html', hrefMsg
        assert.ok file.nav.active, activeMsg
      test "Parent-#{label}", (assert) ->
        assert.plan 3
        assert.is file.nav.parent.title, 'Latin', titleMsg
        assert.is file.nav.parent.href, '.', hrefMsg
        assert.notOk file.nav.parent.active, notActiveMsg
      test "Grandparent-#{label}", (assert) ->
        assert.plan 3
        assert.is file.nav.parent.parent.title, 'Home', titleMsg
        assert.is file.nav.parent.parent.href, '..', hrefMsg
        assert.notOk file.nav.root.active, notActiveMsg
      test "Siblings-#{label}", (assert) ->
        assert.plan 9
        for item, i in [
          title: 'A'
          href: 'letter-a.html'
          active: no
        ,
          title: 'B'
          href: 'b.html'
          active: yes
        ,
          title: 'C'
          href: 'c.html'
          active: no
        ]
          current = file.nav.siblings[i]
          assert.is current.title, item.title, titleMsg
          assert.is current.href, item.href, hrefMsg
          assert.is current.active, item.active,
            if item.active then activeMsg else notActiveMsg
      test "Children-#{label}", (assert) ->
        assert.plan 1
        assert.notOk file.nav.children.length, 'Nav should have no children.'
      test "Root-#{label}", (assert) ->
        assert.plan 3
        assert.is file.nav.root.title, 'Home', titleMsg
        assert.is file.nav.root.href, '..', hrefMsg
        assert.notOk file.nav.root.active, notActiveMsg
