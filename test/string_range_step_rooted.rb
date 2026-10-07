# A String Range's step(n) and % keep the Enumerator they answer, and the
# Range it is an Enumerator over, while its inspect label is made.
x = 3.to_s
y = 8.to_s
n = 0
3000.times { |i| n += (x..y).step(2).to_a.size + ((x..y) % 2).map(&:size).sum }
p n
r = ("a".."e")
n = 0
3000.times do
  e = r.step(2)
  n += e.to_a.size
  n += 1 if e.next == "a"
end
p n
m = 0
3000.times { |i| m += ("10".."29").step(3).to_a.size }
p m
