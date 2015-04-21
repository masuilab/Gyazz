debug = require('debug')('gyazz:controller:api')
mongoose = require 'mongoose'
_        = require 'underscore'
async    = require 'async'
PNG      = require '../lib/png'

Page  = mongoose.model 'Page'
Pair  = mongoose.model 'Pair'
Attr  = mongoose.model 'Attr'
Access = mongoose.model 'Access'
Line  = mongoose.model 'Line'

module.exports = (app) ->

  # 代表アイコン画像
  app.get /^\/([^\/]+)\/(.*)\/icon$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    debug "Getting #{wiki}/#{title}/icon"
    Attr.attr wiki, title, (err, result) ->
      if err
        return res.status(500).send
          error: 'icon: An error has occurred (err)'
      image = result.repimage
      if image
        if /^https?:\/\/.+\.(png|jpe?g|gif)$/i.test image
          return res.redirect image
        if /^[a-z0-9]+\.(jpe?g|gif|png)$/.test image
          return res.redirect "/upload/#{image}"
        else
          return res.redirect "//gyazo.com/#{image}.png"
      else
        return res.status(404).send "image not found"

  #  PageList API
  app.get '/:wiki/__list', (req, res) ->
    wiki = req.params.wiki
    Page.alist wiki, (err, list) ->
      if err
        debug "pagelist get error: #{err}"
        res.status(500).send err
        return

      res.send
        data:        list

  #  ページ内容取得 (apiとしてだけ)用意
  app.get /^\/([^\/]+)\/(.*)\/json$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    debug "Getting #{wiki}/#{title}/json"
    debug JSON.stringify req.query # { suggest, version, age }
    Page.findByName wiki, title, req.query, (err, page) ->
      if err
        return res.send
          error: 'An error has occurred'
      data =  page?.text.split(/\n/) or []
      # 行ごとの古さを計算する
      Line.timestamps wiki, title, data, (err, timestamps) ->
        # データ返信
        res.send
          date:        page?.timestamp
          timestamps:  timestamps
          data:        data


  # 関連ページの配列 repimageも一緒に返す
  app.get /^\/([^\/]+)\/(.*)\/related$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    if !Page.isValidName(wiki) or !Page.isValidName(title)
      return res.status(400).send
        error: "Invalid name"
    debug 'Getting wiki/title/related2'
    Pair.related wiki, title, (err, titles) ->
      debug "Getting related info===="
      if err
        return res.send
          error: err

      async.mapSeries titles, (title, next) ->
        Attr.attr wiki, title, (err, attr) ->
          if err or !attr
            next()
            return
          next null, {
            title: title
            repimage: attr.repimage
          }
      , (err, results) ->
        if err
          return res.status(500).send
            error: 'server error'
        results = _.filter results, (i) -> i
        debug "#{results.length} related pages found"
        return res.send results

  # ページ変更履歴とアクセス履歴からPNGを生成する
  app.get /^\/([^\/]+)\/(.*)\/modify.png$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    debug "modify: wiki = #{wiki}, title=#{title}"

    Page.access wiki, title, (err, data) ->
      png = new PNG
      png.png data, (pngres) ->
        res.set('Content-Type', 'image/png')
        res.send pngres


  # repimageなどのページ属性
  app.get /^\/([^\/]+)\/(.*)\/attr$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    if !Page.isValidName(wiki) or !Page.isValidName(title)
      return res.status(400).send
        error: "Invalid name"
    Attr.attr wiki, title, (err, result) ->
      debug "Getting related info===="
      if err
        return res.send
          error: err
      res.send result

  writetime = {}

  # データ書込み (apiとしてだけ用意)
  app.post '/__write', (req, res) ->
    debug "__write: "
    wiki  = req.body.name
    title = req.body.title
    text  = req.body.data
    writedata wiki, title, text, res

  app.get '/__write', (req, res) ->
    debug "__write: "
    wiki  = req.query.name
    title = req.query.title
    text  = req.query.data
    writedata wiki, title, text, res

  writedata = (wiki, title, text, res) ->
    if !Page.isValidName(wiki) or !Page.isValidName(title)
      res.status(400).end "Invalid name - wiki:#{wiki}, title:#{title}"
      return
    curtime = new Date
    lasttime = writetime["#{wiki}::#{title}"]
    if !lasttime || curtime > lasttime
      writetime["#{wiki}::#{title}"] = curtime
      page = new Page
      page.wiki      = wiki
      page.title     = title
      page.text      = text
      page.timestamp = curtime
      page.save (err) ->
        if err
          debug "Write error: #{err}"
          res.status(500).end err
          return
        res.send "noconflict"
        text.split(/\n/).forEach (line) -> # 新しい行ならば生成時刻を記録する
          Line.find
            wiki:  wiki
            title: title
            line:  line
          .exec (err, results) ->
            if err
              debug "line read error"
              return
            if results.length == 0
              line = new Line
              line.wiki      = wiki
              line.title     = title
              line.line      = line
              line.timestamp = curtime
              line.save (err) ->
                if err
                  debug "line write error"

  # ファイルアップロード
  fs = require 'fs'
  crypto = require 'crypto'
  app.post '/__upload', (req, res) ->
    uploadfile = req.files.uploadfile
    if !uploadfile
      res.status(400).end "Upload fail"
      return
    uploaded_path = uploadfile.path # MD5みたいなパスになる
    debug "upload #{uploaded_path}"
    fs.readFile uploaded_path, (err, data) ->
      if err
        res.status(400).end "Upload fail"
        return
      md5 = crypto.createHash 'md5'
      md5.update data # , 'utf8'
      hash = md5.digest 'hex'
      ext = uploaded_path.match(/\.\w+$/)?[0]
      ext = "" unless ext
      new_path = uploaded_path.replace /[0-9a-f]{32}/, hash
      fs.rename uploaded_path, new_path, (err) ->
        #if err
        #  res.status(400).end "Rename fail"
        #  return
        res.send "#{hash}#{ext}"

