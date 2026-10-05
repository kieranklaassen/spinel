# split and rpartition with a Regexp build their result piece by piece. The
# Array split fills was held in no root, and rpartition made its three pieces
# before it stored any of them, so the collection one piece's allocation
# starts freed the Array or the earlier pieces. On a large String that
# collection comes in a plain run.

piece = "abcdefghij" * 40
s = (piece + " ") * 2000

# split: every round answers 2000 pieces, each the 400 bytes it was cut from.
n = 0
bad = 0
8.times do
  a = s.split(/ /)
  n += a.size
  bad += 1 if a[0] != piece || a[999] != piece || a[1999] != piece
end
p n
p bad

# split with a limit, with a captured group, and on the empty pattern.
a = s.split(/ /, 3)
p a.size, a[0] == piece, a[1] == piece, a[2].size
a = s.split(/( )/)
p a.size, a[0] == piece, a[1], a[3998] == piece
p "ab cd  ef".split(/\s+/)
p "ab cd".split(/\s+/, -1)
p "a1b22c".split(/(\d)/)
puts "héllo".split(//).join("|")

# rpartition: the head, the match and the tail of the last match.
ok = 0
8.times do
  a = s.rpartition(/ /)
  ok += 1 if a.size == 3 && a[0].size == 801999 && a[0][0, 400] == piece && a[1] == " " && a[2] == ""
end
p ok

# Many rounds on a small String: no round may answer a freed piece.
t = ("a" * 3000) + "b" + ("c" * 3000)
wrong = 0
i = 0
while i < 20000
  a = t.rpartition(/b/)
  wrong += 1 if a[0].size != 3000 || a[2].size != 3000 || a[1] != "b" || a[0][0] != "a" || a[2][2999] != "c"
  i += 1
end
p wrong
p ("k-" * 20 + "end").rpartition(/k-/)
p "hello123world".rpartition(/\d+/)
p "no digits".rpartition(/\d/)

# A String separator was right before and stays so.
p s.split(" ").size
p s.rpartition(" ")[0].size
