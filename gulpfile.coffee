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

gulp.task 'default', ['build'], ->
  connect.server root: 'test/dist'

gulp.task 'test', ['coffee'], ->
  processJade()
    .pipe filter 'latin/b.html'
    .pipe spy (file) ->
      titleMsg = 'Nav should have this title.'
      hrefMsg = 'Nav should have this href.'
      activeMsg = 'Nav should be active.'
      notActiveMsg = 'Nav shouldn\'t be active.'
      Msg = ''
      test 'Self', (tape) ->
        tape.is file.nav.title, 'B', titleMsg
        tape.is file.nav.href, 'b.html', hrefMsg
        tape.ok file.nav.active, activeMsg
        tape.end()
      test 'Parent', (tape) ->
        tape.is file.nav.parent.title, 'Latin', titleMsg
        tape.is file.nav.parent.href, '.', hrefMsg
        tape.notOk file.nav.parent.active, notActiveMsg
        tape.end()
      test 'Grandparent', (tape) ->
        tape.is file.nav.parent.parent.title, 'Home', titleMsg
        tape.is file.nav.parent.parent.href, '..', hrefMsg
        tape.notOk file.nav.root.active, notActiveMsg
        tape.end()
      test 'Siblings', (tape) ->
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
          tape.is current.title, item.title, titleMsg
          tape.is current.href, item.href, hrefMsg
          tape.is current.active, item.active, if item.active then activeMsg else notActiveMsg
        tape.end()
      test 'Children', (tape) ->
        tape.notOk file.nav.children.length, 'Nav should have no children.'
        tape.end()
      test 'Root', (tape) ->
        tape.is file.nav.root.title, 'Home', titleMsg
        tape.is file.nav.root.href, '..', hrefMsg
        tape.notOk file.nav.root.active, notActiveMsg
        tape.end()
