# s[/re/, n] = v with a value that is not typed String (here a method that
# returns a String or an Integer) joined the head and the value, then cut the
# tail: the joined piece was in flight, unrooted, while the tail allocated.
# In a long plain run a few Strings lost their head (run by gc-stress-test
# too, where nearly every round lost it).
def pick(i) = i == 0 ? "XY" : 5

bad = 0
i = 0
while i < 4000
  n = 700 + (i * 37) % 900
  s = +("a" * n + "ll" + "b" * n)
  v = pick(0)
  s[/(l)(l)/, 2] = v
  bad += 1 unless s.size == 2 * n + 3 && s.count("a") == n && s.count("b") == n && s[n + 1, 2] == "XY"
  i += 1
end
p bad

# the value read from a call, where it is held too
bad = 0
i = 0
while i < 4000
  n = 700 + (i * 37) % 900
  s = +("a" * n + "ll" + "b" * n)
  s[/(l)(l)/, 2] = pick(0)
  bad += 1 unless s.size == 2 * n + 3 && s.count("a") == n && s.count("b") == n && s[n + 1, 2] == "XY"
  i += 1
end
p bad

t = +"hello world"
t << "!"
t[/(l+)(o)/, 1] = pick(0)
p t
t[/w(or)/, 1] = [1, "OR"].last
p t
begin
  t[/(h)/, 1] = pick(1)
rescue TypeError => e
  p e.class
end
p t
