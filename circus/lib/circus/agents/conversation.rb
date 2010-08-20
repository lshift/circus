module Circus
  module Agents
    class Conversation
      CHAT_STATES = 'http://jabber.org/protocol/chatstates'
    
      def self.end(m)
        gone_el = Nokogiri::XML::Element.new('gone', m.document)
        gone_el.default_namespace = CHAT_STATES
        m << gone_el
      end
    
      def self.ended?(m)
        m.xpath('ns:gone', 'ns' => CHAT_STATES).length > 0
      end
    end
  end
end