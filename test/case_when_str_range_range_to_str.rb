# spinel: gc-stress
# case/when with a String Range and a boxed subject that is no String keeps
# the equality it had. A Range the program gives a to_str takes the arm of
# the endless Range that equals it, in CRuby by that to_str and here by the
# equality.
class Range
  def to_str
    "c"
  end
end

def held(v, r)
  case v
  when r then "in"
  else "out"
  end
end

q = [("a"..), 3]
puts "#{held(q[0], ("a"..))} #{held(q[1], ("a"..))}"

# the subject and the Range both made where the case is written
def fresh(i)
  i % 2 == 0 ? ("a"..) : i
end
lo = "a"
hits = 0
i = 0
while i < 200
  case fresh(i)
  when ((lo + "")..) then hits += 1
  end
  i += 1
end
puts "made on the spot: #{hits}"
