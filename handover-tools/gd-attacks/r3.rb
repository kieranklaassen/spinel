module Net; class Error < StandardError; end; end
class Plain < StandardError; end
Error = Plain
begin
  raise Net::Error, "x"
rescue => e
  if e.is_a?(Error) then puts "plain" else puts "net" end
end
