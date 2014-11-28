module Redminer
  class Server
    attr_accessor :http, :access_key, :uri
    attr_accessor :verbose, :reqtrace

    def initialize(host, access_key, options = {})

      @uri = URI.parse(host)
      @http = Net::HTTP.new(@uri.host, @uri.port)
      @http.use_ssl = true  if @uri.scheme == 'https'

      @access_key = access_key
      @verbose = options[:verbose]
      @reqtrace = options[:reqtrace]
    end

    def request(path, params = nil, obj = Net::HTTP::Get)
      puts "requesting... #{http.address}:#{http.port}#{path} by #{obj}" if verbose
      Rails.logger.info("requesting... #{http.address}:#{http.port}#{path} by #{obj}")
      puts caller.join("\n  ") if reqtrace
      req = obj.new(path)
      req.add_field('X-Redmine-API-Key', access_key)
      req.body = hash_to_querystring(params) if not params.nil? and not params.empty?
      begin
        if block_given?
          yield http.request(req)
        else
          response = http.request(req)
          if response.code != "200"
            raise "fail to request #{response.code}:#{response.message}"
          end
          return {} if response.body.nil? or response.body.strip.empty?
          JSON.parse(response.body)
        end
      rescue Timeout::Error => e
        raise e, "#{http.address}:#{port} timeout error", e.backtrace
      rescue JSON::ParserError => e
        raise e, "response json parsing error", e.backtrace
      end
    end

    def hash_to_querystring(hash)
      hash.keys.inject('') do |query_string, key|
        value = case hash[key]
          when Hash then hash[key].to_json
          else hash[key].to_s
        end
        query_string << '&' unless key == hash.keys.first
        query_string << "#{URI.encode(key.to_s)}=#{URI.encode(value)}"
      end
    end

    def get(path, params = nil, &block); request(path, params, &block) end
    def post(path, params = nil, &block); request(path, params, Net::HTTP::Post, &block) end
    def delete(path, params = nil, &block); request(path, params, Net::HTTP::Delete, &block) end
    def put(path, params = nil, &block)
      url = URI::join(@uri.to_s, path)
      params = params.merge(:key => @access_key)
      RestClient.put url.to_s, params.to_json, :content_type => :json, :accept => :json
    end

    def current_user
      Redminer::User.current(self)
    end

    def working?
      begin
        current_user and true
      rescue
        false
      end
    end

    def issue(issue_key = nil)
      Redminer::Issue.new(self, issue_key)
    end
  end
end
