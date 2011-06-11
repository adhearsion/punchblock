module Punchblock
  module Protocol
    module Ozone
      module HasHeaders
        def headers_hash
          headers.inject({}) do |hash, header|
            hash[header.name] = header.value
            hash
          end
        end

        def headers
          find('//ns:header', :ns => self.class.registered_ns).map do |i|
            Header.new i
          end
        end

        def headers=(headers)
          find('//ns:header', :ns => self.class.registered_ns).each &:remove
          if headers.is_a? Hash
            headers.each_pair { |k,v| self << Header.new(k, v) }
          elsif headers.is_a? Array
            [headers].flatten.each { |i| self << Header.new(i) }
          end
        end
      end
    end
  end
end
