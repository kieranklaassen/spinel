module Lib
  class Addrinfo < StandardError; end
end
begin
  raise Lib::Addrinfo, "x"
rescue => e
  p e.class
end
