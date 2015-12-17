#
# テキストバッファの編集関連
# 適宜HTMLを更新したりサーバと通信したりする必要あり
#

class GyazzBuffer
  init: (gs, gd, tag) ->
    @gs = gs
    @gd = gd
    @tag = tag

  # levelの長さの空白文字列
  _indentstr = (level) ->
    ([0...level].map (x) -> " ").join('')

  # 文字列のインデントを計算
  _indent = (line) ->
    line.match(/^( *)/)[1].length

  _spaces = []           # 行に含まれている空白文字の数

  # 外部から見える変数
  data:       []         # テキストデータ
  datestr:    ''
  timestamps: []
  doi:        []
  editline: -1           # 現在編集中の行番号
  zoomlevel: 0

  refresh: ->
    @zoomlevel = 0
    @calcdoi()
    @gd.display @

  seteditline: (line) ->
    @editline = line
    @gd.display @, true

  calcdoi: ->
    q = $('#filter')
    pbs = new POBoxSearch(assocwiki_pobox_dict)
    re = null
    if q && q.val() != ''
      re = pbs.regexp q.val(), false
    maxind = @maxindent()
    [0...@data.length].forEach (i) =>
      if (if re then re.exec(@data[i]) else true)
        @doi[i] = maxind - @line_indent(i)
      else
        @doi[i] = 0 - @line_indent(i) - 1
  
  #init: (arg) ->
  #  @data = if typeof arg == 'string' then arg.split /\n/ else arg
    
  # n行目のインデントを計算
  line_indent: (n) ->
    s = @data[n] || ''
    _indent s
      
  # 最大のインデント値を取得
  maxindent: ->
    Math.max (@data.map (line) -> _indent line)...
    #
    # reduce を使うとこういう感じになるのだが、Coffeeだと上のような記法が可能らしい
    # maxindent: ->
    #   indents = data.map (line) -> _indent line
    #   _.reduce indents, ((x, y) -> Math.max(x, y)), 0

  # 空白行を削除
  deleteblankdata: ->
    @data = _.filter @data, (line) ->
      typeof line == "string" && !line.match /^\s*$/

  # 空白行を挿入
  addblankline: (line, indent) ->
    @editline = line
    # @eline = line # ?????
    @deleteblankdata()

    if @data.length > @editline
      [@data.length-1..@editline].forEach (i) =>
        @data[i+1] = @data[i]
    @data[@editline] = _indentstr indent
  
  # n行目からブロック移動しようとするときのブロック行数
  _movelines = (n) ->
    ind = @line_indent n
    last = _.find [n+1...@data.length], (i) =>
      @line_indent(i) <= ind
    (last ||= @data.length) - n

  # インデントが自分と同じか自分より深い行を捜す。
  # ひとつもなければ -1 を返す。
  # 引数にeditlineを指定するように仕様が変わっている
  _destline_up = (n) ->
    ind_editline = @line_indent n
    foundline = -1
    if n > 0
      _.find [n-1..0], (i) =>
        ind = @line_indent i
        foundline = i if ind > ind_editline
        if ind == ind_editline
          foundline = i
          return true
        if ind < ind_editline
          return true
    foundline

  # インデントが自分と同じ行を捜す。
  # ひとつもなければ -1 を返す。
  _destline_down = (n) ->
    ind_editline = @line_indent n
    foundline = -1
    _.find [n+1...@data.length], (i) =>
      ind = @line_indent i
      if ind == ind_editline
        foundline = i
        return true
      if ind < ind_editline
        foundline = -1
        return true
    foundline
    
  #########################################################################
  #
  #   行移動 / ブロック移動
  #
  #########################################################################

  # カーソルを下に移動
  cursor_down: ->
    if @editline >= 0 && @editline < @data.length-1
      dest = _.find [@editline+1...@data.length], (i) =>
        @doi[i] >= -@zoomlevel
      if dest
        setTimeout =>
          @editline = dest
          @deleteblankdata()
          @gs.writedata @data
          @gd.display @
        , 1

  # カーソルを上に移動
  cursor_up: ->
    if @editline > 0
      dest = _.find [@editline-1..0], (i) =>
        @doi[i] >= -@zoomlevel
      if dest != undefined
        setTimeout =>
          @editline = dest
          @deleteblankdata()
          @gs.writedata @data
          @gd.display @
        , 1

  # カーソルの行を下に移動
  line_down: ->
    if @editline >= 0 && @editline < @data.length-1
      l = @editline
      [@data[l], @data[l+1]] = [@data[l+1], @data[l]]
      setTimeout =>
        @editline += 1
        @deleteblankdata()
        @gs.writedata @data  #####
        @gd.display @
      , 1
  
  # カーソルの行を上に移動
  line_up: ->
    if @editline > 0
      l = @editline
      [@data[l], @data[l-1]] = [@data[l-1], @data[l]]
      setTimeout =>
        @editline -= 1
        @deleteblankdata()
        @gs.writedata @data  #####
        @gd.display @
      , 1
  
  # editlineのブロックを下に移動
  block_down: ->
    if @editline >= 0 && @editline < @data.length - 1
      m = _movelines.call @, @editline
      dst = _destline_down.call @, @editline
      if dst >= 0
        m2 = _movelines.call @, dst
        tmp = []
        [0...m].forEach  (i) => tmp[i] = @data[@editline+i]
        [0...m2].forEach (i) => @data[@editline+i] = @data[dst+i]
        [0...m].forEach  (i) => @data[@editline+m2+i] = tmp[i]
        @editline += m2
        @deleteblankdata()
        @gs.writedata @data
        @gd.display @

  # editlineのブロックを上に移動
  block_up: ->
    if @editline > 0 && @editline < @data.length
      m = _movelines.call @, @editline
      dst = _destline_up.call @, @editline
      if dst >= 0
        m2 = @editline - dst
        tmp = []
        [0...m2].forEach (i) => tmp[i] = @data[dst+i]
        [0...m].forEach (i)  => @data[dst+i] = @data[@editline+i]
        [0...m2].forEach (i) => @data[dst+m+i] = tmp[i]
        @editline = dst
        @deleteblankdata()
        @gs.writedata @data
        @gd.display @

  #########################################################################
  #
  #   インデント
  #
  #########################################################################

  # インデント
  indent: ->
    if @editline >= 0 && @editline < @data.length
      @data[@editline] = ' ' + @data[@editline]
      @gs.writedata @data
      @gd.display @

  # アンデント
  undent: ->
    if @editline >= 0 && @editline < @data.length
      s = @data[@editline]
      if s.substring(0,1) == ' '
        @data[@editline] = s.substring(1,s.length)
      @gs.writedata @data
      @gd.display @

  #########################################################################
  #
  #   ズーミング
  #
  #########################################################################

  # ズームイン
  zoomin: ->
    if @zoomlevel < 0
      @zoomlevel += 1
      @gd.display @

  # ズームアウト
  zoomout: ->
    if -@zoomlevel < @maxindent()
      @zoomlevel -= 1
      @gd.display @

  #########################################################################
  #
  #   右側消去
  #
  #########################################################################

  kill: ->
    input = $("#editline")
    if input.val().match(/^\s*$/) && @editline < @data.length-1  # 行が完全に削除された時
      @data[@editline] = ""# 現在の行を削除
      @deleteblankdata()
      @gs.writedata @data
      @refresh()
      setTimeout ->
        # カーソルを行頭に移動
        # input = $("#editline")
        input[0].selectionStart = 0
        input[0].selectionEnd = 0
      , 10
      return
    setTimeout ->  # Mac用。ctrl+kでカーソルより後ろを削除するまで待つ
      cursor_pos = input[0].selectionStart
      if input.val().length > cursor_pos  # ctrl+kでカーソルより後ろが削除されていない場合
        input.val input_tag.val().substring(0, cursor_pos) # カーソルより後ろを削除
        input.selectionStart = cursor_pos
        input.selectionEnd = cursor_pos
    , 10
    
  #########################################################################
  #
  #   桁揃え、行桁交換
  #
  #########################################################################

  _similarlines = (process, condition) -> # 同じパタンの連続行の処理
    beginline = 0
    lastspaces = -1
    lastindent = -1

    _spaces = @data.map (line) => # 行に空白がいくつ含まれているか
      @tag.split(line).length - _indent(line) - 1
    
    [0...@data.length].forEach (i) =>
      if _spaces[i] > 0 && _spaces[i] == lastspaces && @line_indent(i) == lastindent
        # 連続パタン続行中
      else
        if lastspaces > 1 && i-beginline > 1  # 同じパタンの連続を検出
          if condition beginline, i, @editline
            process.call @, beginline, i-beginline, @line_indent(beginline)
        beginline = i

      lastspaces = _spaces[i]
      lastindent = @line_indent(i)

    if lastspaces > 1 && @data.length-beginline > 1 #  同じパタンの連続を検出
      if condition beginline, @data.length
        process.call @, beginline, @data.length-beginline, @line_indent(beginline)

  #
  # 桁揃え
  #
  align: -> # 同じパタンの連続を検出して桁を揃える
    _similarlines.call @, _do_align, -> true

  _do_align = (begin, lines, dummy) -> # begin番目からlines個の行を桁揃え
    pos = []
    width = []
    maxwidth = []
    [begin...begin+lines].forEach (line) => # 表示されている要素の位置を取得
      pos[line] = []
      width[line] = []
      [0.._spaces[begin]].forEach (i) =>
        # 要素のidはtag()でつけられている
        id = "#e" + line + "_" + (i + @line_indent(line))
        pos[line][i] = $(id).offset().left
      [0.._spaces[begin]].forEach (i) ->
        width[line][i] = pos[line][i+1]-pos[line][i]
  
    [0..._spaces[begin]].forEach (i) -> # 桁ごとに最大幅を計算 範囲 あってる????
      max = 0
      [begin...begin+lines].forEach (line) ->
        max = width[line][i] if width[line][i] > max
      maxwidth[i] = max
  
    colpos = pos[begin][0]
    [0.._spaces[begin]].forEach (i) => # 最大幅ずつずらして表示
      [begin...begin+lines].forEach (line) =>
        id = "#e" + line + "_" + (i + @line_indent(line))
        $(id).css('position','absolute').css('left',colpos)
      colpos += maxwidth[i]

  #
  # editline周辺の行の行と桁を入れ換える
  #
  transpose: ->
    return if @editline < 0
    _similarlines.call @, _do_transpose, _transpose_condition # thisを伝播させる

  _transpose_condition =  (beginline,limit,editline) ->
    editline >= beginline && editline < limit
    
  # begin番目からlines個の行の行と桁を入れ換え
  _do_transpose = (beginline, lines, indent) ->
    cols = _spaces[beginline] + 1
    newlines = []
    [0...cols].forEach (i) ->
      newlines[i] = _indentstr indent

    [0...lines].forEach (y) =>
      s = @data[beginline+y]
      s = s.replace(/^\s*/,'').replace(/</g,'&lt')
      a = @tag.split(s)
      [0...a.length].forEach (i) ->
        newlines[i] += " " if y != 0
        newlines[i] += a[i]
      
    # data[] の beginlineからlines行をnewlines[]で置き換える
    @data.splice beginline, lines
    [0...newlines.length].forEach (i) =>
      @data.splice beginline+i, 0, newlines[i]
  
    @gs.writedata @data
    @editline = -1
    @gd.display @, true
    # transpose後に行選択しておきたいが、前の行データが残っててうまくいかない

window.GyazzBuffer = GyazzBuffer
