# A local written in the expression of a rescue modifier keeps the write
# when the rescue is taken
tries = 0
x = (tries += 1; raise "no") rescue :gave_up
p x, tries

def size_then_parse(s)
  n = 0
  v = (n = s.size; Integer(s)) rescue -1
  [v, n]
end
p size_then_parse("12"), size_then_parse("zz")

# a parameter
def scaled(k, s)
  v = (k *= 2; Integer(s) * k) rescue 0
  [v, k]
end
p scaled(3, "7"), scaled(3, "x")

# a Float, a Symbol, a true, a String and an Array, the modifier as a statement
def kinds
  f = 1.5
  y = :old
  t = false
  s = "old"
  a = [1]
  (f = 2.5; y = :new; t = true; s = "new"; a = [1, 2]; raise ArgumentError) rescue nil
  [f, y, t, s, a]
end
p kinds

# first written inside, and a local that takes two types
def fresh
  r = ((m = 4; u = 1; u = "one"; Integer("z")) rescue :err)
  [r, m, u]
end
p fresh

# nested modifiers
def nested
  a = 0
  b = 0
  r = ((a = 1; ((b = 2; Integer("in")) rescue raise("out"))) rescue :outer)
  [r, a, b]
end
p nested

# a write in the fallback, and one the rescue does not reach
def untaken
  c = 0
  d = 0
  r = ((c = 1; Integer("5")) rescue (d = 1; 0))
  q = (Integer("z") rescue (d += 2; -1))
  [r, q, c, d]
end
p untaken

# in a block, with next and break
def scan(words)
  seen = 0
  good = 0
  words.each do |w|
    v = (seen += 1; Integer(w)) rescue nil
    next if v.nil?
    good += 1
    break if v == 0
  end
  [seen, good]
end
p scan(["1", "x", "2"]), scan(["0", "1"]), scan(["y"])

i = 0
bad = 0
while i < 4
  i += 1
  (bad += 1 if i.odd?; raise "odd" if i.odd?) rescue next
end
p i, bad

# a block spliced into a yielding method, the whole call under the modifier
def twice
  yield 1
  yield 2
end
def spliced
  n = 0
  f = 0.0
  (twice { |x| n += x; f += 0.5; raise "stop" if x == 2 }) rescue nil
  [n, f]
end
p spliced
