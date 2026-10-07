# A Struct's `super(a, b)` records its stores after their values are built.
#
# In a Struct's own initialize `super(a, b)` sets the members, one C
# expression: `(self->iv_name = A, self->iv_tags = B, 0)`. The barrier pass
# has no room for a statement inside an expression and wraps the holder,
# `SP_WBO(self)->iv_tags = B`: the barrier ran, then the value was built,
# then the store was made. A collection while the value was built started
# the remembered set over, so the Struct, old by then, held a young value
# that was recorded nowhere, and the next minor mark freed it in the slot.
#
# Every case makes a row of Structs whose arguments allocate enough for a
# collection to fall inside them, allocates, and reads the members back.
# Each line is the number of Structs that read back something else.
#
# The gc-minor-test leg also runs this under SPINEL_GC_VERIFY_GEN=1
# SPINEL_GC_STRESS=1, which reports the holder that went unrecorded.

def churn(n)
  i = 0
  x = nil
  while i < n
    x = ["c#{i}", "d#{i}"]
    i += 1
  end
  x
end

# enough allocation for a collection to fall inside the value
def name_of(i)
  churn(200)
  "n" + i.to_s
end

def tags_of(i)
  churn(200)
  ["t" + i.to_s, "x"]
end

def size_of(i)
  churn(200).size + i
end

Pair = Struct.new(:name, :tags) do
  def initialize(i)
    super(name_of(i), tags_of(i))
  end
end

# the value built last belongs to a member that holds no reference
Sized = Struct.new(:tags, :size) do
  def initialize(i)
    super(tags_of(i), size_of(i))
  end
end

Named = Struct.new(:name, :tags, keyword_init: true) do
  def initialize(i)
    super(name: name_of(i), tags: tags_of(i))
  end
end

Point = Data.define(:name, :tags) do
  def initialize(i:)
    super(name: name_of(i), tags: tags_of(i))
  end
end

N = 300

def pairs
  row = []
  i = 0
  while i < N
    row << Pair.new(i)
    i += 1
  end
  churn(2000)
  bad = 0
  row.each_with_index { |s, k| bad += 1 unless s.name == "n#{k}" && s.tags == ["t#{k}", "x"] }
  bad
end

def sized
  row = []
  i = 0
  while i < N
    row << Sized.new(i)
    i += 1
  end
  churn(2000)
  bad = 0
  row.each_with_index { |s, k| bad += 1 unless s.tags == ["t#{k}", "x"] && s.size == k + 2 }
  bad
end

def named
  row = []
  i = 0
  while i < N
    row << Named.new(i)
    i += 1
  end
  churn(2000)
  bad = 0
  row.each_with_index { |s, k| bad += 1 unless s.name == "n#{k}" && s.tags == ["t#{k}", "x"] }
  bad
end

def points
  row = []
  i = 0
  while i < N
    row << Point.new(i: i)
    i += 1
  end
  churn(2000)
  bad = 0
  row.each_with_index { |s, k| bad += 1 unless s.name == "n#{k}" && s.tags == ["t#{k}", "x"] }
  bad
end

puts "two members: #{pairs}"
puts "a member with no reference after one with: #{sized}"
puts "keywords: #{named}"
puts "a Data's keywords: #{points}"
