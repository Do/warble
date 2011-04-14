class HypeController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def index
    page = params[:page] || 1

    hype_songs =   # TODO: maybe route instead of case? eh..
      if params[:feed] == 'latest'
        Hype.latest(page)
      elsif params[:feed] == 'popular' && params[:time] == '3days'
        Hype.popular_3days(page)
      elsif params[:feed] == 'popular' && params[:time] == 'week'
        Hype.popular_week(page)
      elsif params[:username]
        Hype.user(params[:username], page)
      end

    # convert HypeM API objects to our song objects
    songs = hype_songs.map do |hype_song|
      Song.find_or_create_from_hype_song(hype_song, current_user)
    end

    respond_with songs
  end
end