# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  shaHandler = (e) ->
    if 'sha-value' == e.target.className
      element = e.target;
      if window.getSelection and document.createRange
        range = document.createRange()
        selection = window.getSelection()
        range.selectNodeContents(element)
        selection.removeAllRanges()
        selection.addRange(range)
      e.preventDefault()
      e.stopPropagation()

  compareMultiDiffs = (e) ->
    if $('#commit1') and $('#commit2')
      commit1 = $('#commit1').val()
      commit2 = $('#commit2').val()

      if not commit1
        return $('#commit1').focus()

      if not commit2
        return $('#commit2').focus()

      currentUrl = window.location.href
      currentUrl = currentUrl.replace /commits\/master/, 'commit'
      newUrl = currentUrl + '/' + commit1 + '..' + commit2
      window.location.href = newUrl

  $(window).on 'click', (e) -> shaHandler(e)
  $('#compare-diffs').on 'click', (e) -> compareMultiDiffs(e)
