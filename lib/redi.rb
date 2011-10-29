require 'redi/pool'

class Redi
  VERSION = "0.0.6"

  def self.get(key)
    pool.redis_by_key(key).get(key)
  end

  def self.set(key, val)
    pool.redis_by_key(key).set(key, val)
  end

  def self.del(key)
    pool.redis_by_key(key).del(key)
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
