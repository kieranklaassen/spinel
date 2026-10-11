# As test/str_range_grep_own_each.rb, with the `each` given to Array by
# define_method: grep still finds no boxed String in a String Range, which
# is what the program's walk gives.
class Array
  define_method(:each) { self }
end

m = ["c", 5, "q", nil]
p m.grep("a".."m")
