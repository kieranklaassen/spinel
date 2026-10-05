# An index assignment on a boxed String raises CRuby's error for an index
# outside it. A frozen String raised FrozenError whatever the index; the
# index is looked at first. A Range starting outside the String raised
# IndexError, or wrote into the String when it started below it; it is
# RangeError, naming the Range.

def try
  yield
  :stored
rescue => e
  "#{e.class}: #{e.message}"
end

fz = ["abcdef".freeze, 1][0]
p try { fz[9] = "X" }
p try { fz[-9] = "X" }
p try { fz[9, 1] = "X" }
p try { fz[-9, 1] = "X" }
p try { fz[1, -1] = "X" }
p try { fz[9..10] = "X" }
p try { fz[-9..1] = "X" }
p fz

# an index inside a frozen String is still the FrozenError
p try { fz[2] = "X" }.split(":").first
p try { fz[6] = "X" }.split(":").first
p try { fz[-6] = "X" }.split(":").first
p try { fz[2, 1] = "X" }.split(":").first
p try { fz[1..2] = "X" }.split(":").first
p try { fz[6..7] = "X" }.split(":").first
p fz

# a Range on a String that is not frozen
s = [+"abcdef", 1][0]
p try { s[9..10] = "X" }
p try { s[-9..1] = "X" }
p try { s[-9...-8] = "X" }
p try { s[7..] = "X" }
p s
p try { s[6..7] = "X" }, s
p try { s[-7..0] = "Y" }, s
p try { s[1..2] = "Z" }, s

# the same through an element
rows = [+"abcdef", "uvwxyz".freeze, 1]
p try { rows[0][9..10] = "X" }
p try { rows[0][-9..1] = "X" }
p try { rows[1][9..10] = "X" }
p try { rows[1][9] = "X" }
p try { rows[1][1..2] = "X" }.split(":").first
p rows

# and through a parameter that also takes an Array
def put(x, k, v)
  x[k] = v
  x
rescue => e
  e.class
end
p put([1, 2, 3], 0, 9)
p put("abcdef".freeze, 9, "X")
p put("abcdef".freeze, 2, "X")
p put(+"abcdef", 2, "X")
