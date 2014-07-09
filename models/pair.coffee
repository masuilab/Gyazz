#
# リンク情報
#

debug    = require('debug')('gyazz:pair')
_        = require 'underscore'
mongoose = require 'mongoose'

module.exports = (app) ->

  pairSchema = new mongoose.Schema {
    wiki: String,
    title1: String,
    title2: String
  }, {
    collection: "Pairs" # Mongooseは勝手に小文字の複数形にするので大文字を使うときはこういう指定が必要
  }

  # pageに関連するページの配列を得る
  pairSchema.statics.related = (wiki, title, callback) ->
    debug "Pair.related"
    e = false
    related = {}
    @find {wiki:wiki, title1:title}, (err, results) =>
      e ||= err
      for pair in results
        related[pair.title2] = 1
      @find {wiki:wiki, title2:title}, (err, results) ->
        e ||= err
        for pair in results
          related[pair.title1] = 1
        
        debug _.keys(related)
        callback e, _.keys(related)


  mongoose.model 'Pair', pairSchema
