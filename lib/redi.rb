require 'rubygems'
require 'zlib'
require 'yaml'
require 'redis'
require 'redis/hash_ring'
require 'redis/namespace'

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

  # provide a key to name to host:port mapping
  #
  #  should have a larger keyspace than servers, this allows scaling up the servers without changing the keyspace mapping
  #
  # sample configuration:
  #
  # - :host:
  #   :port:
  #   :db:
  #   :buckets: 0 - 64
  # - :host:
  #   :port:
  #   :db:
  #   :buckets: 65 - 127
  #
  class Pool
    attr_reader :keyspace, :servers
    def initialize(config,mock=false)
      key_type = Struct.new(:id, :to_s)

      # build server pool
      @bucket2server = {}
      buckets = []
      @servers = config.map {|cfg|
        bucket_range = cfg.delete(:buckets)
        s, e = bucket_range.split('-').map {|n| n.to_i }
        if mock
          conn = Mock.new
        else
          conn = Redis.new(cfg)
        end
        (s..e).each do|i|
          bucket_name = "n#{i}"
          buckets << key_type.new(i, bucket_name)
          @bucket2server[bucket_name] = conn
        end
        conn
      }

      # create the keyring to map redis keys to buckets
      @keyring  = Redis::HashRing.new(buckets)
    end

    def qualified_key_for(key)
      bucket = @keyring.get_node(key)
      "#{bucket.to_s}:#{key}"
    end

    def redis_by_key(key)
      bucket = @keyring.get_node(key)
      Redis::Namespace.new(bucket.to_s, :redis => @bucket2server[bucket.to_s])
    end

    def flushall
      @servers.map {|s| s.flushall }
    end

    def mock!
      @servers.map! {|s| Mock.new }
      @bucket2server.keys.each_with_index do|k,i|
        @bucket2server[k] = @servers[i % @servers.size]
      end
    end

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
