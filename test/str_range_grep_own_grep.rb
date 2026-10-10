# grep asks === of each element in the compiler's own Ruby, and that === is
# not changed: where the program gives Array a grep of its own, which is not
# called here, the builtin still finds no boxed String in a String Range,
# and that is what the program's grep answers.
class Array
  def grep(pat)
    []
  end
end

a = ["b", 1]
p a.grep("a".."c")
