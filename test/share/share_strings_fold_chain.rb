# --share-strings: a fold seeded with an empty [] whose block is one chain of
# pushes onto the memo, ending in a String from outside the block. Without
# the flag the memo is typed the Array it is (test/fold_empty_seed_push_chain.rb).
# Under the flag the memo keeps the type it had: these are right as they
# are, and with the memo an Array the first two would be refused, as a
# String held by a block parameter.

s1 = t1 = +"s"
x1 = ["a", "b"].inject([]) { |m, v| m << v << s1 }
s1 << "x"
p x1, s1, t1

def aliased
  xs = ["a", "b"]
  t = +"s"
  s = t
  x = xs.inject([]) { |m, v| m << v << s }
  s << "x"
  p x, x[1].equal?(s)
end
aliased

# a String never changed in place
s3 = +"s"
p ["a", "b"].inject([]) { |m, v| m << v << s3 }
