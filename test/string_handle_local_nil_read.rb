# A String local that is appended to twice in a row, or in a loop, is held
# as a handle. While it is nil the handle is NULL, and reading the local
# answers nil: after a write of nil, after a call hands it nil, and before
# its first write.

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

def found(words, want)
  t = +""
  t << "a"
  t << "b"
  t = words.find { |w| w == want }
  t
end

def unset(fill)
  if fill
    t = +""
    t << "a"
    t << "b"
  end
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

p joined([])
p joined(["x", "y"])
puts label(true)
puts label(false)
p found(["x", "y"], "q")
p found(["x", "y"], "y")
p unset(false)
p unset(true)

u = +""
3.times { |i| u << i.to_s }
p u
u = nil
p u
u = +"z"
u << "y"
p u
