# The Hash is an instance variable's: its stores are the class's.
class K
  def initialize; @h = {}; end
  def add(v); @h[:a] = v; end
  def go; @h.each_value { |x| x << "!" }; p @h; end
end
k = K.new
k.add(+"q")
k.go
