#
# About page requires different enough functionality from page app
#

express = require 'express'
routes = require './routes'

app = module.exports = express()
app.set 'views', __dirname + '/templates'
app.set 'view engine', 'jade'

app.get '/about2', routes.index
# Safely init upload routes for missing S3 env vars (like in test)
try
  routes.initClient()
  app.all '/about2*', routes.adminOnly
  app.get '/about2/edit', routes.edit
  app.post '/about2/edit', routes.upload