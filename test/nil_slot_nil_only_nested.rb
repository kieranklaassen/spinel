# nil-only operators nested in one another's operand, on String slots that
# hold nil: each level is answered for its nil, and a level does not double
# the time the program takes to compile.

def pick(k) = k ? "a" : nil

s = pick(ARGV.size > 5)
t = pick(ARGV.size > 6)
u = pick(true)

p(s | (s | (s | (s | (s | (s | (s | (s | (s | (s | (s | (s | (s | (s | (s | (s | (s | (s | (t)))))))))))))))))))
p(s & (s ^ (s | (s & (s ^ (s | (s & (s ^ (s | (s & (s ^ (s | (t)))))))))))))
p(s | (s | (s | (s | (s | (s | (u)))))))

begin
  p(s | (u | (s | t)))
rescue NoMethodError => e
  puts e.class
end
