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

The keyspace mapping is very important.  It helps you manage the exact mapping of buckets to servers and is how you can scale from 2 severs to 16.
In the example, you have 16 buckets that map evenly to 2 servers.  If you decide you need more memory (more severs) you can choose a segment of your
buckets to replicate to a new server.  

1. create new server
2. identify buckets to move to new server
3. setup new server as slave to replicate
4. update configuration to point buckets to new server
5. prune old keys from old server freeing up more space on old server using a keys nsxx* query
