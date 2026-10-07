# A class's own then and yield_self, called with no block, run and answer for
# its objects where the receiver cannot be nil as written (a new object, a
# local that only ever holds one, a read behind a guard, `&.`) and when the
# value is read out of a mixed Array, whether or not the value is used; every
# other value, nil in a typed slot too, keeps the Enumerator, and the block
# form its block.
class Job
  def then = :job_then
  def yield_self = :job_yield_self
end
class Sub < Job; end
module Chained
  def then = :chained
end
class Link
  include Chained
end
class Step
  attr_reader :then
  def initialize(nxt) = @then = nxt
end
class Plain; end
class Tally
  def initialize = @n = 0
  def then
    @n += 1
    self
  end
  def n = @n
end

j = Job.new
p j.then
p j.yield_self
p Sub.new.then
p Link.new.then
s = Step.new(Step.new(nil))
p s.then.class
p s.then&.then

row = [j, Sub.new, Link.new, s, 5, "s", nil, :sym, 2.5, [1], Plain.new]
row.each { |x| p x.then.class }
p row[0].then
p row[0].yield_self
p row[1].then
p row[2].then
p row[3].then.then
p row[0]&.then
p row[6]&.then
v = row[0].then
p v
p row[4].yield_self.class
# with a block the builtin values still take the block's value
p row[4].then { |n| n + 1 }
p row[5].yield_self { |t| t + "!" }
p row[10].then { |o| o.class }
p 5.then { |n| n * 2 }

# called for its effect, the value dropped
t = Tally.new
t.then
p t.n
pair = [t, 5]
pair[0].then
pair[1].then
pair.each { |x| x.then }
p t.n

# a receiver that may be nil: the method runs behind a guard or `&.`, and nil
# keeps Kernel's then
def pick(flag) = flag ? Tally.new : nil
u = pick(true)
p u.then.n if u
p u&.then&.n
q = pick(false)
q.then
p q&.then
p q.nil?
