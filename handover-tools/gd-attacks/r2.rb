module Net; class Error < StandardError; end; end
class Plain < StandardError; end
Error = Plain
begin
  raise Net::Error, "x"
rescue => e
  p e.kind_of?(Error), e.instance_of?(Error)
end
