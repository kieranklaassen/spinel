# A String local that is appended to twice in a row, or in a loop, is held
# as a handle. While it is nil the handle is NULL, and reading the local
# answers nil: after a write of nil, after a call hands it nil, before its
# first write, and in the nil test a program makes on a slice that missed
# before it appends. A String method called on one that was never assigned
# raises NoMethodError, as on any nil.

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

def tail(s)
  t = s[10, 2]
  return "none" if t.nil?
  t << "a"
  t << "b"
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

def unset_size(fill)
  if fill
    t = +""
    t << "a"
    t << "b"
  end
  t.size
rescue NoMethodError => e
  e.message.end_with?("size' for nil")
end

def unset_before(fill)
  if fill
    t = +""
    t << "a"
    t << "b"
  end
  t < "a"
rescue NoMethodError => e
  e.class
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
puts tail("abc")
puts tail("0123456789xy")
p unset(false)
p unset(true)
p unset_size(false)
p unset_size(true)
p unset_before(false)
p unset_before(true)

u = +""
3.times { |i| u << i.to_s }
p u
u = nil
p u
u = +"z"
u << "y"
p u

# `&:nil?` only calls nil?; it defines nothing, and the reads above stay
# tested.
p ["a", nil].map(&:nil?)

# A nil a method answers, with the appends behind a test that holds: the
# loop's test and the method's value both read the handle.
def hit_or_nil(k) = k > 5 ? +"hit" : nil

def banged(k)
  s = hit_or_nil(k)
  i = 0
  while s && i < 2
    s << "!"
    i += 1
  end
  s
end
p banged(9)
p banged(1)
