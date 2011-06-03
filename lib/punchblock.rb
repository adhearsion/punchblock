$LOAD_PATH.unshift(File.dirname(__FILE__))
%w{
punchblock/call
punchblock/dsl
punchblock/protocol/ozone
core_ext/nokogiri_hash
}.each { |f| require f }

##
# This exception may be raised if a transport error is detected.
TransportError = Class.new StandardError
