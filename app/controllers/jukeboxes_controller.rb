class JukeboxesController < ApplicationController
  # App bootstrap
  def app
    @volume = Jukebox.volume
  end

  # Player page bootstrap
  def player
    @rdio_client_id = ENV['RDIO_CLIENT_ID']
    if @rdio_client_id
      @rdio_token = Rdio::Client.new(ENV['RDIO_APP_KEY'], ENV['RDIO_APP_SECRET']).playback_token(request.host)
    end
  end

  def show
    # If the player is retrieving the song, track it
    if params[:player] 
      song = Jukebox.current_song
      if $scrobbler
        # TODO track the song, need credentials to test
        unless $scrobbler.session_id
        # $scrobbler.handshake! # get token / session id
        end
        # playing = Scrobbler::Playing.new(:session_id => $scrobbler.session_id,
        #                         :now_playing_url => $scrobbler.now_playing_url,
        #                         :artist => song.artist,
        #                         :track => song.title,
        #                         :album => song.album
        # )
      end
    end


    render json: Jukebox
  end

  def skip
    # TODO: only move forward if sent song id = current id, prevent multiple players from skipping too fast
    Jukebox.skip
    head :ok
  end

  def volume
    Jukebox.volume = params[:value]
    head :ok
  end

  # Rdio JS API authentication helper shim
  def rdio_helper
    render layout: false
  end
end
