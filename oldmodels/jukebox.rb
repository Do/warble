class Old::Jukebox < Ohm::Model
  list      :played,   Song
  reference :current,  Song
  attribute :volume

  def upcoming
    key[:upcoming]
  end

  def to_hash
    super.merge :current => current,
                :volume  => volume.to_i
  end

  def self.app    # TODO: hack for the meantime until multiple jukebox support
    self.all.first || self.create
  end

  def skip!
    if upcoming.zcard == 0
      self.current = nil
    else
      played << self.current if self.current   # add current song to played list
      next_song = upcoming.zrange(0, 0).map(&Song).first
      upcoming.zrem(next_song.id)
      self.current = next_song
    end

    save

    # notify clients
    Ohm.redis.publish(Warble::Application.config.pubsub_channel, {
      event:   'skip',
      jukebox: Jukebox.app   # TODO: send removing song and client should validate, if wrong, refetch whole queue
    }.to_json)
  end

  def add_song(song, user)            # TODO: ensure transactional
    song.incr :plays
    song.lovers << user               # assume user adding to queue loves it

    if Date.today.to_s != user.date_last_queued
      user.date_last_queued = Date.today.to_s
      user.num_songs_queued_today = 0
    end

    priority = user.num_songs_queued_today.to_i
    upcoming.zadd(priority, song.id)
    user.num_songs_queued_today = priority + 1
    user.save

    # notify clients of new song. send all songs since the order may have changed
    Ohm.redis.publish(Warble::Application.config.pubsub_channel, {
      event: 'refresh',
      songs: Jukebox.app.upcoming.zrange(0, -1).map(&Song)
    }.to_json)

    skip! if self.current.nil?        # pick next song if nothing playing
  end

  def set_volume(volume)
    self.volume = volume
    save
    
    Ohm.redis.publish(Warble::Application.config.pubsub_channel, {
      event: 'volume',
      jukebox: Jukebox.app
    }.to_json)
  end
end