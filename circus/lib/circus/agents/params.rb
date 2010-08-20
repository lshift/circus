require 'circus/agents/encoding'

module Circus
  module Agents
    class CommandParams
      def initialize(str)
        @params = if str
          Encoding.decode(str)
        else
          {}
        end
      end
    
      def required(*names)
        res = names.map do |n|
          raise MissingParameterException.new(n) unless @params.has_key? n
        
          @params[n]
        end
        format_result(res)
      end
    
      def optional(*names)
        res = names.map do |n|
          if  @params.has_key? n
            @params[n]
          else
            nil
          end
        end
        format_result(res)
      end
      
      private
        def format_result(result)
          return result.first if result.length == 1
          result
        end
    end
  
    class MissingParameterException < ArgumentError
      def initialize(name)
        super("missing parameter #{name}")
      end
    end
  end
end