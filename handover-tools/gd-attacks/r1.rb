module Net; class Error < StandardError; end; end
class Plain < StandardError; end
Error = Plain
begin
  raise Net::Error, "x"
rescue => e
  p e.is_a?(Error), e.is_a?(Net::Error), e.is_a?(Plain)
end
