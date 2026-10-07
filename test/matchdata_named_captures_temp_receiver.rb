# MatchData#named_captures and #deconstruct_keys build a Hash, and nothing
# held their receiver while they did: as the call's own temporary
# (`s.match(re).deconstruct_keys(nil)`, or `$~`, a new MatchData at each
# read) a collection inside the call freed it, and the groups were then read
# out of whatever took its place. Each Hash here is read a few rounds after
# it is built.
#
# The names are Symbols the program already holds, or groups that took no
# part, so that only the receiver is at stake.
s = ("a" * 80) + " " + ("b" * 80) + " " + ("c" * 80)
re = /(?<a>\w+) (?<b>\w+) (?<c>\w+)/
want = [[:a, "a" * 80], [:b, "b" * 80], [:c, "c" * 80]]

keep = []
bad = 0
6000.times do
  keep << s.match(re).named_captures(symbolize_names: true)
  if keep.size == 8
    keep.each { |h| bad += 1 unless h.to_a == want }
    keep = []
  end
end
p bad

keep = []
bad = 0
3000.times do
  keep << re.match(s).deconstruct_keys(nil)
  s =~ re
  keep << $~.named_captures(symbolize_names: true)
  if keep.size == 8
    keep.each { |h| bad += 1 unless h.to_a == want }
    keep = []
  end
end
p bad

# only the keys asked for
keep = []
bad = 0
3000.times do
  keep << s.match(re).deconstruct_keys([:c, :a])
  s =~ re
  keep << $~.deconstruct_keys([:c, :a])
  if keep.size == 8
    keep.each { |h| bad += 1 unless h.to_a == [want[2], want[0]] }
    keep = []
  end
end
p bad

# String keys, for groups that took no part
rn = /\w+ \w+ \w+(?<d>!)?(?<e>\?)?/
keep = []
bad = 0
3000.times do
  keep << s.match(rn).named_captures
  keep << rn.match(s).named_captures
  if keep.size == 8
    keep.each { |h| bad += 1 unless h.to_a == [["d", nil], ["e", nil]] }
    keep = []
  end
end
p bad

# the answers themselves
p "hello world".match(/(?<w>w\w+)/).deconstruct_keys([:w]).to_a
p "hello world".match(/(?<w>w\w+)/).deconstruct_keys(nil).to_a
p "hello world".match(/(?<w>w\w+)/).named_captures(symbolize_names: true).to_a
p "ac".match(/(?<a>a)(?<b>b)?(?<c>c)(?<d>d)?/).deconstruct_keys([:d, :a, :b]).to_a
p "ac".match(/(?<a>a)(?<b>b)?(?<c>c)(?<d>d)?/).deconstruct_keys([:a, :b, :c, :d, :w]).to_a
p "ab".match(/ab(?<x>!)?/).named_captures.to_a
p (s =~ re; $~.deconstruct_keys([:b]).to_a[0][1].size)
