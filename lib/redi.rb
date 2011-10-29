require 'redi/pool'

class Redi
  VERSION = "0.0.5"

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

  def self.mock!
    pool(true).mock!
  end

  def self.pool(mock=false)
    @pool ||= Pool.new(self.config,mock)
  end

  def self.config=(config)
    @config = config
  end

  def self.config
    @config
  end

  class Mock
    def initialize
      @store = {}
    end

    def get(key)
      @store[key]
    end

    def del(key)
      @store.delete(key)
    end

    def set(key, val)
      @store[key] = val
    end

    def mget(*keys)
      keys.map {|k| get(k) }
    end

    def flushall
      @store = {}
    end

  end

end
