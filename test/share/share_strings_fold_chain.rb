# --share-strings: a fold seeded with an empty [] whose block is one chain of
# pushes onto the memo, ending in a variable from outside the block. The memo
# is that Array, so the String pushed last is the variable's own.

s1 = +"s"
x1 = [1, 2].inject([]) { |m, v| m << v << s1 }
s1 << "x"
p x1, x1[1].equal?(s1)

s2 = String.new
x2 = [1, 2].reduce([]) { |m, v| m.push(v).push(s2) }
s2 << "x"
p x2

s3 = +"s"
x3 = [:a].inject([]) { |m, v| (m << v) << v << s3 }
s3.upcase!
p x3

def chained
  s = +"s"
  x = [1.5].inject([]) { |m, v| m << v << s }
  s << "x"
  x
end
p chained

# a String never changed in place
s5 = +"s"
p ["a", "b"].inject([]) { |m, v| m << v << s5 }
