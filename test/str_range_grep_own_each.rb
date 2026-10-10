# grep asks === of each element in the compiler's own Ruby, and that === is
# not changed. CRuby's grep walks by `each`, and by the program's own where
# it gives Array one; here grep walks an Array as the builtin does and still
# finds no boxed String in a String Range, which is what this `each` gives.
# The `each` is no part of what === asks: written by the program, in a block
# that select runs, === covers the String.
class Array
  def each
    self
  end
end

m = ["c", 5, "q", nil]
p m.grep("a".."m")
p m.select { |e| ("a".."m") === e }
