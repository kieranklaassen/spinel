# A call's result is held while a sibling operand is made where it stands: an
# interpolated String, an empty Hash or Array. The two are a C call's
# arguments, which C evaluates in either order; whichever ran second could
# collect the other.

def label(n)
  s = ""
  30000.times { |i| s = "q#{i % 1000}" }
  "s#{n % 1000}t"
end

# the argument is made first by gcc, and label allocates enough to collect
wrong = 0
20.times { |n| wrong += 1 unless label(n).include?("s#{n % 1000}") }
p wrong

def any(n)
  return 1 if n > 5
  return "s" if n > 6
  {"a#{n}" => n}
end

def anya(n)
  return 1 if n > 5
  return "s" if n > 6
  ["a#{n}", n]
end

def mk(n) = {"a#{n}" => n, "b" => 2}
def ms(n) = "s#{n}t"

n = ARGV.size + 1
o = n > 5 ? {"z" => 1} : nil

p ms(1).include?("s#{n}"), ms(1).start_with?("s#{n}"), ms(1).index("#{n}")
p ms(1).split("#{n}"), ms(1).tr("#{n}", "z"), ms(1).center(9, "#{n}")
p mk(1).key?("a#{n}"), any(1).fetch("a#{n}"), anya(1).join("-#{n}-")
p anya(1).insert(0, "x#{n}"), anya(1).insert(0, {}), anya(1).insert(0, [])
p any(1).merge({}).to_a, any(1).merge({}).merge({}).to_a, any(1).dup.merge({}).to_a
p mk(1).merge(o || {}).to_a, any(1).merge(o || {"k" => "v"}).to_a
# the made operand first, the call second
p "s#{n}t" == ms(1), "as#{n}tb".include?(ms(1)), "a#{n}" + ms(1)

# Ruby runs the receiver before the argument: the String reads what the call
# stored. One written ahead of the call reads what was there before it.
class Box
  def initialize = @n = 1

  def bump
    @n += 1
    "s#{@n}t"
  end

  def seen = bump.include?("#{@n}")
  def ahead = "#{@n}" + bump
end
p Box.new.seen, Box.new.ahead

# ...and so does one that reads a local the call changes in place
def app(t)
  t << "x"
  t
end

def add(a)
  a << 3
  "3"
end

s = +"ab"
p "#{s}-" + s.concat("x"), "#{s}-" + app(s), "<#{s}>" + s.replace("zz")
p "#{s}".eql?(s.upcase!), s
a = [1, 2]
p "#{a}" + add(a)

# ...or that runs a to_s of the program's own
class Tag
  def to_s
    $log << "to_s"
    "tag"
  end
end

def noisy(n)
  $log << "call"
  "s#{n}t"
end

$log = []
t = Tag.new
p "#{t}-" + noisy(1), $log

# ...or that raises: the call has not run
z = ARGV.size
begin
  p "#{10 / z}-" + noisy(2)
rescue ZeroDivisionError
  p $log
end

# Left as they were. A String its method appends to is read by its arm, where
# the arm reads it: bound ahead of that, the call that assigns the variable
# ran first.
def rebound(n, s)
  s << "a"
  l = -> { s = +"b"; "b" }
  s.start_with?("z#{n}", l.call)
end

def rebound_arg(n, s)
  s << "a"
  l = -> { s = +"zzzz"; "b" }
  "abcabc#{n}".delete(s, l.call)
end
p rebound(1, +"abc"), rebound_arg(1, +"b")

class Kept
  attr_reader :label

  def initialize
    @i = 0
    @label = "s1t"
  end

  def bump
    @i += 1
    "a"
  end

  def ms(n) = "s#{n}t"
  def maybe(n) = n > 5 ? nil : "s#{n}t"
  def arr(n) = ["a#{n}", "b"]

  # ...and so is an operand computed ahead of the call from what it changes
  def ahead(n) = "q#{n}".start_with?(@i > 0 ? "q" : "z", bump)
  def ahead_set(n) = "abcabc#{n}".delete(@i > 0 ? "a-c" : "a-b", bump + "-c")

  # Nothing to hold in these: the Makefile's infer-test reads their C.
  # a `&.` call's receiver is held by its guard
  def guarded(n) = maybe(n)&.include?("s#{n}")
  # a reader runs nothing
  def reader(n) = label.include?("s#{n}")
  def named(o, n) = o.label.include?("s#{n}")
  # an empty literal the arm folds away is never made
  def folded(n) = arr(n) == []
  # an arm that holds its receiver itself
  def compared(n) = ms(n) <=> "s#{n}"
end

k = Kept.new
p k.ahead(1), k.ahead_set(1)
p k.guarded(1), k.reader(1), k.named(k, 1), k.folded(1), k.compared(1)
