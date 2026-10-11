# === of a String Range asks String#<=>. In a program that gives String a
# <=> of its own, a boxed String keeps the answer it had: not covered, which
# is what this <=> says of every String.
class String
  def <=>(other)
    1
  end
end

m = ["c", 5]
r = ("a".."m")
puts "#{r === m[0]} #{r === m[1]}"
