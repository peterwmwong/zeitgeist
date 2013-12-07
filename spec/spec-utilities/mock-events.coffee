module.exports =
  fireMouseEvent: (type, target)->
    event = document.createEvent "MouseEvent"
    event.initMouseEvent type, true, true, null, null, null, null, null,
                         null, null, null, null, null, null, target
    target.dispatchEvent event
