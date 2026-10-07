# The Range key store of poly_range_aset_beside_user_class.rb in a program
# whose only `[]=` is a Struct's: every Struct has one, so a program with a
# Struct anywhere dropped `s[1..2] = v` on a boxed String and raised
# TypeError for it on a boxed Array.
Pt = Struct.new(:x, :y)

def pick(i) = [+"abcdef", [1, 2, 3, 4], Pt.new(1, 2)][i]

s = pick(0)
s[1..2] = "-"
p s
s[1...-1] = ""
p s

a = pick(1)
a[1..2] = [9]
p a
a[2..] = [5, 6]
p a
