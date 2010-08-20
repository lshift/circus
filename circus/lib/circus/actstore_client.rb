module Circus
  class ActStoreClient
    def initialize(root, logger)
      @root = root
      @logger = logger
    end
    
    def upload_act(fn)
      actname = File.basename(fn)
      upload_url = "#{@root}/#{actname}"
      
      @logger.info "Uploading to #{upload_url}"
      uri = URI.parse(upload_url)
      
      res = Net::HTTP.start(uri.host, uri.port) do |http|
        req = Net::HTTP::Put.new(uri.request_uri)
        req.body = File.read(fn)
        req.content_type = 'application/binary'
        
        http.request req
      end
      unless res.is_a? Net::HTTPSuccess
        @logger.error "FAILED: Act Upload"
        @logger.error "  Status:   #{res.code}"
        @logger.error "  Response: #{res.body}"
        return false
      end
    end
  end
end