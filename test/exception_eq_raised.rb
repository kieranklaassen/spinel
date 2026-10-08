# Exception#== compares the backtrace along with the class and the message.
# An exception that was raised has one and one that never was has nil, so
# the two are not equal, whatever their messages.

def rescued(m)
  raise RuntimeError, m
rescue => e
  e
end

fresh = RuntimeError.new("ab")
r = rescued("ab")
puts "raised against never raised: #{r == fresh}"
puts "never raised against raised: #{fresh == r}"
puts "not equal: #{r != fresh}"
puts "never raised, both: #{fresh == RuntimeError.new("ab")}"
puts "itself: #{r == r}"
puts "its copy: #{r == r.dup}"
puts "its copy with the same message: #{r == r.exception("ab")}"
puts "raised at one place twice: #{rescued("ab") == rescued("ab")}"
puts "in an Array: #{[r].include?(fresh)} #{[fresh].include?(r)} #{[r].include?(r)}"
puts "its index: #{[fresh, r].index(r)}"
puts "Arrays of them: #{[r] == [fresh]} #{[fresh] == [RuntimeError.new("ab")]}"

# an object made, then raised
made = RuntimeError.new("ab")
begin
  raise made
rescue
end
puts "made, then raised: #{made == fresh}"

# a copy that is raised
first = RuntimeError.new("first")
begin
  raise first.exception("a\0b")
rescue => f
  puts "a raised copy: #{f == RuntimeError.new("a\0b")}"
end

# an attached backtrace is compared by its lines
k = RuntimeError.new("ab")
k.set_backtrace(["x:1"])
m = RuntimeError.new("ab")
m.set_backtrace(["x:1"])
n = RuntimeError.new("ab")
n.set_backtrace(["y:2"])
puts "attached against none: #{k == fresh}"
puts "attached, the same lines: #{k == m}"
puts "attached, other lines: #{k == n}"

# and can be taken away again
z = rescued("ab")
z.set_backtrace(nil)
puts "raised, its backtrace taken away: #{z == fresh}"

# a class of the program, with a variable of its own
class Own < StandardError
  def initialize(m, code)
    super(m)
    @code = code
  end
end
o = Own.new("ab", 1)
puts "own, never raised: #{o == Own.new("ab", 1)}"
begin
  raise o
rescue Own => x
  puts "own, raised: #{x == Own.new("ab", 1)} #{x == o}"
end

# raised in a thread, and again by join
t = Thread.new do
  Thread.current.report_on_exception = false
  raise RuntimeError, "ab"
end
begin
  t.join
rescue => joined
  puts "from a thread: #{joined == fresh}"
end

# a frozen exception takes no backtrace: raised or not, it equals one that
# never was, and so does its copy
frozen = IOError.new("ab").freeze
begin
  raise frozen
rescue => caught
  puts "frozen, raised: #{caught == IOError.new("ab")} #{frozen.dup == IOError.new("ab")}"
end
