class Img
  def m(s, t, k: "a" * 2)
    s << "x"
    t << "y"
    [s, t, k]
  end
end
class Other
  def m(s, t, k: 1) = []
end
y = [Img.new, Other.new][0]
keep = []
bad = 0
i = 0
while i < 300_000
  r = y.m(+"a", +"b")
  keep << [r, i] if i % 7 == 0
  bad += 1 unless r == ["ax", "by", "aa"]
  i += 1
end
bad2 = 0
keep.each { |r, i| bad2 += 1 unless r == ["ax", "by", "aa"] }
p bad, bad2, keep.size
