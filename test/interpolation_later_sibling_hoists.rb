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
