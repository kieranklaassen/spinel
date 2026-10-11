# spinel: gc-stress
# === of a String Range with a boxed value that is no String keeps the
# equality it had. A Range the program gives a to_str is covered by the
# endless Range that equals it, in CRuby by that to_str and here by the
# equality.
class Range
  def to_str
    "c"
  end
end

e = ("a"..)
q = [("a"..), 3]
puts "#{e === q[0]} #{e === q[1]}"

# the Range and the value both made where the === is written
def fresh(i)
  i % 2 == 0 ? ("a"..) : i
end
lo = "a"
hits = 0
i = 0
while i < 200
  hits += 1 if ((lo + "")..) === fresh(i)
  i += 1
end
puts "made on the spot: #{hits}"
