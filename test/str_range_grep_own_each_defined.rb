# As test/str_range_grep_own_each.rb, with the `each` given to Array by
# define_method: the program's walk reaches no element, and === of a String
# Range keeps the answer it had for a boxed String.
class Array
  define_method(:each) { self }
end

m = ["c", 5, "q", nil]
p m.grep("a".."m")
