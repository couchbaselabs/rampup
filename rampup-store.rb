#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'rubygems'

class Store
  def connect(target, cfg)
  end

  def command(cmd, key_num, key_str, data, bulk_load_batch = 1)
    out("#{cmd} #{key_num} #{key_str} #{data}\n")
  end

  def flush()
  end

  def gen_doc(key_num, key_str, min_value_size)
    gen_doc_string(key_num, key_str, min_value_size)
  end

  def cmd_line_get(key_num, key_str)
    return key_str
  end
end

class StoreCouchDB < Store
  def connect(target, cfg) # host:port
    @target = target
    @http = Net::HTTP.new(target.split(':')[0],
                          target.split(':')[1].to_i)
    @bulk = {}
    @num_vbuckets = cfg.num_vbuckets
  end

  def command(cmd, key_num, key_str, data, bulk_load_batch = 1)
    partition = ""
    if @num_vbuckets > 1
      partition = "%2F#{key_num.modulo(@num_vbuckets)}"
    end

    case cmd
    when :get
      uri = URI.parse("http://#{@target}/default#{partition}/#{key_str}")
      request = Net::HTTP::Get.new(uri.request_uri)
      return @http.request(request)
    when :set
      if bulk_load_batch > 1
        @bulk[partition] ||= []
        @bulk[partition] << data
        if @bulk[partition].length > bulk_load_batch
          flush
        end
      else
        uri = URI.parse("http://#{@target}/default#{partition}/#{key_str}")
        request = Net::HTTP::Put.new(uri.request_uri)
        request.body = data
        return @http.request(request)
      end
    else
      print("ERROR: unknown StoreCouchDB cmd: #{cmd}\n")
      exit(-1)
    end
  end

  def flush()
    @bulk.each_pair do |partition, docs|
      uri = URI.parse("http://#{@target}/default#{partition}/_bulk_docs")
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = "application/json"
      request.body = "{\"docs\":[#{docs.join(',')}]}"
      @http.request(request)
    end

    @bulk = {}
  end

  def gen_doc(key_num, key_str, min_value_size)
    gen_doc_string(key_num, key_str, min_value_size, key_name = "_id")
  end

  def cmd_line_get(key_num, key_str)
    partition = ""
    if @num_vbuckets > 1
      partition = "%2F#{key_num.modulo(@num_vbuckets)}"
    end

    return "curl http://#{@target}/default#{partition}/#{key_str}"
  end
end

class StoreMemCache < Store
  require 'memcache'

  def connect(target, cfg) # host:port
    @target = target
    @conn   = MemCache.new([target])
  end

  def command(cmd, key_num, key_str, data, bulk_load_batch = 1)
    case cmd
    when :get
      return @conn.get(key_str)
    when :set
      return @conn.set(key_str, data, 0, true) # Raw is true.
    else
      print("ERROR: unknown StoreMemCache cmd: #{cmd}\n")
      exit(-1)
    end
  end

  def cmd_line_get(key_num, key_str)
    return "echo get #{key_str} | nc #{@target.split(':').join(' ')}"
  end
end

class StoreDalli < Store
  require 'dalli'

  def connect(target, cfg) # host:port
    @target = target
    @conn   = Dalli::Client.new([target])
    @opts   = { :raw => true }
  end

  def command(cmd, key_num, key_str, data, bulk_load_batch = 1)
    case cmd
    when :get
      return @conn.get(key_str)
    when :set
      return @conn.set(key_str, data, nil, @opts)
    else
      print("ERROR: unknown StoreDalli cmd: #{cmd}\n")
      exit(-1)
    end
  end

  def cmd_line_get(key_num, key_str)
    return "echo get #{key_str} | nc #{@target.split(':').join(' ')}"
  end
end

class StoreMongo < Store
  # sudo gem install mongo
  # sudo gem install bson
  # sudo gem install bson_ext
  # sudo gem install SystemTimer

  require 'mongo'

  def connect(target, cfg) # host:port/dbName/collName
    hp, dbName, collName = target.split('/')
    @host = (hp.split(':')[0] || 'localhost')
    @port = (hp.split(':')[1] || '27017').to_i
    @dbName   = dbName   || 'test'
    @collName = collName || 'test'

    @conn = Mongo::Connection.new(@host, @port, :safe => true)
    @db   = @conn.db(@dbName)
    @coll = @db.collection(@collName)
  end

  def command(cmd, key_num, key_str, data, bulk_load_batch = 1)
    case cmd
    when :get
      return @coll.find_one({"_id" => key_str})
    when :set
      return @coll.update({"_id" => key_str}, data, {:upsert => true})
    else
      print("ERROR: unknown StoreMongo cmd: #{cmd}\n")
      exit(-1)
    end
  end

  def gen_doc(key_num, key_str, min_value_size)
    gen_doc_hash(key_num, key_str, min_value_size)
  end
end

