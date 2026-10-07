# String#insert on a receiver whose kind is known at run time raises
# IndexError for an index below the start, and leaves the String as it was:
# the index came back around to a place inside the String.

# a statement, at every index from below the start to past the end
[-9, -4, -3, -2, -1, 0, 1, 2, 3, 9].each do |i|
  box = [+"ab", 1][0]
  begin
    box.insert(i, "x")
  rescue IndexError => e
    puts "IndexError: #{e.message}"
  end
  p box
end

# the value taken
[-4, -3, 2, 3].each do |i|
  box = [+"ab", 1][0]
  begin
    r = box.insert(i, "x")
    p r
  rescue IndexError => e
    puts "IndexError: #{e.message}"
  end
  p box
end

# characters, not bytes
m = [+"héllo", 1][0]
begin
  m.insert(-7, "x")
rescue IndexError => e
  puts "IndexError: #{e.message}"
end
m.insert(-6, "¿")
m.insert(-1, "!")
p m

# a parameter that takes a String or an Array
def put(s, i)
  s.insert(i, "x")
rescue IndexError => e
  "IndexError: #{e.message}"
end
p put(+"ab", -4)
p put(+"ab", -3)
p put([1, 2], -3)
p put([1, 2], 1)

# a frozen String: the index is heard first
f = ["ab", 1][0]
begin
  f.insert(-4, "x")
rescue IndexError, FrozenError => e
  puts "#{e.class}: #{e.message}"
end
p f
