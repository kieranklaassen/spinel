# `when nil` beside an Array or a Hash subject asks whether the subject is
# nil, as it does beside an Integer, a Float and a String. An Array or a
# Hash that was nil never matched the arm and took the else.

# an element past the end; an empty row is not nil
rows = [[1, 2], [3], []]
p(case rows[9] when nil then :hit else :miss end)
p(case rows[0] when nil then :hit else :miss end)
p(case rows[2] when nil then :hit else :miss end)
case rows[9]
when nil then puts "none"
else puts "row"
end

# an instance variable never written
class Bag
  def initialize(set)
    if set
      @list = [1, 2]; @map = { a: 1 }
    end
  end
  def list = @list
  def map = @map
end

p(case Bag.new(false).list when [1, 2] then :same when nil then :hit else :miss end)
p(case Bag.new(true).list when [1, 2] then :same when nil then :hit else :miss end)
p(case Bag.new(false).map when nil then :hit else :miss end)
p(case Bag.new(true).map when nil then :hit else :miss end)

# a Hash's missing value
maps = { a: { x: 1 } }
p(case maps[:a] when nil then :hit else :miss end)
p(case maps[:z] when nil then :hit else :miss end)

# nil beside another value in one arm
p(case rows[9] when [3], nil then :hit else :miss end)
p(case rows[1] when [3], nil then :hit else :miss end)
p(case rows[0] when [3], nil then :hit else :miss end)

# in a block, as a value
p [0, 2, 5].map { |j| case rows[j] when nil then -1 else rows[j].size end }
