# A def on one exception object answers ahead of its class's attribute.
class Counted < StandardError
  attr_accessor :count
end
e = Counted.new("m")
def e.count
  0
end
p e.count
begin
  raise e
rescue Counted => x
  p x.count, x.message
end
