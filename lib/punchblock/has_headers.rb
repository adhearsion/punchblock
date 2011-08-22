module Punchblock
  module HasHeaders
    ##
    # @return [Hash] hash of key-value pairs of headers
    #
    def headers_hash
      headers.inject({}) do |hash, header|
        hash[header.name] = header.value
        hash
      end
    end

    ##
    # @return [Array[Header]] headers
    #
    def headers
      find('//ns:header', :ns => self.class.registered_ns).map do |i|
        Header.new i
      end
    end

    ##
    # @param [Hash, Array] headers A hash of key-value header pairs, or an array of Header objects
    #
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
