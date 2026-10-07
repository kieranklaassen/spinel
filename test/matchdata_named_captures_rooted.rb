# MatchData#named_captures builds its Hash one String at a time. The name's
# copy and the group's text were both fresh and went to the Hash as two
# arguments of one call, so a collection while the second was built freed
# the first: in a loop, a Hash answered one group's text under another
# group's name, or a text as its own name. The symbolize_names: true form,
# which #deconstruct_keys(nil) shares, lost the text the same way when a
# name was a new Symbol.
def check(keep, want)
  bad = 0
  keep.each { |h| bad += 1 unless h.to_a == want }
  bad
end

# short texts first: a text is then the size of a name's copy, and either
# takes the other's place. Each Hash is read a few rounds later, when a
# freed String has been given out again.
q = "aaaaa bbbbb ccccc".match(/(?<a>\w+) (?<b>\w+) (?<c>\w+)/)
qw = [["a", "aaaaa"], ["b", "bbbbb"], ["c", "ccccc"]]
keep = []
bad = 0
i = 0
while i < 20000
  keep << q.named_captures
  if keep.size == 8
    bad += check(keep, qw)
    keep = []
  end
  i += 1
end
p bad

s = ("ab" * 100) + " " + ("cd" * 100) + " " + ("ef" * 100) + " " + ("gh" * 100) + " " + ("ij" * 100)
re = /(?<a>\w+) (?<b>\w+) (?<c>\w+) (?<d>\w+) (?<e>\w+)/
want = [["a", "ab" * 100], ["b", "cd" * 100], ["c", "ef" * 100], ["d", "gh" * 100], ["e", "ij" * 100]]

# long texts
m = s.match(re)
keep = []
bad = 0
i = 0
while i < 20000
  keep << m.named_captures
  if keep.size == 8
    bad += check(keep, want)
    keep = []
  end
  i += 1
end
p bad

# the receiver is the call's own temporary, or $~
v = ("ab" * 40) + " " + ("cd" * 40) + " " + ("ef" * 40)
rv = /(?<a>\w+) (?<b>\w+) (?<c>\w+)(?<d>!)?/
vw = [["a", "ab" * 40], ["b", "cd" * 40], ["c", "ef" * 40], ["d", nil]]
keep = []
bad = 0
i = 0
while i < 6000
  keep << v.match(rv).named_captures
  if keep.size == 8
    bad += check(keep, vw)
    keep = []
  end
  i += 1
end
p bad

keep = []
bad = 0
i = 0
while i < 3000
  keep << rv.match(v).named_captures
  v =~ rv
  keep << $~.named_captures
  if keep.size == 8
    bad += check(keep, vw)
    keep = []
  end
  i += 1
end
p bad

vs = [[:a, "ab" * 40], [:b, "cd" * 40], [:c, "ef" * 40], [:d, nil]]
keep = []
bad = 0
i = 0
while i < 3000
  keep << v.match(rv).named_captures(symbolize_names: true)
  keep << v.match(rv).deconstruct_keys(nil)
  if keep.size == 8
    bad += check(keep, vs)
    keep = []
  end
  x = v.match(rv).deconstruct_keys([:b, :d])
  bad += 1 unless x.to_a == [vs[1], vs[3]]
  i += 1
end
p bad

# a new name each round: its Symbol is interned inside the call
t = ("ab" * 500) + " " + ("cd" * 500)
keep = []
bad = 0
i = 0
while i < 2000
  n = Regexp.new("(?<g" + i.to_s + ">\\w+) (?<h" + i.to_s + ">\\w+)").match(t)
  keep << n.named_captures(symbolize_names: true)
  if keep.size == 8
    keep.each { |h| bad += 1 unless h.values == ["ab" * 500, "cd" * 500] }
    keep = []
  end
  i += 1
end
p bad

# the answers themselves
p "hello world".match(/(?<w>w\w+)/).named_captures.to_a
p "hello world".match(/(?<w>w\w+)/).named_captures(symbolize_names: true).to_a
p "hello world".match(/(?<w>w\w+)/).deconstruct_keys([:w]).to_a
p "key=value".match(/(?<k>\w+)=(?<v>\w+)/).named_captures.to_a
p "ac".match(/(?<a>a)(?<b>b)?(?<c>c)(?<d>d)?/).named_captures.to_a
p "abc".match(/(?<a>\d*)(?<b>[a-z]*)(?<c>\s*)/).named_captures.to_a
p "日本語 テキスト".match(/(?<a>[^ ]+) (?<b>[^ ]+)/).named_captures.to_a
p "abc 123".match(/(?<a>\w)+ (?<b>\d)+/).named_captures.to_a
h = "a b c d e f g h i j k l".match(/(?<g1>\w) (?<g2>\w) (?<g3>\w) (?<g4>\w) (?<g5>\w) (?<g6>\w) (?<g7>\w) (?<g8>\w) (?<g9>\w) (?<g10>\w) (?<g11>\w) (?<g12>\w)/).named_captures
p h.size, h.keys, h.values
p m.named_captures == m.named_captures, m.named_captures.keys, m.named_captures.values.map(&:size)
