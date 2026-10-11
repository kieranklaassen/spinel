# As test/str_range_grep_own_grep.rb, with the grep given to Array by
# alias_method.
class Array
  def none(pat)
    []
  end
  alias_method :grep, :none
end

a = ["b", 1]
p a.grep("a".."c")
