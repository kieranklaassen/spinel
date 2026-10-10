# An Array has no key? in CRuby: the call raises NoMethodError. Here it
# answers. Under a rescue the answer it had for a boxed appended String
# is the rescued one, and it is kept.
h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
bw = [["ab", "cd"], 1][0]
p((bw.key?(h["k"]) rescue false))
