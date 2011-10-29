Redi
----------

Pooled redis, add a layer of indirection between server pool and key ring

The idea comes from http://blog.zawodny.com/2011/02/26/redis-sharding-at-craigslist/

- - -
Install
----------
    gem install redi

Configure
----------
The configuration should look like a normal redis configuration with the addition of a buckets key.
This tells redi how many buckets it should hash keys to before mapping them to the configured server.

redi.yml:

    development:
      - :host: 192.168.0.10
        :port: 6379
        :db: 0
        :buckets: 0 - 64
      - :host: 192.168.0.11
        :port: 6380
        :db: 0
        :buckets: 65 - 127

In the example above, it is possible to scale the 2 configured servers up to 128 servers without 
re-keying.
- - -

Adding a new server can be done as follows:

* start a new server process, call it r3.
* identify buckets to move to r3 from existing server r2.
* setup r3 as slave to replicate from r2.
* update configuration to point buckets to r3

<pre>
     production:
       - :host: 192.168.0.10 # r1
         :port: 6379
         :db: 0
         :buckets: 0 - 64
       - :host: 192.168.0.11 # r2
         :port: 6380
         :db: 0
         :buckets: 65 - 95
       - :host: 192.168.0.11 # r3
         :port: 6380
         :db: 0
         :buckets: 96 - 127
</pre>

* use bucket key prefixes to prune old keys from r2.

  How you do this can vary depending on your application, but something like the pseudo code below is the idea:

       96..127.times do|i| # NOTE: using redis here not redi as we want to talk to r2 explicitly
         redis.del(redis.keys("n#{i}*"))
       end
