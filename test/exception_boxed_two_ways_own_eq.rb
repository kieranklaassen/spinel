# One exception boxed two ways (test/exception_boxed_two_ways_equal.rb) whose
# class has an == of its own: that method answers, for the same object too.
class Never < StandardError
  def ==(o) = false
end
class Always < StandardError
  def ==(o) = true
end

n = Never.new("n")
a = Always.new("a")
made = [n, a, 3]
begin
  raise n
rescue => e
  p [e, 3][0] == made[0], made[0] == [e, 3][0], [e, 3][0] != made[0]
  p e.equal?(made[0]), made.map { |x| e.equal?(x) }
end
begin
  raise a
rescue => e
  p [e, 3][0] == made[1], made[1] == [e, 3][0], made[1] == 3, made[1] != [e, 3][0]
end
