# spinel: gc-stress
# include? and member? of a boxed String Array with a boxed appended
# String, where only the call holds the Array, the String or both: a
# method makes the Array, a method makes the String and hands it on
# after allocating, a container gives the String up. Each is still
# there when the Array is searched.
def mk(i)
  [["cd", "ef", "a" + "abcdefgh"[i % 8]], i][0]
end

def hv(i)
  h = {"k" => "a".dup, "n" => i}
  h["k"] << "abcdefgh"[i % 8]
  h["k"]
end

def tl(i)
  s = "a".dup
  s << "abcdefgh"[i % 8]
  [s, i][0]
end

hh = {"k" => "a".dup, "n" => 1}
hh["k"] << "b"
bw = [["ab", "cd", "ef"], 1][0]
t = []
u = []
w = []
80.times { |i| t << hv(i); u << tl(i); w << hv(i) }
c = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
i = 0
while i < 80
  c[0] += 1 if mk(i).include?(hv(i))
  c[1] += 1 if mk(i).include?(hh["k"])
  c[2] += 1 if bw.include?(hv(i))
  c[3] += 1 if bw.member?(tl(i))
  c[4] += 1 if bw.include?(t.pop)
  c[5] += 1 if mk(i).member?(u.shift)
  c[6] += 1 if [["ab", "a" + "abcdefgh"[i % 8]], i][0].include?(hv(i))
  c[7] += 1 if mk(i).include?(w.delete_at(0))
  c[8] += 1 if mk(i).include?(tl(i))
  c[9] += 1 if bw.include?(hh["k"])
  i += 1
end
p c
