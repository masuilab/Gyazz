#
# ページ表示
#
class GyazzDisplay

  init: (tag) ->
    @tag = tag

  version: -1
  showold: false

  display: (gb, delay) ->
    # zoomlevelに応じてバックグラウンドの色を変える
    $("body").css 'background-color', switch gb.zoomlevel
      when 0  then "#eeeeff"
      when -1 then "#e0e0c0"
      when -2 then "#c0c0a0"
      else         "#a0a080"
    $('#datestr').text if @version >= 0 || @showold then gb.datestr else ''
    $('#title').attr
      href: "/#{wiki}/#{title}/__edit?version=#{ if @version >= 0 then @version else 0 }"

    if delay # ちょっと待ってもう一度呼び出す!
      setTimeout =>
        @display gb
      , 100
      return

    input = $("#editline")
    if gb.editline == -1
      gb.deleteblankdata()
      input.css 'display', 'none'

    contline = -1
    if gb.data.length == 0
      gb.data = ["(empty)"]
      gb.doi[0] = gb.maxindent()

    [0...gb.data.length].forEach (i) =>
      ind = gb.line_indent i
      xmargin = ind * 30

      t = $("#list#{i}")
      p = $("#listbg#{i}")
      if gb.doi[i] >= -gb.zoomlevel
        if i == gb.editline # 編集行
          t.css('display','inline').css('visibility','hidden')
          p.css('display','block').css('visibility','hidden')
          input.css('position','absolute')
          input.css('visibility','visible')
          input.css('left',xmargin+25)
          input.css('top',p.position().top)
          input.blur()
          input.val(gb.data[i]) # Firefoxの場合日本語入力中にこれが効かないことがあるような... blurしておけば大丈夫ぽい
          input.focus()
          input.mousedown linefunc(i, gb)
          setTimeout ->
            $("#editline").focus()
          , 100  # 何故か少し待ってからfocus()を呼ばないとフォーカスされない...
        else
          lastchar = ''
          if i > 0 && typeof gb.data[i-1] == "string"
            lastchar = gb.data[i-1][gb.data[i-1].length-1]
          if gb.editline == -1 && lastchar == '\\' # 継続行
            if contline < 0
              contline = i-1
            s = ''
            [contline..i].forEach (j) ->
              s += gb.data[j].replace(/\\$/,'__newline__')
            $("#list#{contline}").css('display','inline').css('visibility','visible')
              .html(@tag.expand(s,wiki,contline).replace(/__newline__/g,''))
            $("#listbg#{contline}").css('display','inline').css('visibility','visible')
            t.css('visibility','hidden')
            p.css('visibility','hidden')
          else # 通常行
            contline = -1
            if typeof gb.data[i] == "string" && (m = gb.data[i].match(/\[\[(https:\/\/gist\.github\.com.*\?.*)\]\]/i))
              # gistエンベッド
              # https:#gist.github.com/1748966 のやり方
              gisturl = m[1]
              gistFrame = document.createElement("iframe")
              gistFrame.setAttribute("width", "100%")
              gistFrame.id = "gistFrame" + i
              gistFrame.style.border = 'none'
              gistFrame.style.margin = '0'
              t.children().remove() # 子供を全部消す
              t.append(gistFrame)
              gistFrameHTML = '<html><body onload="parent.adjustIframeSize(document.body.scrollHeight,'+i+
                  ')"><scr' + 'ipt type="text/javascript" src="' + gisturl + '"></sc'+'ript></body></html>'
              # Set iframe's document with a trigger for this document to adjust the height
              gistFrameDoc = gistFrame.document
              if gistFrame.contentDocument
                gistFrameDoc = gistFrame.contentDocument
              else if gistFrame.contentWindow
                gistFrameDoc = gistFrame.contentWindow.document

              gistFrameDoc.open()
              gistFrameDoc.writeln(gistFrameHTML)
              gistFrameDoc.close()
            else
              t.css
                display: 'inline'
                visibility: 'visible'
                'line-height': ''
              .html @tag.expand(gb.data[i],wiki,title,i)
              p.attr "class", "listedit#{ind}" # addClassだとダメ!! 前のが残るのか?
              p.css
                display: 'block'
                visibility: 'visible'
                'line-height': ''
      else
        t.css 'display', 'none'
        p.css 'display', 'none'


      # 各行のバックグラウンド色設定
      color = if (@version >= 0 || @showold) then bgcol(gb.timestamps[i]) else 'transparent'
      $("#listbg#{i}").css 'background-color', color
      if @version >= 0 # ツールチップに行の作成時刻を表示
        $("#list#{i}").addClass 'hover'
        date = new Date()
        createdate = new Date(date.getTime() - gb.timestamps[i] * 1000)
        $("#list#{i}").attr 'title', createdate.toLocaleString()
        $(".hover").tipTip
          maxWidth:        "auto"   #ツールチップ最大幅
          edgeOffset:      5        #要素からのオフセット距離
          activation:      "hover"  #hoverで表示、clickでも可能
          defaultPosition: "bottom" #デフォルト表示位置
      else
        $("#listbg#{i}").removeClass('hover')

    [gb.data.length...1000].forEach (i) ->
      $("#list#{i}").css('display','none')
      $("#listbg#{i}").css('display','none')

    input.css('display', if gb.editline == -1 then 'none' else 'block')

    gb.align()

    # リファラを消すプラグイン
    # http://logic.moo.jp/memo.php/archive/569
    # http://logic.moo.jp/data/filedir/569_3.js
    #
    #jQuery.kill_referrer.rewrite.init()
    follow_scroll.call @, gb

    # 編集中の行│画面外に移動した時に、ブラウザをスクロールして追随する

  follow_scroll = (gb) ->
    # 編集中かどうかチェック
    return if gb.editline < 0
    return if @showold

    currentLinePos = $("#editline").offset().top
    return if !(currentLinePos && currentLinePos > 0)
    currentScrollPos = $("body").scrollTop()
    windowHeight = window.innerHeight

    # 編集中の行が画面内にある場合、スクロールする必要が無い
    return if currentScrollPos < currentLinePos && currentLinePos < currentScrollPos+windowHeight

    $("body").stop().animate({'scrollTop': currentLinePos - windowHeight/2}, 200)

window.GyazzDisplay = GyazzDisplay
