# case/when with a String Range asks String#<=>. In a program that gives
# String a <=> of its own, a boxed String keeps the answer it had: the arm
# is not taken, which is what this <=> says of every String.
class String
  def <=>(other)
    1
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
