benv = require 'benv'
Backbone = require 'backbone'
sinon = require 'sinon'
{ resolve } = require 'path'
sd = require('sharify').data
{ fabricate } = require 'antigravity'

describe 'Layout init code', ->

  beforeEach (done) ->
    benv.setup =>
      benv.expose { $: require('jquery')(window) }
      sinon.stub $, 'ajax'
      { @syncAuth } = require '../client'
      done()

  afterEach -> benv.teardown()

  it 'logs you out if Gravity throws an auth error', ->
    sd.CURRENT_USER = fabricate 'user'
    @syncAuth()
    $.ajax.args[0][0].url.should.include 'api/v1/me'
    $.ajax.args[0][0].error()
    window.location.should.equal '/force/users/sign_out'
    sd.CURRENT_USER = null