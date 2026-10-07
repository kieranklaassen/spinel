# `when pa` in a case statement, for an arm of the subject's own class that
# defines == (taking its own class) and no ===. Object#=== is rb_equal: the
# same object matches before == is called, an equal one through it. The
# case value tested the same object first; the statement called ==.

class P
  attr_accessor :v
  def initialize(v, log)
    @v = v
    @log = log
  end
  def ==(o)
    @log << :peq
    o.v == @v
  end
end

class Never
  attr_reader :n
  def initialize(n) = @n = n
  def ==(o) = o.n > 1_000_000
end

def show(log, v)
  p [v, log.size]
  log.clear
end

plog = []
pa = P.new(1, plog)
pb = P.new(1, plog)
pc = P.new(2, plog)
pc.v = 3
show(plog, pa == pb)

# the same object: no call
case pa
when pa then show(plog, :same)
else show(plog, :none)
end

# an equal one: through ==
case pb
when pa then show(plog, :equal)
else show(plog, :none)
end

# another: == is asked and says no
case pc
when pa then show(plog, :wrong)
else show(plog, :none)
end

# a list: each arm in order, the same object found without a call
case pa
when pc, pa then show(plog, :second)
else show(plog, :none)
end

# inside a method
def pick(s, a, log)
  case s
  when a then show(log, :hit)
  else show(log, :miss)
  end
end
pick(pa, pa, plog)
pick(pc, pa, plog)

# an == that never answers true: only the same object matches
na = Never.new(1)
nb = Never.new(2)
p(na == nb)
case na
when nb then puts "nb"
when na then puts "na"
else puts "none"
end
