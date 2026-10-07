# The error classes of poly_string_index_assign_error_class.rb for the keys
# sp_poly_str_aset_key takes: a boxed key, a String, a Regexp, a Range, and
# every key in a program where a class owns `[]=` (a Struct does). A frozen
# String raised FrozenError whatever the key; a key with no match, or one
# outside the String, raises first in CRuby.
Pt = Struct.new(:a)

def try
  yield
  :stored
rescue => e
  "#{e.class}: #{e.message}"
end

fz = ["abcdef".freeze, 1][0]
p try { fz[9] = "X" }
p try { fz["q"] = "X" }
p try { fz[/q/] = "X" }
ki = [9, "q"][0]
p try { fz[ki] = "X" }
ks = ["q", 9][0]
p try { fz[ks] = "X" }
kr = [9..10, 0][0]
p try { fz[kr] = "X" }
p fz

# a key that is in the String is still the FrozenError
p try { fz[2] = "X" }.split(":").first
p try { fz["b"] = "X" }.split(":").first
p try { fz[/b/] = "X" }.split(":").first
kin = [2, "q"][0]
p try { fz[kin] = "X" }.split(":").first
krin = [1..2, 0][0]
p try { fz[krin] = "X" }.split(":").first
p fz

# a String that is not frozen raises the same and stores the rest
s = [+"abcdef", 1][0]
p try { s["q"] = "X" }
p try { s[/q/] = "X" }
p try { s[ki] = "X" }
p try { s[kr] = "X" }
p try { s["b"] = "X" }, s
p try { s[kin] = "Y" }, s
