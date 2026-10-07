# An Array a call returns is held while its elements are boxed one by one.
#
# `take(*floats(i))` fills the rest parameter with a new Array of boxed values
# made from the Float Array, and `fmt % ints(i)` hands String#% one made from
# the Integer Array. Both come from sp_typed_to_poly, which allocated the new
# Array before it read the old one and held the old one nowhere. A result no
# variable holds was collected by that allocation, and the elements were then
# read out of a buffer already given back.
#
# `mixed == strs(i)` compares a mixed Array with a boxed copy of the String
# Array, and an element with a == of its own allocates in the middle of that:
# the copy is held while it is compared, and it holds the Strings.
#
# An Array that something holds needs no such hold and is boxed where it is
# read: a variable's, a reader's or a Struct member's, an element of one, a
# conditional between two.
#
# Each line is the number of calls, of 1,000, that answered something else;
# the last two are of 4,000 and of 800.

SIZE = 2000
CALLS = 1000

def floats(i)
  a = []
  k = 0
  while k < SIZE
    a << i + k + 0.5
    k += 1
  end
  a
end

def ints(i)
  a = []
  k = 0
  while k < SIZE
    a << i + k
    k += 1
  end
  a
end

WORDS = []
SIZE.times { |k| WORDS << "w#{k}" }

def strs(i)
  a = []
  k = 0
  while k < SIZE
    a << WORDS[(i + k) % SIZE]
    k += 1
  end
  a
end

def take(*items) = items

def rest_of_floats
  bad = 0
  i = 0
  while i < CALLS
    r = take(*floats(i))
    bad += 1 unless r.size == SIZE && r[0] == i + 0.5 && r[SIZE - 1] == i + SIZE - 0.5
    i += 1
  end
  bad
end

def format_of_floats
  fmt = "%.1f " * SIZE
  bad = 0
  i = 0
  while i < CALLS
    s = fmt % floats(i)
    bad += 1 unless s.start_with?("#{i + 0.5} #{i + 1.5} ") && s.end_with?(" #{i + SIZE - 0.5} ")
    i += 1
  end
  bad
end

def format_of_ints
  fmt = "%d " * SIZE
  bad = 0
  i = 0
  while i < CALLS
    s = fmt % ints(i)
    bad += 1 unless s.start_with?("#{i} #{i + 1} ") && s.end_with?(" #{i + SIZE - 1} ")
    i += 1
  end
  bad
end

def format_of_strs
  fmt = "%s " * SIZE
  bad = 0
  i = 0
  while i < CALLS
    s = fmt % strs(i)
    bad += 1 unless s.start_with?("w#{i} w#{i + 1} ") && s.end_with?(" w#{(i + SIZE - 1) % SIZE} ")
    i += 1
  end
  bad
end

puts "a Float Array into a rest parameter: #{rest_of_floats}"
puts "a Float Array formatted: #{format_of_floats}"
puts "an Integer Array formatted: #{format_of_ints}"
puts "a String Array formatted: #{format_of_strs}"

class Loud
  def ==(other)
    junk = []
    40.times { |k| junk << "j#{k}" }
    true
  end
end

def three(i) = ["s#{i}", "t#{i}", "u#{i}"]

def compared
  bad = 0
  i = 0
  while i < 2000
    mixed = [Loud.new, "t#{i}", "u#{i}"]
    bad += 1 unless mixed == three(i)
    bad += 1 if mixed != three(i)
    i += 1
  end
  bad
end

puts "a String Array compared: #{compared}"

class Pair
  attr_reader :co, :fl
  def initialize(co, fl)
    @co = co
    @fl = fl
  end
end
Slot = Struct.new(:co, :fl)

def held_sources
  pair = Pair.new(ints(7), floats(7))
  slot = Slot.new(ints(8), floats(8))
  rows = [ints(1), ints(2)]
  frows = [floats(1), floats(2)]
  fa = floats(3)
  fb = floats(4)
  fmt = "%d " * SIZE
  bad = 0
  i = 0
  while i < 100
    k = i & 1
    s = fmt % pair.co
    bad += 1 unless s.start_with?("7 8 ") && s.end_with?(" #{SIZE + 6} ")
    r = take(*pair.fl)
    bad += 1 unless r.size == SIZE && r[0] == 7.5 && r[SIZE - 1] == SIZE + 6.5
    s = fmt % slot.co
    bad += 1 unless s.start_with?("8 9 ") && s.end_with?(" #{SIZE + 7} ")
    r = take(*slot.fl)
    bad += 1 unless r.size == SIZE && r[0] == 8.5 && r[SIZE - 1] == SIZE + 7.5
    s = fmt % rows[k]
    bad += 1 unless s.start_with?("#{k + 1} #{k + 2} ") && s.end_with?(" #{SIZE + k} ")
    r = take(*frows[k])
    bad += 1 unless r.size == SIZE && r[0] == k + 1.5 && r[SIZE - 1] == SIZE + k + 0.5
    s = fmt % (i.odd? ? rows[0] : rows[1])
    bad += 1 unless s.start_with?("#{2 - k} #{3 - k} ") && s.end_with?(" #{SIZE + 1 - k} ")
    r = take(*(i.odd? ? fa : fb))
    bad += 1 unless r.size == SIZE && r[0] == 4.5 - k && r[SIZE - 1] == SIZE + 3.5 - k
    i += 1
  end
  bad
end

puts "an Array something holds, boxed where it is read: #{held_sources}"
