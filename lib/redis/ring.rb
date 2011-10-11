require 'rubygems' if __FILE__ == $0
require 'zlib'
require 'yaml'
require 'redis'
require 'redis/hash_ring'
require 'redis/namespace'

class Redis
class Ring

  def self.get(key)
    pool.redis_by_key(key).get(key)
  end

  def self.set(key, val)
    pool.redis_by_key(key).set(key, val)
  end

  def self.pool
    @pool ||= Pool.new(self.config) #Redis.new(self.config)
  end

  def self.config
    @config ||= YAML.load_file(File.join(RAILS_ROOT,'config/me.yml'))[RAILS_ENV]
  end

  # provide a key to name to host:port mapping
  #
  #  should have a larger keyspace than servers, this allows scaling up the servers without changing the keyspace mapping
  #
  # sample configuration:
  #
  # :keyspace:
  #   - :n0: 0
  #   - :n1: 1
  #   - :n2: 0
  #   - :n3: 1
  #   - :n4: 0
  # :servers:
  #   - :host:
  #     :port:
  #     :db:
  #   - :host:
  #     :port:
  #     :db:
  #
  class Pool
    attr_reader :keyspace, :servers
    def initialize(config)
      @key_type = Struct.new(:id, :to_s)
      keyspace = config[:keyspace]

      # create bucket set
      @buckets = keyspace.each_with_index.map {|k,i| @key_type.new(i, k.keys.first) }

      # build server pool
      @servers = config[:servers].map {|cfg| Redis.new(cfg) }

      # create the mapping from bucket to server
      @bucket2server = {}
      keyspace.each do|ks|
        @bucket2server[ks.keys.first] = @servers[ks.values.first]
      end

      # create the keyring to map redis keys to buckets
      @keyring  = Redis::HashRing.new(@buckets)
    end

    def redis_by_key(key)
      bucket = @keyring.get_node(key)
      Redis::Namespace.new(bucket.to_s, :redis => @bucket2server[bucket.to_s])
    end

  end

  class Mock
    def initialize
      @store = {}
    end

    def get(key)
      @store[key]
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
end

if __FILE__ == $0
require 'rubygems'
require 'test/unit'

TEST_CONFIG = %(
  :keyspace:
    - :n0: 0
    - :n1: 1
    - :n2: 0
    - :n3: 1
    - :n4: 0
    - :n5: 1
    - :n6: 0
    - :n7: 1
    - :n8: 0
    - :n9: 1
    - :n10: 0
    - :n11: 1
    - :n12: 0
    - :n13: 1
    - :n14: 0
    - :n15: 1
    - :n16: 0
    - :n17: 1
    - :n18: 0
    - :n19: 1
    - :n20: 0
    - :n21: 1
    - :n22: 0
    - :n23: 1
    - :n24: 0
    - :n25: 1
    - :n26: 0
    - :n27: 1
    - :n28: 0
    - :n29: 1
    - :n30: 0
    - :n31: 1
    - :n32: 0
  :servers:
    - :host: 127.0.0.1
      :port: 6379
      :db: 0
    - :host: 127.0.0.1
      :port: 6379
      :db: 1
)
  class TestIt < Test::Unit::TestCase

    def test_redis_pool
      pool = Redis::Ring::Pool.new(YAML.load(TEST_CONFIG))
      redis = pool.redis_by_key('me:foo:1')
      assert_equal :n25, redis.namespace
      redis.flushall
      redis.set("me:foo:1", "hello")
      assert_equal "hello", redis.get("me:foo:1")
    end

    def test_using_hash_ring_strategy
      return
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
