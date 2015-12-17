#
# リンク情報
#

debug    = require('debug')('gyazz:pair')
_        = require 'lodash'
mongoose = require 'mongoose'

module.exports = (app) ->

  pairSchema = new mongoose.Schema
    wiki:
      type: String
      validate: [
        (v) ->
          return mongoose.model('Page').isValidName(v)
        'Invalid WiKi name'
      ]
    title1:
      type: String
      validate: [
        (v) ->
          return mongoose.model('Page').isValidName(v)
        'Invalid WiKi name'
      ]
    title2:
      type: String
      validate: [
        (v) ->
          return mongoose.model('Page').isValidName(v)
        'Invalid WiKi name'
      ]

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
        
        callback e, _.keys(related)

  pairSchema.statics.refresh = (wiki, title, relatedtitles) ->
    # console.log "remove #{wiki}, #{title}, related = #{relatedtitles}"
    @find {wiki:wiki, title1:title}, (err, results) =>
      removeentries = results.map (result) -> result.title2
      # console.log "removeentries = #{removeentries}----"
      removeentries = removeentries.filter (e) ->
        ! (e in relatedtitles)
      removeentries.forEach (e) =>
        @find {wiki:wiki, title1:title, title2:e}, (err, results) ->
          results.forEach (result) =>
            # console.log "========removing unused entry #{title}, #{e}"
            result.remove (err) ->
              console.log "remove fail" if err
    relatedtitles.forEach (relatedtitle) =>
      pair = new @
      pair.wiki =   wiki
      pair.title1 = title
      pair.title2 = relatedtitle
      # console.log "wiki=#{wiki}, title1=#{title}, reelatedtitle=#{relatedtitle}"
      @find {wiki:wiki, title1:title, title2:relatedtitle}, (err, results) ->
        if results[0]
          result = results[0]
          # console.log "result = #{result}"
          # console.log "========removing entry #{relatedtitle}, #{title} for update"
          result.remove (err) ->
            if (err)
              console.log "result.remove error"
            pair.save (err) ->
              if err
                console.log "Pair SAVE error"
              #else
              #  console.log "UPDATE SUCCESS"
        else
          pair.save (err) ->
            if err
              console.log "Pair update error"
            #else
            #  console.log "UPDATE SUCCESS"

  mongoose.model 'Pair', pairSchema
