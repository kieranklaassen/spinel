# The same for a local written from a read no sharing rule follows, in a
# method.
def star(words)
  w = words.max_by { |s| s.size }
  w << "*"
  nil
end
a = [+"q", +"rr"]
star(a)
p a
