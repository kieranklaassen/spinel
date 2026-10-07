# Right before the yield frame, and still: a spliced method that matches and a
# block that touches no match; a block whose match its writer reads after the
# call; a method that takes its block as a parameter, which keeps the old frame.
def first_word(s)
  s =~ /(\w+)/
  yield $1
end

first_word("ab cd") { |w| puts w }
first_word("ab cd") { |w| w =~ /(b)/ }
p $1

def each_item(a)
  a.each { |x| yield x }
end

each_item(["a1", "b2"]) { |x| x =~ /(\d)/ }
p $1

def tokens(s)
  out = []
  while s =~ /\A\s*(\w+)/
    out << yield($1)
    s = $'
  end
  out
end

p tokens("ab cd ef") { |t| t.upcase }

def with_blk(s, &b)
  s =~ /(a+)/
  b.call($1)
end

with_blk("aa") { |w| p w }
