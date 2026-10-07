# A String a call takes out of an Array and changes in place is refused
# when the statement's value is dropped (test/reject/
# string_array_find_dropped_append.rb). These are its neighbours, which
# are not: a read the sharing analysis follows, setbyte (it writes the
# byte where the String is), a call whose value is used, and a String the
# call made.
a = [+"q", +"r"]
a.first << "1"
a.dup.last << "2"
a.sort[0].upcase!
p a
a.find { |s| s == "r2" }.setbyte(0, 90)
a.min_by { |s| s.size }.setbyte(1, 90)
p a
y = "a,b".split(",")[0] << "!"
p y
z = ("ab" * 2).clear
p z
n = 0
n += ((+"cd") << "e").size
("ab" * 2).clear
p n
h = { k: +"v" }
h.fetch(:k) << "3"
h[:k] << "4"
p h[:k]
# setbyte again, on an Array nothing has shared
b = [+"q", +"r"]
b.find { |s| s == "q" }.setbyte(0, 90)
p b
# a block whose value a method of the program uses, under a name
# (`step`) that is a loop on a builtin
class Machine
  def initialize = @log = []
  def step
    @log << yield
    self
  end
  def log = @log
end
names = [+"ann", +"bo"]
m = Machine.new
m.step { names.min_by { |s| s.size } << "!" }
m.step { names.max_by { |s| s.size } << "?" }
p m.log
# a mutator with a block runs for what the block does as well
words = [+"a1", +"b22"]
total = 0
words.find { |w| w.start_with?("b") }.gsub!(/\d/) { |d| total += d.to_i; d }
p total
# a slice of a String is a new String
s = +"hello"
s[0, 2] << "!"
s.slice(0, 2).upcase!
p s
# ...and under a name that reaches the program's method through an alias
class Bag
  def run
    yield 1
  end
  alias each run
end
pets = [+"cat", +"ox"]
r = Bag.new.each { |i| pets.find { |s| s.size == 3 } << "#{i}" }
p r
def once
  yield 2
end
alias each once
r = each { |i| pets.min_by { |s| s.size } << "#{i}" }
p r
# a change nothing can see: the Array's own literal made its Strings and
# nothing reads the Array again but for its size
fresh = [+"q", +"rr"]
fresh.max_by { |s| s.size } << "*"
p fresh.size
# ...or the Array is built where it is read
line = "k = v"
line.split("=").first.strip!
line.chars.first << "x"
p line
# a frozen literal raises, as it does by every route
lits = ["q", "rr"]
begin
  lits.find { |s| s.size == 2 } << "!"
rescue FrozenError
  puts "frozen"
end
p lits
NAMES = ["ann", "bo"]
begin
  NAMES[0].upcase!
rescue FrozenError
  puts "frozen"
end
p NAMES
