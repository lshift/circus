require 'cgi'

module Circus
  module Agents
    class Encoding
      def self.encode(params, sep = '&')
        params.map do |k,v|
          if v.is_a? Array
            v.map do |iv|
              "#{CGI.escape(k.to_s)}=#{CGI.escape(iv.to_s)}"
            end.join(sep)
          else
            "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}"
          end
        end.join(sep)
      end
    
      def self.decode(str)
        parsed = CGI::parse(str)
        result = {}
        parsed.each do |k, v|
          if v.length == 1
            result[k] = v.first
          else
            result[k] = v
          end
        end
        result
      end
    end
  end
end