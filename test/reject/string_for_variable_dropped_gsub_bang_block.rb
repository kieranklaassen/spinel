# The variable of a `for` over an Array is a copy of each String unless
# the sharing analysis follows it. gsub! with a block changes that copy
# and nothing reads it: refused, not lost.
a = [+"q1", +"r"]
for s in a
  s.gsub!(/\d/) { "#" }
end
p a
