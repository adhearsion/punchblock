$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'punchblock'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'core_ext'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
%w{
punchblock/call
punchblock/dsl
punchblock/protocol/ozone.rb
punchblock/transport/xmpp.rb
core_ext/nokogiri_hash
}.each { |f| require f }
