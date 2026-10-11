# As test/boxed_str_array_member_own_each.rb, with the `each` given to
# Array by define_method.
class Array
  define_method(:each) { self }
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
bw = [["ab", "cd"], 1][0]
p bw.member?(h["k"])
