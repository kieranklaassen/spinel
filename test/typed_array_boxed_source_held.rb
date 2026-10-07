# An Array a call returns is held while its elements are boxed one by one.
#
# `take(*floats(i))` fills the rest parameter with a new Array of boxed values
# made from the Float Array, and `fmt % ints(i)` hands String#% one made from
# the Integer Array. Both come from sp_typed_to_poly, which allocated the new
# Array before it read the old one and held the old one nowhere. A result no
# variable holds was collected by that allocation, and the elements were then
# read out of a buffer already given back.
#
# Each line is the number of calls, of 1,000, that answered something else.

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
