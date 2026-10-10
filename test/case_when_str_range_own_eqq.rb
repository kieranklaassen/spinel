# In a program that gives Range a === of its own, case/when with a String
# Range and a boxed String keeps the answer it had: the arm is not taken,
# which is what this === says of every value.
class Range
  def ===(other)
    false
  end
end

def held(v, r)
  case v
  when r then "in"
  else "out"
  end
end

m = ["c", 5]
puts "#{held(m[0], ("a".."m"))} #{held(m[1], ("a".."m"))}"
