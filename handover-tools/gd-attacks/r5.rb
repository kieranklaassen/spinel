module Net; class Error < StandardError; end; end
Error = Class.new(StandardError)
begin
  raise Net::Error, "x"
rescue => e
  p e.is_a?(Error), e.is_a?(Net::Error)
end
