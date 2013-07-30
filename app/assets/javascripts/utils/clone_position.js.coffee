# Clones the position of one element to another.
# This is a port of Prototypes's Element.clonePosition.
# See: http://api.prototypejs.org/dom/Element/clonePosition
window.Utils = Utils ? {}
Utils.clonePosition = (src, target, options = {}) ->
  _.defaults options,
    setWidth: true
    setHeight: true

  $(target).css {
    position: 'absolute'
    top: "0"
    left: "0"
  }

  if options.setWidth
    $(target).width $(src).width()

  if options.setHeight
    $(target).height $(src).height()

  true
