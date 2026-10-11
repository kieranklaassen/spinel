# As test/str_range_grep_own_each.rb, with the `each` in a module that is
# prepended to Array: grep still finds no boxed String in a String Range,
# which is what the program's walk gives.
module Quiet
  def each
    self
  end
end

class Array
  prepend Quiet
end

m = ["c", 5, "q", nil]
p m.grep("a".."m")
