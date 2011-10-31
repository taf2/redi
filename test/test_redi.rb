require 'test/unit'
require 'redi'
require 'yaml'

TEST_CONFIG = %(
  - :host: 127.0.0.1
    :port: 6379
    :db: 14
    :buckets: 0-64
  - :host: 127.0.0.1
    :port: 6379
    :db: 15
    :buckets: 65-127
)

class TestRedi < Test::Unit::TestCase

  def setup
    Redi.config = YAML.load( TEST_CONFIG )
    Redi.flushall
  end

  def teardown
    Redi.flushall
  end

  def test_redis_pool
    redis = Redi.pool.redis_by_key('me:foo:1')
    assert_equal "n25", redis.namespace
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
  end
end
