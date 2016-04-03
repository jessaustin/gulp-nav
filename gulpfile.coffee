# copyright © 201{4,5,6} Jess Austin <jess.austin@gmail.com>, MIT license

gulp = require 'gulp'
matter = require 'jade-var-matter'
through = require 'through2'
test = require 'tape'
{connect, data, filter, jade, stream} = (require 'gulp-load-plugins')()

start = ->
  nav = require './gulp-nav'  # convenient during development to wait until now
  gulp.src 'test/**/*.jade'
    .pipe data ({ contents }) ->
      matter String contents
    .pipe nav orders: ['order', 'ord']

gulp.task 'build', ->
  start()
    .pipe jade pretty: true
    .pipe gulp.dest 'test/dist'

gulp.task 'default', ['build'], ->
  connect.server root: 'test/dist'

gulp.task 'test', ->
  runTest 'Buffer', start()
  runTest 'Stream', start().pipe stream()

runTest = (label, src) ->
  src.pipe filter '*/latin/b.jade'
    .pipe through.obj ({ nav }) ->
      titleMsg = 'Nav should have this title.'
      hrefMsg = 'Nav should have this href.'
      activeMsg = 'Nav should be active.'
      notActiveMsg = 'Nav shouldn\'t be active.'
      test "Self-#{label}", (assert) ->
        assert.is nav.title, 'B', titleMsg
        assert.is nav.href, 'b.html', hrefMsg
        assert.ok nav.active, activeMsg
        assert.end()
      test "Parent-#{label}", (assert) ->
        assert.is nav.parent.title, 'Latin', titleMsg
        assert.is nav.parent.href, '.', hrefMsg
        assert.notOk nav.parent.active, notActiveMsg
        assert.is nav.root.href, nav.parent.root.href, hrefMsg
        assert.end()
      test "Grandparent-#{label}", (assert) ->
        assert.is nav.parent.parent.title, 'Home', titleMsg
        assert.is nav.parent.parent.href, '..', hrefMsg
        assert.notOk nav.parent.parent.active, notActiveMsg
        assert.is nav.root.href, nav.parent.parent.root.href, hrefMsg
        assert.end()
      test "Siblings-#{label}", (assert) ->
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
          current = nav.siblings[i]
          assert.is current.title, item.title, titleMsg
          assert.is current.href, item.href, hrefMsg
          assert.is current.active, item.active,
            if item.active then activeMsg else notActiveMsg
          assert.is nav.root.href, current.root.href, hrefMsg
        assert.end()
      test "Children-#{label}", (assert) ->
        assert.notOk nav.children.length, 'Nav should have no children.'
        assert.end()
      test "Root-#{label}", (assert) ->
        assert.plan 4     # don't know why, but otherwise tests exit w/o ending
        assert.is nav.root.title, 'Home', titleMsg
        assert.is nav.root.href, '..', hrefMsg
        assert.is nav.root.href, nav.root.root.href, hrefMsg
        assert.notOk nav.root.active, notActiveMsg
      test "No-Index", (assert) ->
        for uncle in nav.parent.siblings
          if uncle.title is 'Greek'
            assert.notOk uncle.href?, "Nav without index shouldn't have href"
        assert.end()
