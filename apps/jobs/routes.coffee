_ = require 'underscore'
JSONPage = require '../../components/json_page'
resizer = require '../../components/resizer'
page = new JSONPage name: 'jobs'

@index = (req, res, next) ->
  page.get (err, data) ->
    return next err if err
    page.data.categories = _.groupBy page.data.jobs, 'category'
    res.render 'index', _.extend {}, page.data, resizer