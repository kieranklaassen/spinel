module Net; class Error < StandardError; end; end
class Plain < StandardError; end
Error = Plain
module Disk; def self.plain?(e) = e.is_a?(Error); end
begin
  raise Net::Error, "x"
rescue => e
  p Disk.plain?(e)
end
begin
  raise Plain, "x"
rescue => e
  p Disk.plain?(e)
end
