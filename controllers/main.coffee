#
# メインコントローラモジュール
#

path     = require 'path'
debug    = require('debug')('gyazz:controller:main')
mongoose = require 'mongoose'
RSS      = require 'rss'

GyazzMarkup = require path.resolve 'lib/markup'

Page  = mongoose.model 'Page'
Pair  = mongoose.model 'Pair'
Attr  = mongoose.model 'Attr'
Access = mongoose.model 'Access'
Line  = mongoose.model 'Line'

module.exports = (app) ->

  app.get '/', (req, res) ->
    return res.render 'index',
      title: 'Gyazz'


  # 右上検索boxからの検索画面
  app.get '/:wiki/__search', (req, res) ->
    wiki = req.params.wiki
    query = req.query.q
    if query == ''
      res.redirect "/#{wiki}"
    else
      Page.search wiki, query, (err, list) ->
        if err
          return res.end err
        res.render 'search',
          wiki:  wiki
          q:     query
          pages: list


  # テキストエリアでのページ全行編集画面
  app.get /^\/([^\/]+)\/(.*)\/__edit$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    return res.render 'edit',
      title:   title
      wiki:    wiki
      version: req.query.version


  # ランダムにページを表示
  app.get /^\/([^\/]+)\/__random$/, (req, res) ->
    # 認証必要
    wiki  = req.params[0]
    Page.alist wiki, (err, list) ->
      if err
        res.redirect "/#{wiki}"
        return
      len = list.length
      if len == 0
        res.redirect "/#{wiki}"
        return
      ind = Math.floor(Math.random() * len)
      title = list[ind]._id
      Page.findByName wiki, title, {}, (err, page) ->
        if err
          debug "Page error"
          return
        rawdata =  page?.text or ""
        return res.render 'page',
          title:   title
          wiki:    wiki
          rawdata: rawdata


  # RSSを出力する
  app.get  /^\/([^\/]+)\/rss.xml$/, (req, res) ->
    wiki = req.params[0]
    if !Page.isValidName wiki
      return res.send 404

    # ドキュメントを取得
    Page.mlist wiki,{includeText:true},(err,docs)->
      if err
        debug "pagelist get error:#{err}"
        return res.status(500).send err

      # フィード作成
      subdomains = if req.subdomains.length > 0 then "#{req.subdomains.join('.')}." else ""
      site_url = "#{req.protocol}://#{subdomains}#{req.get "host"}"

      feed = new RSS
        title: "Gyazz::#{wiki}"
        feed_url: "#{site_url}/#{wiki}/rss.xml"
        site_url: site_url
        image_url: "#{site_url}/favicon.ico"
        docs: "http://github.com/masuilab/gyazz"
        webMaster: "https://gihub.com/masuilab/gyazz"
        copyright: "2014 "
        language: "ja"
        categories: []
        pubDate: docs[0]?.timestamp || new Date()

      # Limit
      docs = docs.slice(0,20) if docs.length > 20
      markup = new GyazzMarkup host: site_url, wiki: wiki

      for page in docs
        description = "<ul>"
        description += page.text
          .split /[\r\n]/
          .map (line) -> "<li>#{markup.markup line, escape: false}</li>"
          .join ''
        description += "</ul>"

        feed.item
          title: page._id
          description: description
          url: "#{site_url}/#{wiki}/#{page._id}"
          date: page.timestamp # any format that js Date can parse.
      res.set
        "Content-Type": "text/xml"
      res.send feed.xml()

  # 普通にページアクセス
  app.get /^\/([^\/]+)\/(.+)$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    if !Page.isValidName(title) or !Page.isValidName(wiki)
      title = Page.toValidName title
      wiki  = Page.toValidName wiki
      return res.redirect "/#{wiki}/#{title}"
    debug "Get: wiki = #{wiki}, title=#{title}"

    # アクセス記録
    new Access(wiki: wiki, title: title).save (err) ->
      if err
        debug "Access write error"

    # ページデータを読み込んでrawdataとする
    escape_regexp_token = (str) ->
      return str.replace /[\\\+\*\.\[\]\{\}\(\)\^\|]/g, (c) -> "\\#{c}"
    title_regexp =
      new RegExp "^#{escape_regexp_token title.replace(/\s/g,'').split('').join(' ?')}$", 'i'
    Page.findByName wiki, title_regexp, {}, (err, page) ->
      if err
        debug "Page error: #{err}"
        return res.status(500).end err
      if page? and title isnt page?.title and !page?.isEmpty()
        res.redirect "/#{page.wiki}/#{page.title}"
        return
      rawdata =  page?.text or ""
      return res.render 'page',
        title:   title
        wiki:    wiki
        rawdata: rawdata

  # ページリスト
  app.get '/:wiki/', (req, res) ->
    wiki = req.params.wiki
    Page.alist wiki, (err, list) ->
      if err
        debug "pagelist get error: #{err}"
        res.status(500).send err
        return
      args =
        wiki:  wiki
        q:     ""
        pages: list

      res.render 'search', args

