# A frozen exception takes no backtrace when it is raised: its #backtrace
# stays nil, as it is for an exception that was never raised.

e = IOError.new("ab").freeze
begin
  raise e
rescue => r
  p r.backtrace
  p r.equal?(e)
end
p e.backtrace

# raised again and again, the way a constant error is
STOP = RuntimeError.new("stop").freeze
3.times do
  begin
    raise STOP
  rescue RuntimeError => s
    p s.backtrace
  end
end

# rescued by a clause that binds nothing, and by a method's rescue
def twice(x)
  raise x
rescue IOError
  x.backtrace
end
p twice(e)

# a class of the program
class Own < StandardError
  def initialize(m, code)
    super(m)
    @code = code
  end
end
o = Own.new("ab", 7).freeze
begin
  raise o
rescue Own => c
  p c.backtrace
end

# a backtrace attached before it was frozen stays
k = IOError.new("ab")
k.set_backtrace(["x:1"])
k.freeze
begin
  raise k
rescue => r
  p r.backtrace
end

# an exception that is not frozen takes one
begin
  raise IOError, "ab"
rescue => r
  p r.backtrace.class
end
u = IOError.new("ab")
begin
  raise u
rescue => r
  p u.backtrace.class
end
