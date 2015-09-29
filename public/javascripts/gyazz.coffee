#
# jQueryを利用して書き直し (2011/6/11 masui)
# CoffeeScriptに書き直し   (2014/7/20 masui)
#

#
#  以下はExpressでセットされる
#  var wiki =  '増井研';
#  var title = 'MIRAIPEDIA';
#

gs = new GyazzSocket   # socket.io
gd = new GyazzDisplay  # display()
gb = new GyazzBuffer   # Gyazzテキスト編集関連
gr = new GyazzRelated  # 関連ページ取得
gu = new GyazzUpload   # アップロード処理
gt = new GyazzTag

# 依存関係を設定
gd.init gt
gb.init gs, gd, gt
gs.init gb, gd, gt
gu.init gb, gs, gd

historycache = {}            # 履歴cache
clickline = -1               # マウスクリックして押してるときだけ行番号が入る

KC =
  tab:   9
  enter: 13
  ctrlD: 17
  left:  37
  up:    38
  right: 39
  down:  40
  k:     75
  n:     78
  p:     80
  s:     83

$ -> # = $(document).ready()
  $('#rawdata').hide()

  [0...1000].forEach (i) ->
    y = $('<div>').attr('id',"listbg#{i}")
    x = $('<span>').attr('id',"list#{i}").mousedown(linefunc(i,gb))
    $('#contents').append(y.append(x))

  b = $('body')
  b.bind "dragover", (e) -> false
  b.bind "dragend",  (e) -> false
  b.bind "drop",     (e) -> # Drag&Dropでファイルをアップロード
    e.preventDefault() # デフォルトは「ファイルを開く」
    files = e.originalEvent.dataTransfer.files
    gu.sendfiles files
    false

  $('#filterdiv').css('display','none')
  $("#filter").keyup (event) ->
    $('#filterdiv').css('display','none') if $('#filter').val() == ''
    gb.refresh()

  gs.getdata
    force:   true
    suggest: true # 1回目はsuggestオプションを付けてデータ取得
  , (res) ->
    gb.timestamps = res.timestamps
    gb.data       = res.data.concat()
    gb.datestr    = res.date
    gb.refresh()

  gr.getrelated()

longPressTimeout = false
longmousedown = ->
  gb.editline = clickline
  gd.display gb, true

$(document).mouseup (event) ->
  clearTimeout longPressTimeout
  clickline = -1
  true

$(document).mousemove (event) ->
  clearTimeout longPressTimeout
  true

$(document).mousedown (event) ->
  if clickline == -1  # 行以外をクリック
    gb.seteditline clickline
    gs.writedata gb.data
  else
    clearTimeout longPressTimeout
    if gb.editline != clickline # #27
      longPressTimeout = setTimeout longmousedown, 300
  true

$(document).keyup (event) ->
  gb.data[gb.editline] = $("#editline").val()

#  keypressを定義しておかないとFireFox上で矢印キーを押してときカーソルが動いてしまう
$(document).keypress (event) ->
  kc = event.which
  if kc == KC.enter
    event.preventDefault() if $(':focus').attr('id') != 'search'
  if kc == KC.enter
    # 1行追加
    # IME確定でもkeydownイベントが出てしまうのでここで定義が必要!
    gb.deleteblankdata()
    if gb.editline >= 0 && gb.editline < gb.data.length
      gb.addblankline(gb.editline+1,gb.line_indent(gb.editline))
      gb.refresh()
      return false
    # カーソルキーやタブを無効化
    if !event.shiftKey && (kc == KC.down || kc == KC.up || kc == KC.tab)
      return false

getversion = (n) ->
  if gd.version + n >= -1
    gd.version += n
    gs.getdata
      version:gd.version
    , (res) ->
      gb.data = res.data.concat()
      gb.datestr = res.date
    gb.refresh()

$(document).keydown (event) ->
  kc = event.which
  sk = event.shiftKey
  ck = event.ctrlKey
  cd = event.metaKey && !ck

  switch
    when ck && kc == KC.s && gb.editline >= 0 # Ctrl-Sでtranspose
      event.preventDefault()
      gb.transpose()
    when kc == KC.enter
      $('#filter').val('')
      gs.writedata gb.data
    when kc == KC.down && sk # Shift+↓ = 下にブロック移動
      gb.block_down()
    when kc == KC.k && ck # Ctrl+K カーソルより右側を削除する
      gb.kill()
    when kc == KC.down && ck # 行を下に移動
      gb.line_down()
    when kc == KC.down && !sk || kc == KC.n && !sk && ck # 下にカーソル移動
      gb.cursor_down()
    when kc == KC.up && sk # 上にブロック移動
      gb.block_up()
    when kc == KC.up && ck && gb.editline > 0 # 行を上に移動
      gb.line_up()
    when (kc == KC.up && !sk) || (kc == KC.p && !sk && ck) # 上にカーソル移動
      gb.cursor_up()
    when kc == KC.tab && !sk || kc == KC.right && sk # indent
      gb.indent()
    when kc == KC.tab && sk || kc == KC.left && sk # undent
      gb.undent()
    when kc == KC.left && !sk && !ck && gb.editline < 0 # zoom out
      gb.zoomout()
    when kc == KC.right && !sk && !ck && gb.editline < 0 # zoom in
      gb.zoomin()
    when ck && kc == KC.left # 古いバージョンゲット
      getversion 1
    when ck && kc == KC.right
      getversion -1
    when kc >= 0x30 && kc <= 0x7e && gb.editline < 0 && !cd && !ck && $(':focus').attr('id') != 'search'
      $('#filterdiv').css('display','block')
      $('#filter').focus()

# 行クリックで呼ばれる関数をクロージャで定義
window.linefunc = (n,gb) ->
  (event) ->
    clickline = n
    if event.shiftKey
      gb.addblankline n, gb.line_indent(n)  # 上に行を追加
      gb.refresh()
    true

show_history = (res) ->
  gb.datestr =    res.date
  gb.timestamps = res.timestamps
  gb.data =       res.data
  gb.refresh()

window.adjustIframeSize = (newHeight, i) ->
  frame= document.getElementById("gistFrame"+i)
  frame.style.height = parseInt(newHeight) + "px"
