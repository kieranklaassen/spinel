# A literal nil bound to a block parameter that holds a Symbol is a
# Symbol's nil. It was written as 0, the id of the program's first Symbol:
# `p m` printed that Symbol and `m.nil?` was false. `when nil` beside a
# Symbol compared with 0 too, so it took that nil, and the first Symbol
# with it; both now read the Symbol's own nil.
NOTHING = nil

# the first Symbol of the program (`:m` here) is no nil
p(case :m when nil then :hit else :miss end)
p(case :m when NOTHING then :hit else :miss end)

def marks
  yield nil
  yield :a
end

marks do |m|
  p m
  p m.nil?
  puts(m ? "set" : "unset")
  p(m || :none)
  puts "[#{m}]"
  puts(case m when nil then "nil" when :a then "a" else "other" end)
  puts(case m when NOTHING then "nil" else "other" end)
  case m
  when :a, nil then puts "a or nil"
  else puts "other"
  end
end

def call_marks(&blk)
  blk.call(nil)
  blk.call(:b)
end
call_marks { |m| p m }

def pairs
  yield 1, nil
  yield 2, :c
end
pairs { |n, m| puts "#{n} #{m.inspect}" }

# kept in an Array and asked later
kept = []
marks { |m| kept << m }
p kept
p kept.map { |m| m.nil? }
kept.each { |m| puts(case m when nil then "nil" else "sym" end) }

# handed on to a method that asks
def name_of(m)
  case m
  when nil then "none"
  when :a then "first"
  else "sym"
  end
end
marks { |m| puts name_of(m) }

# a Symbol's nil that came another way: an element past the end, an
# instance variable never written
syms = [:a, :z]
puts name_of(syms[0]), name_of(syms[1]), name_of(syms[9])

class Slot
  def initialize(set)
    @y = :a if set
  end
  def y = @y
end
p(case Slot.new(false).y when nil then :hit else :miss end)
p(case Slot.new(true).y when NOTHING then :hit else :miss end)
