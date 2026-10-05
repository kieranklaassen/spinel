# The value of `expr rescue fallback` when expr is always nil and the fallback
# is a Symbol, a String, an Array, an object or true: nil where nothing is
# raised, the fallback where something is, whatever expr is written as and
# wherever the value goes.

def twice
  yield 1
  yield 2
end

def nothing(stop)
  raise "stop" if stop
  nil
end

class Box
  def nothing(stop)
    raise "stop" if stop
    nil
  end

  def to_s = "a box"
end

# a yielding method's call in parentheses
def spliced(stop)
  r = (twice { |x| raise "stop" if stop && x == 2 }) rescue :rescued
  r
end
p spliced(false)
p spliced(true)

# a call in parentheses
def in_parens(stop)
  r = (nothing(stop)) rescue "rescued"
  r
end
p in_parens(false)
p in_parens(true)

# two statements in parentheses
def two_statements(stop)
  seen = []
  r = (seen << 1; nothing(stop)) rescue [0]
  [r, seen]
end
p two_statements(false)
p two_statements(true)

# an `if` with no else
def bare_if(stop)
  r = (raise "stop" if stop) rescue Box.new
  r.nil? ? "nil" : r.to_s
end
puts bare_if(false)
puts bare_if(true)

# a call on a receiver, in parentheses
def on_receiver(stop)
  r = (Box.new.nothing(stop)) rescue [1.5]
  r
end
p on_receiver(false)
p on_receiver(true)

# a begin block
def in_begin(stop)
  r = (begin; nothing(stop); end) rescue { 1 => 2 }
  r.nil? ? "nil" : r.size
end
p in_begin(false)
p in_begin(true)

# a literal nil after a loop: no Symbol of the program stands in for it
def after_each(stop)
  r = ([1, 2].each { |x| raise "stop" if stop && x == 2 }; nil) rescue :rescued
  r
end
p after_each(false)
p after_each(true)

# both arms of a conditional nil
def both_nil(flag)
  r = (flag ? nil : nothing(false)) rescue :rescued
  r
end
p both_nil(true)
p both_nil(false)

# the value used at once
def used_at_once(stop)
  ((nothing(stop)) rescue "rescued").inspect
end
puts used_at_once(false)
puts used_at_once(true)

# a fallback whose type has no nil of its own
def true_fallback(stop)
  r = (nothing(stop)) rescue true
  r
end
p true_fallback(false)
p true_fallback(true)

def range_fallback(stop)
  r = (nothing(stop)) rescue (1..2)
  r
end
p range_fallback(false)
p range_fallback(true)

# the value as an element of an Array
def as_element(stop)
  a = [((nothing(stop)) rescue "rescued"), ((nothing(stop)) rescue "rescued")]
  a[0]
end
p as_element(false)
p as_element(true)

# the value as a lambda's answer
def from_lambda(stop)
  l = lambda { |s| (nothing(s)) rescue :rescued }
  l.call(stop)
end
p from_lambda(false)
p from_lambda(true)

# the value's own inspect, not the fallback's class's
class Loud
  def inspect = "LOUD"
end
def inspected(stop)
  "<#{((nothing(stop)) rescue Loud.new).inspect}>"
end
puts inspected(false)
puts inspected(true)

# locals written before the raise are kept beside the value
def with_locals(stop)
  n = 0
  f = 0.0
  r = (twice { |x| n += x; f += 0.5; raise "stop" if stop && x == 2 }) rescue :rescued
  [r, n, f]
end
p with_locals(false)
p with_locals(true)
