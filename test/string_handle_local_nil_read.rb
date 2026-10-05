# A String local that is appended to twice in a row, or in a loop, is held
# as a handle. Once a write sets it to nil the handle is NULL, and reading
# the local answers nil.

def joined(parts)
  t = +""
  parts.each { |x| t << x }
  t = nil if parts.empty?
  t
end

def label(clear)
  t = +""
  t << "a"
  t << "b"
  t = nil if clear
  return "none" unless t
  t
end

t = +""
t << "a"
t << "b"
t = nil if ARGV.empty?
p t
puts t.inspect
p t.nil?
p(t == nil)
p(t != nil)
puts(t ? "set" : "unset")
puts "[#{t}]"
p t.to_s
p t.class
p t&.size
p(t || "d")
p t.to_i
p t.to_f

p joined([])
p joined(["x", "y"])
puts label(true)
puts label(false)

u = +""
3.times { |i| u << i.to_s }
p u
u = nil
p u
u = +"z"
u << "y"
p u
