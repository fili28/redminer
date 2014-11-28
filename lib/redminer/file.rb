module Redminer
  class File

    attr_accessor :file, :server

    def initialize(server, file)
      @server = server
      @file = file
    end

    def upload
      upload_url = URI::join(server.uri.to_s, "/uploads.json")
      upload_url_with_key = "#{upload_url.to_s}?key=#{server.access_key}"
      
      RestClient.post(upload_url_with_key, file, { :multipart => true, :content_type => 'application/octet-stream'}) 
    end
  end
end