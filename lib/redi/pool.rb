require 'rubygems'

require 'redis'
require 'redis/hash_ring'
require 'redis/namespace'

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
class Redi
  class Pool
    attr_reader :keyspace, :servers
    def initialize(config)
      key_type = Struct.new(:id, :to_s)

      # build server pool
      @bucket2server = {}
      buckets = []
      @servers = config.map {|cfg|
        bucket_range = cfg.delete(:buckets)
        s, e = bucket_range.split('-').map {|n| n.to_i }
        conn = Redis.new(cfg)
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

    def flushdb
      @servers.each {|s| s.flushdb }
    end

  end
end
