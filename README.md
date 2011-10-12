Redi
----------

Pooled redis puts a layer of indirection between server pool and key ring


The idea comes from http://blog.zawodny.com/2011/02/26/redis-sharding-at-craigslist/

    gem install redi

Create a configuration file:

    development:
      - :host: 192.168.0.10
        :port: 6379
        :db: 0
        :buckets: 0 - 64
      - :host: 192.168.0.11
        :port: 6380
        :db: 0
        :buckets: 65 - 127

The configuration should look like a normal redis configuration with the addition of a buckets key.  This tells redi how many buckets it should
hash keys to before mapping them to the configured server.  In the example above, it would be possible to scale those 2 servers up to 128 servers without 
rekeying, you can follow the 5 steps below to add a new server each time.

1. create new server
2. identify buckets to move to new server
3. setup new server as slave to replicate
4. update configuration to point buckets to new server
5. use bucket key prefixes to prune old keys from old server.
