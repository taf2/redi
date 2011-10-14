require 'rubygems' if __FILE__ == $0
require 'zlib'
require 'yaml'
require 'redis'
require 'redis/hash_ring'
require 'redis/namespace'

class Redi

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

if __FILE__ == $0
require 'rubygems'
require 'test/unit'

TEST_CONFIG = %(
  - :host: 127.0.0.1
    :port: 6379
    :db: 0
    :buckets: 0-64
  - :host: 127.0.0.1
    :port: 6379
    :db: 1
    :buckets: 65-127
)
  class TestIt < Test::Unit::TestCase

    def test_redis_pool
      pool = Redi::Pool.new(YAML.load(TEST_CONFIG))
      redis = pool.redis_by_key('me:foo:1')
      assert_equal "n25", redis.namespace
      redis.flushall
      redis.set("me:foo:1", "hello")
      assert_equal "hello", redis.get("me:foo:1")
    end

    def test_using_hash_ring_strategy
      node_class = Struct.new(:id, :to_s)
      buckets = []
      128.times do|i|
        buckets << node_class.new(i, "n#{i}")
      end

      servers = []
      2.times do|i|
        servers << node_class.new(i, "s#{i}") 
      end

      ring1 = Redis::HashRing.new(buckets)

      bucket2server = {}
      buckets.each do|bucket|
        bucket2server[bucket.to_s] = servers[bucket.id % servers.size].to_s
      end

      puts bucket2server.inspect

      servers_used = {}

      buckets_used = {}
      6400.times do|i|
        key = "me:foo#{i}"
        bucket = ring1.get_node(key)
        server = bucket2server[bucket.to_s]#ring2.get_node(name.to_s)
        #puts "#{key} -> #{name} -> #{server}"
        servers_used[ server.to_s ] ||= 0
        servers_used[ server.to_s ] += 1
        buckets_used[ bucket.to_s ] ||= 0
        buckets_used[ bucket.to_s ] += 1
      end
      puts servers_used.inspect
      puts buckets_used.inspect
    end
  end
end
