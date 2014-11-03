class GyazzSocket

  init: (gb, gd, gt) ->
    query = $.param
      wiki:  wiki
      title: title
    @socket = io.connect "#{location.protocol}//#{location.hostname}?#{query}"
    @gb = gb
    @gd = gd
    @gt = gt

    @socket.on 'pagedata', (res) =>
      _data_old =   res['data'].concat()
      @gb.data    = res.data.concat()
      @gb.datestr = res.date
      @gb.timestamps = res.timestamps or []
      @gb.refresh()

    @socket.on 'after write', (err) =>
      if err
        notifyBox.print(err).show(3000)
        return
      notifyBox.show(1)

  getdata: (opts = {}, callback = ->) =>
    opts = {} if typeof opts isnt 'object'
    if typeof opts.version != 'number' || 0 > opts.version
      opts.version = 0
    @socket.emit 'read',
      opts:  opts

  _oldstr = ""
  writedata: (data) ->
    datastr = data.join("\n").replace(/\n+$/,'')+"\n"
    if datastr == _oldstr
      return
    _oldstr = datastr
    notifyBox.print("saving..", {progress: true}).show()
    keywords = _.flatten data.map (line) =>
      @gt.keywords(line, wiki, title, 0)
    @socket.emit 'write',
      data:     datastr
      keywords: keywords

window.GyazzSocket = GyazzSocket
