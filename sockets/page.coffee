#
# socket.ioを利用したデータ読み書き (サーバ側)
#

debug    = require('debug')('gyazz:sockets:page')
mongoose = require 'mongoose'
async    = require 'async'

Page  = mongoose.model 'Page'
Line  = mongoose.model 'Line'
Pair  = mongoose.model 'Pair'

module.exports = (app) ->
  io = app.get 'socket.io'

  io.on 'connection', (socket) ->
    debug "socket.io connected from client"

    wiki  = decodeURIComponent socket.handshake.query.wiki
    title = decodeURIComponent socket.handshake.query.title
    unless wiki and title
      socket.disconnect()
      return

    ## 同じページを見ているクライアント毎にroomで分ける
    room = "#{wiki}/#{title}"
    socket.join room
    socket.once 'disconnect', ->
      socket.leave room

    socket.on 'read', (req) ->
      debug "#{wiki}::#{title} read request from client"
      Page.findByName wiki, title, req.opts, (err, page) ->
        debug "findByName callback"
        if err
          debug "Page error"
          return
        data = page?.text.split(/\n/) or []
        # 行ごとの古さを計算する
        Line.timestamps wiki, title, data, (err, timestamps) ->
          debug "send data back to client"
          socket.emit 'pagedata', { # 自分だけに返信
            date:        page?.timestamp
            timestamps:  timestamps
            data:        data
          }

    # write処理時にリンク情報を更新する必要あり
    # データはgyazz_related.coffeeで使っている
    # pair.coffee でDBから取得している
    #
    socket.on 'write', (req) ->
      debug "#{wiki}::#{title} write request from client"
      text     = req.data
      keywords = req.keywords

      # 同じページを見ている自分以外の相手に送信
      socket.broadcast.to(room).emit 'pagedata', {
        date: Date.now()
        data: text?.split(/[\r\n]+/) or []
      }

      # 書き込んできたクライアントに完了通知
      socket.emit 'after write', null

      Page.saveNewPage wiki, title, text, (err) ->
        if err
          debug "save error: #{err}"
          socket.emit 'after write', err
          return
        debug "#{wiki}::#{title} page saved"

        Pair.refresh wiki, title, keywords # リンク情報登録

        # 行の生成時刻を記録する
        async.eachSeries text.split(/[\r\n]+/), (line, next) ->
          Line.saveIfNewLine wiki, title, line, (err) ->
            next()
        , (errs) ->
          debug "line timestamps saved"
