# grep asks === of each element it walks to. CRuby walks by `each`, and by
# the program's own where it gives Array one; here grep walks an Array as
# the builtin does. So in a program that defines an `each`, === of a String
# Range keeps the answer it had for a boxed String: no element is found,
# which is what the program's `each` gives.
class Array
  def each
    self
  end
end

m = ["c", 5, "q", nil]
p m.grep("a".."m")
