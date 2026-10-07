# A rescue modifier whose value is always nil has no C type to be held in.
# Its temporary was declared `void`, and the program did not build.
$n = 0
$t = false
def none; $n += 1; nil; end
def boom; $n += 1; raise "b" if $t; nil; end
def fb; puts "fb"; nil; end

x = (none rescue nil)
p x
p((none rescue nil))
p (none rescue nil).nil?
p (none rescue nil).to_s
a = [(none rescue nil), 1]
p a
puts "v#{(none rescue nil)}w"
p((none rescue nil) == nil)
puts((none rescue nil) ? "t" : "f")
y = (none rescue nil) || 7
p y
p $n

# the fallback runs when the expression raises
$t = true
x = (boom rescue fb)
p x
x = (raise("x") rescue nil)
p x
x = (nil rescue nil)
p x
p $n

# as a method's value and a block's
def tail; (none rescue nil); end
p tail
p [1, 2].map { |i| (none rescue nil) }
p $n
