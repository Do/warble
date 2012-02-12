require 'fileutils'

class Song < ActiveRecord::Base
  include Tire::Model::Search

  validate :source,      presence: true
  validate :external_id, presence: true
  validate :title,       presence: true

  belongs_to :user
  has_many   :votes
  has_many   :plays
  has_many   :users_who_voted,  through: :votes, source: :user
  has_many   :users_who_played, through: :plays, source: :user

  tire.mapping do
    indexes :id,     type: :integer, index: :not_analyzed
    indexes :title,  type: :string,  analyzer: :snowball,  boost: 3
    indexes :artist, type: :string,  analyzer: :snowball,  boost: 2
    indexes :album,  type: :string,  analyzer: :snowball,  boost: 2
    indexes :source, type: :string,  index: :not_analyzed, boost: 0.1
  end

  after_commit ->(song) { Queues::Index.push song.id }  # Index after any saves


  def self.find_or_create_from_pandora_song(pandora_song, submitter)
    if song = where(source: 'pandora').where(external_id: pandora_song.music_id).first
      song
    else   # first time seeing the song, so create it
      song = Song.create({
        source:      'pandora',
        title:       pandora_song.title,
        artist:      pandora_song.artist,
        album:       pandora_song.album,
        cover_url:   pandora_song.art_url || pandora_song.artist_art_url,
        url:         pandora_song.audio_url,
        external_id: pandora_song.music_id,
        user:        submitter
      })
      Queues::Archive.push song.id    # Queue for async download
      song
    end
  end

  def self.find_or_create_from_youtube_params(params, submitter)
    if song = where(source: 'youtube').where(external_id: params[:youtube_id]).first
      song
    else
      Song.create({
        source:      'youtube',
        title:       params[:title],
        artist:      params[:author],
        cover_url:   params[:thumbnail],
        external_id: params[:youtube_id],
        user:        submitter
      })
    end
  end

  def self.find_or_create_from_hype_song(hype_song, submitter)
    if song = where(source: 'hypem').where(external_id: hype_song.id).first
      song
    else
      song = Song.create({
        source:      'hypem',
        title:       hype_song.title,
        artist:      hype_song.artist,
        url:         hype_song.url,
        external_id: hype_song.id,
        user:        submitter
      })
      Queues::Archive.push song.id    # Queue for async download
      song
    end
  end

  def self.random
    # 7 out of 10 times we'll play something from the rotation, else we'll just pick something completely random
    if rand(10) > 2
      ids = connection.select_all(
              "select plays.song_id from plays left join votes on plays.song_id = votes.song_id " +
              "where votes.id is not null or plays.user_id is not null " +
              "order by plays.created_at desc limit 1000"
      )

      find(ids[rand(ids.length)]["song_id"].to_i)
    else
      find(:first, :offset =>rand(count))
    end
  end

  def archive!
    raise 'No URL!' unless url    # Check for an actual URL
    filename = Rails.root.join('public', 'songs', "#{id}.mp3").to_s

    # Archive the song to disk
    http = Patron::Session.new
    http.connect_timeout = 2
    http.timeout = 500
    http.get_file(url, filename)

    # Check that it actually saved
    if !File.size?(filename)
      FileUtils.rm filename, force: true
      raise 'Error archiving song'
    end

    # Change location to local path
    url = "/songs/#{id}.mp3"
    save!
  end

  def as_json(options = {})
    {
      id:          id,
      source:      source,
      title:       title,
      artist:      artist,
      album:       album,
      cover_url:   cover_url,
      url:         url,
      external_id: external_id,
      user:        user,
      votes:       votes.as_json,
      voters:      users_who_voted.as_json
      # TODO: add collection of likes
    }
  end
end
