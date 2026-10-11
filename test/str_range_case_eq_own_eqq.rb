# In a program that gives Range a === of its own, === of a String Range
# with a boxed String keeps the answer it had: false, which is what this
# === says of every value.
class Range
  def ===(other)
    false
  end
end

m = ["c", 5]
r = ("a".."m")
puts "#{r === m[0]} #{r === m[1]}"
