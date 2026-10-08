# A bare name in is_a?, kind_of? and instance_of? on a rescued exception is
# what Ruby binds it to: `Error = Plain` at the program's level is not the
# Net::Error nested in a module, though no other class has that leaf. Nor is
# another module's constant of the name.
module Net
  class Error < StandardError; end
end
class Plain < StandardError; end
Error = Plain
module Other
  Error = Plain
end

begin
  raise Net::Error, "down"
rescue => e
  p [e.is_a?(Error), e.kind_of?(Error), e.instance_of?(Error)]
  p [e.is_a?(Other::Error), e.is_a?(Net::Error), e.is_a?(Plain)]
  puts(e.is_a?(Error) ? "plain" : "net")
end
