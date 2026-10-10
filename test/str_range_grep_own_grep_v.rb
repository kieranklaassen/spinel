# As test/str_range_grep_own_grep.rb, for grep_v: the program's own answers
# the whole Array, and the builtin, which still finds no boxed String in a
# String Range, leaves every element.
class Array
  def grep_v(pat)
    self
  end
end

a = ["b", 1]
p a.grep_v("a".."c")
