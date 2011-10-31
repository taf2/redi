require 'redi/pool'

class Redi

  ### these commands are complicated to distribute across a pool and so
  ### for now are unimplemented. Translation: we are lazy.
  UNIMPLEMENTED_COMMANDS = %w[
    keys move object randomkey rename renamenx eval
    mget mset msetnx
    brpoplpush rpoplpush
    sdiff sdiffstore sinter sinterstore smove sunion sunionstore
    zinterstore zunionstore
    psubscribe publish punsubscribe subscribe unsubscribe
    discard exec multi unwatch watch
    auth echo ping quit select
    bgrewriteaof bgsave config dbsize debug flushdb info lastsave monitor save shutdown slaveof slowlog sync
  ]

  ### raise exceptions on unimplemented/unknown commands, delegate
  ### everything else down to the actual Redis connections
  def self.method_missing( cmd, *args )
    if UNIMPLEMENTED_COMMANDS.include?( cmd.to_s )
      raise NotImplementedError, "#{cmd} has not yet been implemented. Patches welcome!"
    end

    pool.redis_by_key( args.first ).send( cmd, *args )
  end

  def self.flushall
    pool.flushall
  end

  def self.pool(mock=false)
    require 'redi/mock' if mock
    @pool ||= Pool.new(self.config,mock)
  end

  def self.config=(config)
    @config = config
  end

  def self.config
    @config
  end

end
