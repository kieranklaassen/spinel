# As test/str_range_grep_own_each.rb, with the `each` in a module that is
# prepended to Array: the program's walk reaches no element, and === of a
# String Range keeps the answer it had for a boxed String.
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
