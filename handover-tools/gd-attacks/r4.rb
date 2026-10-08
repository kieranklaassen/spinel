class Wrap; class Error < StandardError; end; end
class Plain < StandardError; end
Error = Plain
begin
  raise Wrap::Error, "x"
rescue => e
  p e.is_a?(Error), e.is_a?(Wrap::Error)
end
