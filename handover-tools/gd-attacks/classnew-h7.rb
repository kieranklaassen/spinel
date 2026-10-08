module Net
  class Error < StandardError; end
end
module Disk
  class Error < StandardError; end
end
Error = Struct.new(:code)
begin
  raise Net::Error, "x"
rescue => e
  p [(e.is_a?(Error) rescue :ne), e.is_a?(Net::Error), e.is_a?(Disk::Error)]
end
