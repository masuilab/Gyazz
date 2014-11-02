socket = io.connect "#{location.protocol}//#{location.hostname}?wiki=#{encodeURIComponent wiki}&title=#{encodeURIComponent title}"
gt = new GyazzTag

getData = ->
  return $('#contents').val().trim() + "\n"

$ ->
  opts = {version: version}

  socket.on 'pagedata', (res) =>
    $('#contents').val res.data.join("\n")

  socket.on 'connect', ->
    socket.emit 'read',
      opts:  opts

  send_timeout = null
  last_data = ""
  socket.once 'pagedata', ->
    last_data = getData()
    $(document).keyup (e) ->
      data = getData()
      if last_data is data
        return

      last_data = data
      clearTimeout send_timeout
      send_timeout = setTimeout ->
        keywords = _.flatten data.split(/\n/).map (line) ->
          gt.keywords(line, wiki, title, 0)
        socket.emit 'write',
          data:     data
          keywords: keywords
        $("#contents").css('background-color','#ffffff')
      , 3000

      $("#contents").css('background-color','#e0e0e0')
