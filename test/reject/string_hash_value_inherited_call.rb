# The store is in a subclass's method, called on self by the method the
# subclass inherits.
class Plain
  def run(h); fill(h); end
  def fill(h); h.size; end
end
class Namer < Plain
  def fill(h); h[:a] = +"q"; end
end
h = {}
Namer.new.run(h)
h.each_value { |x| x << "!" }
p h
