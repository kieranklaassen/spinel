# include? of an Array compares by ==. This program gives String an == of
# its own by an alias to a builtin, which is no method of the program in
# the class table. include? of a boxed String Array with a boxed appended
# String keeps the answer it had: the one the program's == gives.
class String
  alias == equal?
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
bw = [["ab", "cd"], 1][0]
p bw.include?(h["k"])
