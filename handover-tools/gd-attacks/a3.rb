module Net
  class Error < StandardError; end
end
class Plain < StandardError; end
module Other
  Error = Plain
end
begin
  raise Net::Error, "x"
rescue => e
  p e.is_a?(Other::Error), e.is_a?(Net::Error)
end
