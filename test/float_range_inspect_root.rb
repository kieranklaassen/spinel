# A Float Range's inspect makes the text of its first end, then the text of
# its last end, then joins the two. Nothing held the first text while the
# second was made: a collection there freed it, and the result began with
# freed bytes. One inspect in 200,000 was wrong in a plain run, and every
# one under SPINEL_GC_STRESS=2.
bad = 0
300.times do |i|
  bad += 1 if ((i + 0.25)..(i + 1.25)).inspect != "#{i + 0.25}..#{i + 1.25}"
  bad += 1 if ((i + 0.5)...(i + 1.5)).to_s != "#{i + 0.5}...#{i + 1.5}"
end
p bad

r = (0.25..1.25)
p r.inspect, r.to_s
puts "#{r}", r
p (1.5...2.5)
p (1.5..).inspect, (..2.5).inspect   # an omitted end prints as nothing
x = [(0.5..1.5), 1]           # a Float Range in a box
p x, x[0].inspect
