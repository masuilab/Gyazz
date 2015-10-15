#
# PNGを自力で生成する (masui 2014/07/13 14:26:29)
#
# こういう感じのRGB配列をPNGにする
# data = [
#   [[0, 0, 0], [100, 100, 100], [200, 200, 200]],
#   [[0, 0, 0], [100, 100, 100], [200, 200, 200]],
#   [[0, 0, 0], [100, 100, 100], [200, 200, 200]]
# ]
#
# クラス定義のやり方がよくわからない
# バイナリ操作(Bufferの使い方)もよくわからない
#  http://nodejs.org/api/buffer.html
#
# もしかして: npmに既存だったりして?
#
# こういうのがあった (2014/07/14 15:49:14)
# https://www.npmjs.org/package/node-png
#

crc32 = require 'buffer-crc32'
zlib = require 'zlib'

module.exports = class Png
  chunk = (type, data) ->
    buf = new Buffer data.length+12, 'binary'
    buf.writeUInt32BE data.length, 0
    buf.write type, 4
    data.copy buf, 8

    bufx = new Buffer data.length+4, 'binary'
    bufx.write type, 0
    data.copy bufx, 4

    buf_crc = crc32 bufx
    buf_crc.copy buf, data.length+8

    buf

  png: (data, callback, depth=8, color_type=2) ->
    height = data.length
    width = data[0].length
    buf1 = new Buffer "\x89PNG\r\n\x1a\n", 'binary'

    buf = new Buffer 13, 'binary'
    buf.writeUInt32BE width, 0
    buf.writeUInt32BE height, 4
    buf.writeUInt8 depth, 8
    buf.writeUInt8 color_type, 9
    buf.writeUInt8 0, 10
    buf.writeUInt8 0, 11
    buf.writeUInt8 0, 12
    buf2 = chunk "IHDR", buf

    imagebuf = new Buffer height * (width * 3 +1)

    pos = 0
    data.map (line) ->
      d = [0].concat line... # http://stackoverflow.com/questions/4631525/
      d.map (c) -> imagebuf.writeUInt8 c, pos++

    zlib.deflate imagebuf, (err, res) ->
      return if err
      buf3 = chunk "IDAT", new Buffer res, 'binary'
      buf4 = chunk "IEND", new Buffer "", 'binary'
      buf = new Buffer 33+buf3.length+buf4.length, 'binary'
      buf1.copy buf, 0
      buf2.copy buf, 8
      buf3.copy buf, 33
      buf4.copy buf, 33 + buf3.length
      callback buf
