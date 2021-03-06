#= require models/plays

class Warble.Jukebox extends Backbone.Model
  url: '/jukebox'

  initialize: ->
    @current_play = new Warble.Play;
    @bind 'change', =>
      @current_play.set @get('current_play'), silent: true
      @current_play.change()
