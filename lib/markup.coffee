# convert Gyazz Markup to HTML
'use strict'

_ = require 'underscore'

module.exports = class GyazzMarkup

  constructor: (opts) ->
    @host = opts.host
    @wiki = opts.wiki

  markup: (lines, opts={escape: true}) ->
    lines = _.escape lines if opts.escape

    lines
      .split /[\r\n]/
      .map (line) =>
        methods = [
          'url_with_image'
          'image'
          'strong'
          'url_with_title'
          'url'
          'wiki_link'
          'inner_link'
        ]
        for method in methods
          line = @[method](line)
        return line
      .join ('\n')

  url_with_image: (line) ->
    reg = /\[{2}(https?:\/\/[^\s\[\]]+)\s(https?:\/\/[^\s\[\]]+)\.(png|jpe?g|gif|bmp)\]{2}/gi
    return line unless reg.test line
    line.replace reg, "<a href=\"$1\"><img src=\"$2.$3\"></a>"

  image: (line) ->
    reg = /\[{2,3}(https?:\/\/[^\s\[\]]+)\.(png|jpe?g|gif|bmp)\]{2,3}/gi
    return line unless reg.test line
    line.replace reg, "<a href=\"$1.$2\"><img src=\"$1.$2\"></a>"

  strong: (line) ->
    reg = /\[{3}([^\[\]]+)\]{3}/g
    return line unless reg.test line
    line.replace reg, "<strong>$1</strong>"

  url_with_title: (line) ->
    reg = /\[{2}(https?:\/\/[^\s\[\]]+)\s([^\[\]]+)\]{2}/gi
    return line unless reg.test line
    line.replace reg, "<a href=\"$1\">$2</a>"

  url: (line) ->
    reg = /\[{2}(https?:\/\/[^\s\[\]]+)\]{2}/gi
    return line unless reg.test line
    line.replace reg, "<a href=\"$1\">$1</a>"

  wiki_link: (line) ->
    reg = /\[{2}([^\/\[\]]+)::([^\[\]]+)\]{2}/gi
    return line unless reg.test line
    line.replace reg, "<a href=\"#{@host}/$1/\">$1</a>::<a href=\"#{@host}/$1/$2\">$2</a>"

  inner_link: (line) ->
    reg = /\[{2}([^\[\]]+)\]{2}/g
    return line unless reg.test line
    line.replace reg, "<a href=\"#{@host}/#{@wiki}/$1\">$1</a>"
