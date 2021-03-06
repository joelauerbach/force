_ = require 'underscore'
Q = require 'bluebird-q'
Backbone = require 'backbone'
{ fabricate } = require 'antigravity'
Article = require '../../models/article'
Articles = require '../../collections/articles'
sinon = require 'sinon'
fixtures = require '../helpers/fixtures'

describe "Article", ->
  beforeEach ->
    sinon.stub Backbone, 'sync'
      .returns Q.defer()
    @article = new Article

  afterEach ->
    Backbone.sync.restore()

  describe '#fetchWithRelated', ->
    it 'gets all the related data from the article', (done) ->
      @article.set sections: []

      Backbone.sync
        .onCall 0
        .yieldsTo 'success', _.extend {}, fixtures.article, title: 'Moo'
        .onCall 1
        .yieldsTo 'success', [fixtures.article]
        .onCall 2
        .yieldsTo 'success', [fixtures.article]

      @article.fetchWithRelated success: (data) ->
        data.article.get('title').should.equal 'Moo'
        done()

    it 'gets the slideshow artworks', (done) ->
      slideshowArticle = _.extend {}, fixtures.article,
        title: 'Moo'
        channel_id: null
        sections: [
          {
            type: 'slideshow'
            items: [
              {
                type: 'artwork', id: 'foo'
              }
            ]
          }
        ]

      Backbone.sync
        .onCall 0
        .yieldsTo 'success', slideshowArticle
        .onCall 1
        .yieldsTo 'success', [fixtures.article]
        .onCall 2
        .yieldsTo 'success', [fixtures.article]
        .onCall 3
        .yieldsTo 'success', fabricate 'artwork', title: 'foobar'
        .onCall 4
        .yieldsTo 'success', [fixtures.article]

      @article.fetchWithRelated success: (data) ->
        data.slideshowArtworks.first().get('title').should.equal 'foobar'
        done()

    it 'fetches section content if need be', (done) ->
      sectionArticle = _.extend {}, fixtures.article,
        title: 'Moo'
        section_ids: ['foo']
        sections: []
        channel_id: null

      Backbone.sync
        .onCall 0
        .yieldsTo 'success', sectionArticle
        .onCall 1
        .yieldsTo 'success', [fixtures.article]
        .onCall 2
        .yieldsTo 'success', [fixtures.article]
        .onCall 3
        .yieldsTo 'success', fixtures.section
        .onCall 4
        .yieldsTo 'success', [fixtures.articles]
        .onCall 5
        .yieldsTo 'success', [fixtures.articles]

      @article.fetchWithRelated success: (data) ->
        data.section.get('title').should.equal 'Vennice Biennalez'
        done()

    it 'works for those rare sectionless articles', (done) ->
      sectionlessArticle = _.extend {}, fixtures.article,
        title: 'Moo'
        sections: []
        channel_id: null

      Backbone.sync
        .onCall 0
        .yieldsTo 'success', sectionlessArticle
        .onCall 1
        .yieldsTo 'success', [fixtures.article]
        .onCall 2
        .yieldsTo 'success', [fixtures.article]

      @article.fetchWithRelated success: (data) ->
        data.article.get('title').should.equal 'Moo'
        done()

    it 'fetches related articles for super articles', (done) ->
      superArticle = _.extend {}, fixtures.article,
        title: 'SuperArticle',
        is_super_article: true
        sections: []
        channel_id: null
        super_article:
          related_articles: ['id-1']

      relatedArticle = _.extend {}, fixtures.article,
        title: 'RelatedArticle'
        id: 'id-1'

      Backbone.sync
        .onCall 0
        .yieldsTo 'success', superArticle
        .onCall 1
        .yieldsTo 'success', [fixtures.article]
        .onCall 2
        .yieldsTo 'success', [fixtures.article]
        .onCall 3
        .yieldsTo 'success', relatedArticle

      @article.fetchWithRelated success: (data) ->
        data.relatedArticles.models[0].get('title').should.equal 'RelatedArticle'
        data.article.get('title').should.equal 'SuperArticle'
        done()

    it 'fetches related articles for article in super article', (done) ->
      relatedArticle1 = _.extend {}, fixtures.article,
        id: 'id-1'
        title: 'RelatedArticle 1',
        sections: []
      relatedArticle2 = _.extend {}, fixtures.article,
        id: 'id-2'
        title: 'RelatedArticle 2',
        sections: []
      superArticle = _.extend {}, fixtures.article,
        id: 'id-3'
        title: 'SuperArticle',
        is_super_article: true
        sections: []
        channel_id: null
        super_article:
          related_articles: ['id-1', 'id-2']

      Backbone.sync
        .onCall 0
        .yieldsTo 'success', superArticle
        .onCall 1
        .yieldsTo 'success', [fixtures.article]
        .onCall 2
        .yieldsTo 'success', [fixtures.article]
        .onCall 3
        .yieldsTo 'success', relatedArticle1
        .onCall 4
        .yieldsTo 'success', relatedArticle2

      @article.fetchWithRelated success: (data) ->
        data.superArticle.get('title').should.equal 'SuperArticle'
        data.relatedArticles.first().get('title').should.equal 'RelatedArticle 1'
        data.relatedArticles.last().get('title').should.equal 'RelatedArticle 2'
        done()

  describe '#strip', ->
    it 'returns the attr without tags', ->
      @article.set 'lead_paragraph', '<p><br></p>'
      @article.strip('lead_paragraph').should.equal ''
      @article.set 'lead_paragraph', '<p>Existy</p>'
      @article.strip('lead_paragraph').should.equal 'Existy'

  describe '#prepForInstant', ->

    it 'returns the article with empty tags removed', ->
      @article.set 'sections', [
        { type: 'text', body: '<p>First Paragraph</p><p></p>' },
        { type: 'text', body: '<p>Second Paragraph</p><br>'}
      ]
      @article.prepForInstant()
      @article.get('sections')[0].body.should.equal '<p>First Paragraph</p>'
      @article.get('sections')[1].body.should.equal '<p>Second Paragraph</p>'

    it 'returns the article with captions p tags replaced by h1', ->
      @article.set 'sections', [
        { type: 'image', caption: '<p>First Paragraph</p>' },
        { type: 'image_set', images: [
          { type: 'image', caption: '<p>A place for credit</p>' }
        ]}
      ]
      @article.prepForInstant()
      @article.get('sections')[0].caption.should.equal '<h1>First Paragraph</h1>'
      @article.get('sections')[1].images[0].caption.should.equal '<h1>A place for credit</h1>'

  describe 'byline', ->

    it 'returns the author when there are no contributing authors', ->
      @article.set 'contributing_authors', []
      @article.set 'author', { name: 'Molly' }
      @article.byline().should.equal 'Molly'

    it 'returns the contributing author name if there is one', ->
      @article.set 'contributing_authors', [{name: 'Molly'}]
      @article.byline().should.equal 'Molly'

    it 'returns "and" with two contributing authors', ->
      @article.set 'contributing_authors', [{name: 'Molly'}, {name: 'Kana'}]
      @article.byline().should.equal 'Molly and Kana'

    it 'returns multiple contributing authors', ->
      @article.set 'contributing_authors', [{name: 'Molly'}, {name: 'Kana'}, {name: 'Christina'}]
      @article.byline().should.equal 'Molly, Kana and Christina'

  describe 'contributingByline', ->

    it 'returns an empty string when there are no contributing authors', ->
      @article.set 'contributing_authors', []
      @article.contributingByline().should.equal ''

    it 'returns the contributing author name if there is one', ->
      @article.set 'contributing_authors', [{name: 'Molly'}]
      @article.contributingByline().should.equal 'Molly'

    it 'returns "and" with two contributing authors', ->
      @article.set 'contributing_authors', [{name: 'Molly'}, {name: 'Kana'}]
      @article.contributingByline().should.equal 'Molly and Kana'

    it 'returns multiple contributing authors', ->
      @article.set 'contributing_authors', [{name: 'Molly'}, {name: 'Kana'}, {name: 'Christina'}]
      @article.contributingByline().should.equal 'Molly, Kana and Christina'

  describe 'getParselySection', ->

    it 'returns Editorial', ->
      @article.set 'channel', new Backbone.Model name: 'Artsy Editorial'
      @article.getParselySection().should.equal 'Editorial'

    it 'returns channel name', ->
      @article.set 'channel', new Backbone.Model name: 'Life at Artsy'
      @article.getParselySection().should.equal 'Life at Artsy'

    it 'returns Section', ->
      @article.set 'section', new Backbone.Model title: '56th Venice Biennale'
      @article.getParselySection().should.equal '56th Venice Biennale'

    it 'returns Partner', ->
      @article.set 'partner', new Backbone.Model
      @article.getParselySection().should.equal 'Partner'

    it 'returns Other', ->
      @article.clear()
      @article.getParselySection().should.equal 'Other'
