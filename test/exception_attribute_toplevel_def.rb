# A def at the top level is Object's, so every exception answers to it,
# and CRuby calls some on its own: to_ary where an Array is flattened. The
# attribute it stores a zero in reads that zero.
class Counted < StandardError
  attr_accessor :count
end
def to_ary
  @count = 0
  nil
end
e = Counted.new("m")
p [e].flatten.size
p e.count
begin
  raise Counted, "r"
rescue Counted => x
  p [[x]].flatten.size
  p x.count, x.message
end
