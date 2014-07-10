#
# ExpressによるGyazzサーバのメインプログラム
#

express  = require 'express'
mongoose = require 'mongoose'
path     = require 'path'
debug    = require('debug')('gyazz:app')


## Config
process.env.PORT ||= 3000


module.exports = app = express()

# public以下のファイルはWikiデータとみなさないようにする
app.use express.static path.resolve 'public'
# app.set 'view engine', 'ejs'
app.set 'view engine', 'jade'
app.locals.pretty = true       # jade出力を整形する

## load controllers, models, socket.io ##
components =
  models:      [ 'pair', 'page', 'attr' ]
  controllers: [ 'main' ]
  sockets:     [ ]

for type, items of components
  for item in items
    debug "load #{type}/#{item}"
    require(path.resolve type, item)(app)

mongodb_uri = process.env.MONGOLAB_URI or
              process.env.MONGOHQ_URL or
              'mongodb://localhost/gyazz'

mongoose.connect mongodb_uri, (err) ->
  if err
    debug "mongoose connect failed"
    debug err
    process.exit 1
    return
  debug "connect MongoDB"

  app.listen process.env.PORT
  console.log "Listening on port #{process.env.PORT}..."
