class SongsController < ApplicationController

  NUMBER_OF_SONGS = 50

  def index
    results =
      if params[:query].blank?
      	# If blank allow navigating
      	size = (params[:size] || NUMBER_OF_SONGS).to_i
      	offset = ((params[:page] || 1).to_i - 1) * size
      	Song.find(:all, order: 'title', offset: offset, limit: size + 1)
      else
        Song.search(params[:query], page: params[:page] || 1, load: true).results
      end
    render json: results
  end

end
