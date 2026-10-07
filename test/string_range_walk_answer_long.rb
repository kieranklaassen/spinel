# The value of each over a String Range is the Range itself, read again
# after the walk. One whose ends are made on the spot keeps them across
# a walk long enough for a collection in a plain run.

lo = "1"
z = ((lo + "0")..(lo + "49999")).each { |s| s + "!" }
puts z.first, z.last

p ((lo + "0")..(lo + "49999")).reverse_each { |s| s + "!" }.last
w = ((lo + "0")..(lo + "49999")).each_cons(2) { |a| a[0] + "!" }
p w.first, w.last
p ((lo + "0")..(lo + "49999")).each_entry { |s| s + "!" }.first

def walked(a) = ((a + "0")..(a + "49999")).each_with_index { |s, i| s + "!" }
r = walked("2")
p r.first, r.last, r.cover?("25")

n = 0
3.times do |i|
  k = (i + 1).to_s
  q = ((k + "0")..(k + "49999")).each { |s| s + "!" }
  n += 1 if q.first == k + "0" && q.last == k + "49999"
end
p n
