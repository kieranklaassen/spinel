# A default the call leaves out, in a method reached through a boxed
# receiver's dispatch, runs in the arm of the class that owns it: what the
# default builds reads that arm's receiver, and no other arm runs it.

$n = 0
def tick = ($n += 1)

class Symbol
  def note(k = [self]) = "sym #{k.inspect}"
end

class Range
  def note(k = first) = "rng #{k.inspect}"
  # each default goes its own way: a reads the receiver, b only builds, c runs
  def pair(a = [last], b = [2], c = [tick]) = "pair #{a.inspect} #{b.inspect} #{c.inspect}"
end

class Tk
  def to_s = "tk"
  def note(k = [to_s, tick]) = "tk #{k.inspect}"
end

class Other
  def note = "other"
  def pair = "other pair"
end

[:abc].each { |x| puts x.note }
[(1..3)].each { |x| puts x.note }
[Tk.new, Other.new, Other.new].each { |x| puts x.note }
p $n
x = ARGV.size > 5 ? Other.new : :loc
puts x.note
def show(x) = x.note
puts show(4..6)
puts show(Other.new)
puts show(Tk.new)
p $n
[(1..3), Other.new].each { |x| puts x.pair }
p $n
puts show(7..9)
