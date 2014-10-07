$ ->
  $('.btn_share').click ->
    url = decodeURI(location.href).replace /[\s<>]/g, (c) -> encodeURI c
    window.prompt "#{wiki}/#{title}", url
