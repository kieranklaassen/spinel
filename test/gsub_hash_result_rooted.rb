# gsub with a String pattern and a Hash keeps its result while the match
# is set for a program that reads $~.

h = {"l" => "L"}
s = "hello world " * 500
bad = 0
i = 0
while i < 20000
  t = s.gsub("l", h)
  m = $~[0]
  bad += 1 if t.size != 6000 || t[2] != "L" || t[5998] != "d" || m != "l"
  i += 1
end
p bad

sp = {" " => "_"}
big = ("abcdefghij" * 40 + " ") * 2000
n = 0
8.times do
  t = big.gsub(" ", sp)
  n += t.size if t[400] == "_" && $~[0] == " "
end
p n

p "hello".gsub("l", h), $~[0], $~.begin(0)
p "hello".gsub("z", h), $~
p "hello".gsub("", {"" => "-"}), $~.begin(0)
p "hello".gsub("l", {"l" => 1}), $~[0]
p "hello".gsub("l", {"l" => "L", "e" => 3}), $~[0]

# sub with a Hash and gsub with a String were right before and stay so.
p "hello".sub("l", h), $~.begin(0)
p "hello".gsub("l", "L"), $~.begin(0)
