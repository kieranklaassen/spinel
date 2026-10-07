# What is written after an interpolation in the same statement can hoist
# its operands ahead of the statement. Where it does, the interpolation's
# own operands stay ahead of the statement too, before them: kept in the
# part's place they would run after what was written later.
class C
  def initialize = @n = 0
  def nxt = (@n += 1)
  def two(a, b) = a * 10 + b
end
def pair(a, b) = [a, b]

# a later link of a `<<` chain
c = C.new
buf = +""
buf << "#{c.two(0, 0)} #{c.two(c.nxt, 0)} " << c.two(c.nxt, 0).to_s
puts buf

# the values of a case's whens: beside the subject, in one list, with no subject
c = C.new
p(case "#{c.two(0, 0)} #{c.two(c.nxt, 0)}" when c.two(c.nxt, 0).to_s then 1 when "0 10" then 2 else 3 end)
c = C.new
p(case "20" when "#{c.two(0, 0)} #{c.two(c.nxt, 0)}", c.two(c.nxt, 0).to_s then 1 else 2 end)
c = C.new
p(case when "#{c.two(0, 0)} #{c.two(c.nxt, 0)}" == "0 20" then 1 when c.two(c.nxt, 0) == 20 then 2 else 3 end)

# a later part of the interpolation around this one
c = C.new
n = 0
p pair("#{"#{c.two(0, 0)} #{c.two(c.nxt, 0)}"} #{c.two(c.nxt, 0)}#{n += 1}", n)

# a read of an instance variable beside the interpolation, written by a
# default argument a part's call evaluates
class M
  def initialize = @n = 0
  def pure(x) = x
  def tw(a, b) = a * 10 + b
  def step(a = (@n += 1)) = a
  def key(a: (@n += 1)) = a
  def run = "#{pure(1)}#{tw(step, 2)}" * (@n + 1)
  def pad = "#{pure(1)}#{tw(key, 2)}".center(@n + 12, "*")
end
p M.new.run, M.new.pad

# ...or written where a walk of the callee does not look: a method made by
# define_method, an attribute's operator write
class N
  attr_accessor :n
  def initialize = @n = 1
  def pure(x) = x
  def tw(a, b) = a * 10 + b
  define_method(:step) { @n += 1 }
  def down = (self.n -= 1; 1)
  def run = "#{pure(1)}#{tw(step, 2)}" * (@n + 1)
  def pad = "#{pure(1)}#{tw(down, 2)}".center(@n + 5, "-")
end
p N.new.run, N.new.pad

# an operation beside the interpolation that raises: the parts' operands
# have run by then
$log = []
def lg(x) = ($log << x; x)
c = C.new
z = ARGV.size
begin
  p "#{c.two(0, lg(1))} #{c.two(0, lg(2))}" * (10 / z)
rescue ZeroDivisionError
  $log << :zde
end
p $log
