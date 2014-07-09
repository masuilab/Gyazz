#
# Gyazzページのデータ
#
 
debug    = require('debug')('gyazz:page')
mongoose = require 'mongoose'


module.exports = (app) ->
  
  pageSchema = new mongoose.Schema {
    wiki: String
    title: String
    text: String
    timestamp: Date
  }, {
    collection: "Pages" # Mongooseは勝手に小文字の複数形にするので大文字を使うときはこういう指定が必要
  }

  # Pageクラス(?)のクラスメソッド(?)みたいなものの定義。
  pageSchema.statics.latest = (wiki, title, callback) ->
    @find
      wiki: wiki
      title:title
    .sort
      timestamp: -1
    .limit 1
    .exec (err, results) ->
      callback err, results[0]  # 最新のをひとつだけ取得

#  pageSchema.statics.related = (param,callback) ->
#    Pair = mongoose.model 'Pair'
#    debug Pairs.related this # 関連ページとウェイトを得る
#    debug "vvvvvvvvvvvvvvvvvvvvvvvvvv"
#    callback 0
#    debug "^^^^^^^^^^^^^^^^^^^^^^^^^^^"
#
#
#  # 関連ページをリストするインスタンスメソッドみたいなもの
#  # page.related(callback) とする?
#  #
#  pageSchema.methods.related = (callback) ->
#    debug "pageSchema.meghods.related-------------------"
#    debug callback
#    Pairs = mongoose.model 'Pairs'
#    debug Pairs.related this # 関連ページとウェイトを得る
#    debug "vvvvvvvvvvvvvvvvvvvvvvvvvv"
#    callback 0
#    debug "^^^^^^^^^^^^^^^^^^^^^^^^^^^"
#    #                      ここで関連ページリストを得る?

  mongoose.model 'Page', pageSchema

