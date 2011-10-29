class Redi

  def self.mock!
    pool(true).mock!
  end

  class Pool

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
