# to_i and to_f read a String handle local's live buffer. A local that is
# nil has no buffer, and nil answers both itself: 0 and 0.0.

def as_int(keep)
  t = +""
  t << "4"
  t << "2"
  t = nil unless keep
  t.to_i
end
p as_int(false)
p as_int(true)

def as_float(keep)
  t = +""
  t << "4"
  t << ".5"
  t = nil unless keep
  t.to_f
end
p as_float(false)
p as_float(true)

# in a loop that clears the local every other round
sum = 0
4.times do |i|
  t = +""
  t << i.to_s
  t << "0"
  t = nil if i.odd?
  sum += t.to_i
end
p sum

t = +""
t << "7"
t << "7"
t = nil if ARGV.empty?
p t.to_i
p t.to_f
puts "#{t.to_i}|#{t.to_f}"
