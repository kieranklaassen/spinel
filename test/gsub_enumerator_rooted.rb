# gsub with no block answers an Enumerator over the matches. The
# Enumerator is kept while its label is made.

p "a1b2".gsub(/\d/).to_a
e = "a1b2c3".gsub(/\d/)
p e.inspect
p e.to_a
p "a1b2".gsub("1").to_a
re = /[a-c]/
p "a1b2".gsub(re).to_a
p "a1b2".gsub(re).inspect
p "a1b2".gsub(/x/).to_a

s = +"a1b2"
f = s.gsub!(/\d/)
p f.inspect
p f.to_a

long = "a1b2c3" * 200
n = 0
i = 0
while i < 300
  g = long.gsub(/\d/)
  n += g.to_a.size + g.inspect.size
  i += 1
end
p n

# The block form and scan were right before and stay so.
p "a1b2".gsub(/\d/) { |m| m * 2 }
p "a1b2".scan(/\d/)

# A pattern that is neither a String nor a Regexp raises TypeError, and its
# inspect is not asked for a label first.
class Pt
  def inspect
    puts "inspect ran"
    "pt"
  end
end
q = [Pt.new, /\d/]
begin
  p "a1b2".gsub(q[0]).to_a
rescue TypeError
  puts "TypeError"
end
