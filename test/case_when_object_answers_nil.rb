# A `when obj` whose === (or ==) answers nil on every path is called and
# is no match. Such a method is a void function in C, and the arm used its
# value: the program did not build.
class Never
  def ===(o) = nil
end

class Log
  def initialize = @seen = 0
  def seen = @seen
  def ===(o)
    @seen += 1
    nil
  end
end

class Blank
  def initialize(n) = @n = n
  def set(n) = @n = n
  def ==(o) = nil
end

class Refuses
  def ===(o) = raise(ArgumentError, "refused")
end

case 5
when Never.new then puts "hit"
else puts "miss"
end
case 2
when 1, Never.new then puts "hit"
else puts "miss"
end
case :y
when Never.new, :y then puts "hit"
else puts "miss"
end

# the method runs
log = Log.new
case 5
when log then puts "hit"
when 5 then puts "five"
end
case :y
when log then puts "hit"
else puts "miss"
end
p log.seen

blank = Blank.new(1)
blank.set(2)
case 5
when blank then puts "hit"
else puts "miss"
end

# the case value calls it too
p(case 2 when 1, Never.new then :hit else :miss end)
p(case :y when Never.new, :y then :hit else :miss end)
p(case 5 when log then :hit else :miss end)
p log.seen
p(case 5 when blank then :hit else :miss end)

# one that always raises is a void function too
begin
  case 5
  when Refuses.new then puts "hit"
  else puts "miss"
  end
rescue ArgumentError => e
  puts e.message
end
