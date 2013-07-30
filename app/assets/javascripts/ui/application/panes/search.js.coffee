#= require ui/application/panes/pane
#= require templates/search
#= require templates/search_results

# TODO: abstract some of this stuff out to a generic
#       search class that Youtube can share
class Warble.SearchView extends Warble.PaneView
  template: window.JST['templates/search']
  resultsTemplate: window.JST['templates/search_results']

  events:
    'click a.library_search'   : 'search'
    'keypress input'           : 'handleEnter'
    'click a.result'           : 'queueVideo'
    'click a#previous_results' : 'previousPage'
    'click a#next_results'     : 'nextPage'

  initialize: ->
    @page = 1
    @pageSize   = 10
    @collection = new Warble.SearchList
    @collection.bind 'all', @render, @

  render: ->
    @$el.html @template
      query:   @collection.query      
    @

  activate: ->
    @$('#search_query').focus()

  handleEnter: (event) ->
    if event.which == 13
      @search event

  previousPage: (event) ->
    @page -= 1
    @page = 1 if @page < 1 
    @search event

  nextPage: (event) ->
    @page += 1
    @search event

  search: (event) ->
    @page = 1
    @collection.query = @$('#search_query').val()
    successCallback = =>
      window.workspace.hideSpinner()
      @$('#search_results').html @resultsTemplate
        results: @collection.toJSON()
        hasPrev: @page > 1
        hasNext: @collection.size() > @pageSize

    window.workspace.showSpinner()
    @collection.fetch
      data: $.param
        page: @page
        size: @pageSize
      success: successCallback
      error: ->
        window.workspace.navigate '/', true
        window.workspace.hideSpinner()

    event.preventDefault()

  queueVideo: (event) ->
    window.workspace.showSpinner()

    song_id = $(event.currentTarget).attr('data-id')
    $.post '/jukebox/playlist',
      'song_id[]': [song_id]

    window.workspace.hideSpinner()
    event.preventDefault()
