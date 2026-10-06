# A condition over a method that answers a class or a module calls the method
# once, and so does respond_to? over it. It was called twice: the test for the
# nil class read its operand twice.
class K; end
module M; end
$n = 0

def one
  $n += 1
  K
end

def mod
  $n += 1
  M
end

def anon
  $n += 1
  Class.new { def hi; "hi"; end }
end

def wrap
  yield
end

def two
  one
end

puts "if" if one
puts $n
puts "unless" unless one
puts $n
x = one ? 1 : 2
puts x, $n
puts !one
puts $n
puts !!mod
puts $n
if $n > 100
  puts "no"
elsif mod
  puts "elsif"
end
puts $n
i = 0
until !one || i > 0
  i += 1
end
puts $n
y = (anon ? 1 : 2) + 1
puts y, $n
puts "block" if wrap { one }
puts $n
l = -> { mod }
puts "lambda" if l.call
puts $n
puts "through" if two
puts $n
puts "not" if !anon
puts "not not" unless !anon
puts $n
puts one.respond_to?(:new)
puts $n
