Q = require 'bluebird-q'
_ = require 'underscore'
benv = require 'benv'
sinon = require 'sinon'
Backbone = require 'backbone'
Article = require '../../../models/article'
Articles = require '../../../collections/articles'
CurrentUser = require '../../../models/current_user'
fixtures = require '../../../test/helpers/fixtures.coffee'
sd = require('sharify').data
{ resolve } = require 'path'
{ fabricate } = require 'antigravity'
{ stubChildClasses } = require '../../../test/helpers/stubs'

describe 'ArticleView', ->

  before (done) ->
    benv.setup =>
      benv.expose $: benv.require 'jquery'
      $.fn.imagesLoaded = sinon.stub()
      $.fn.waypoint = sinon.stub()
      $.fn.fillwidthLite = sinon.stub().yieldsTo('done')
      Backbone.$ = $
      sd.SCROLL_ARTICLE = 'static'
      @ArticleView = benv.requireWithJadeify(
        resolve(__dirname, '../client/view')
        ['editTemplate', 'calloutTemplate' ]
      )
      @ArticleView.__set__ 'imagesLoaded', sinon.stub()
      @ArticleView.__set__ 'Sticky', -> { add: sinon.stub() }
      @ArticleView.__set__ 'CurrentUser', fabricate 'user'
      @fillwidth = sinon.spy(@ArticleView::fillwidth)
      stubChildClasses @ArticleView, this,
        ['initCarousel']
        []
      benv.render resolve(__dirname, '../templates/index.jade'), @locals = {
        footerArticles: new Backbone.Collection
        slideshowArtworks: null
        article: @article = new Article _.extend fixtures.article,
          author_id: '4d8cd73191a5c50ce210002a'
          sections: [
            { type: 'text', body: '<p><a class="is-follow-link">Damon Zucconi</a><a class="artist-follow" data-id="damon-zucconi"></a></p>' }
            {
              type: 'artworks',
              ids: ['5321b73dc9dc2458c4000196', '5321b71c275b24bcaa0001a5'],
              layout: 'overflow_fillwidth',
              artworks: [
                {
                  type: 'artwork'
                  id: '5321b73dc9dc2458c4000196'
                  slug: "govinda-sah-azad-in-between-1",
                  date: "2015",
                  title: "In Between",
                  image: "https://d32dm0rphc51dk.cloudfront.net/zjr8iMxGUQAVU83wi_oXaQ/larger.jpg",
                  partner: {
                    name: "October Gallery",
                    slug: "october-gallery"
                  },
                  artist: {
                    name: "Govinda Sah 'Azad'",
                    slug: "govinda-sah-azad"
                  }
                },{
                  type: 'artwork'
                  id: '5321b71c275b24bcaa0001a5'
                  slug: "govinda-sah-azad-in-between-2",
                  date: "2015",
                  title: "In Between 2",
                  image: "https://d32dm0rphc51dk.cloudfront.net/zjr8iMxGUQAVU83wi_oXaQ2/larger.jpg",
                  partner: {
                    name: "October Gallery",
                    slug: "october-gallery"
                  },
                  artist: {
                    name: "Govinda Sah 'Azad'",
                    slug: "govinda-sah-azad"
                  }
                }
              ]
            }
            {
              type: 'embed',
              layout: 'overflow',
              url: 'http://files.artsy.net/data.pdf',
              height: ''
            }
            {
              type: 'callout',
              article: '123',
              text: '',
              title: ''
              hide_image: false
            }
          ]
        author: new Backbone.Model fabricate 'user'
        sd:
          SCROLL_ARTICLE: 'static'
        asset: (->)
        embed: require('particle')
        moment: require('moment')
        resize: sinon.stub()
      }, =>
        done()

  after ->
    benv.teardown()

  beforeEach ->
    sinon.stub Backbone, 'sync'
    sinon.stub($, 'get').returns { html: '<iframe>Test</iframe>' }
    sinon.stub @ArticleView.prototype, 'initialize'
    @view = new @ArticleView
    @view.setElement $('body')
    @view.article = @article

  afterEach ->
    Backbone.sync.restore()
    $.get.restore()
    @ArticleView.prototype.initialize.restore()

  describe '#renderSlideshow', ->

    it 'renders the slideshow', ->
      @view.renderSlideshow()
      @initCarousel.called.should.be.ok()

  describe '#resizeArtworks', ->

    it 'fillwidth is called on each artwork section', ->
      @view.resizeArtworks()
      _.defer =>
        @fillwidth.callCount.should.equal 1

  describe '#checkEditable', ->

    it 'shows the edit button when the author_id matches user and the user has \
        partner access', ->
      @view.user = _.extend( fabricate('user') , { 'id' : '4d8cd73191a5c50ce210002a', has_partner_access: true } )
      @view.checkEditable()
      @view.renderedEditButton.should.be.ok()

  describe '#renderCalloutSections', ->

    it 'renders callout content from the article', ->
      Backbone.sync.restore()
      sinon.stub Backbone, 'sync'
      Backbone.sync
        .onCall 0
        .yieldsTo 'success', article = fabricate 'article', { thumbnail_title: 'Callout title', id: '123'}
        .returns Q.resolve(article)
      @view.renderCalloutSections()
      _.defer =>
        @view.$('.article-section-callout-container').html().should.containEql 'Callout title'

  describe '#setupFollowButtons', ->

    it 'sets the list of artists in an article with ids', ->
      @view.setupFollowButtons()
      @view.artists[0].id.should.equal 'damon-zucconi'
