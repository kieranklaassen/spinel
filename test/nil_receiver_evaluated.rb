# A receiver that always answers nil is still evaluated under ! and &. :
# the call was left out, and what it does with it.
$n = 0

def none
  $n += 1
  nil
end

def log(s)
  puts s
  nil
end

puts !none
puts $n
puts !!none
puts $n
puts "if" if !none
puts $n
puts "unless" unless !none
puts $n
i = 0
until !none || i > 0
  i += 1
end
puts $n
p none&.size
puts $n
x = none&.to_s
p x
puts $n
none&.length
puts $n
p !log("seen")
p log("once")&.size
# the arguments of a call that is not made stay unevaluated
p none&.fetch(log("not printed"))
puts $n
# a nil that is not a call
v = nil
p !v
p v&.size
