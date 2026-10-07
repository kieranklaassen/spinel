# A String variable on this route must not silently lose its append.
# A yielding method that calls itself with a block that yields is compiled
# as a function, and its String parameter is a copy.
def countdown(out, n)
  out << n.to_s
  if n > 0
    countdown(out, n - 1) { |v| yield v }
  else
    yield out.size
  end
end
buf = +""
r = countdown(buf, 3) { |v| v * 2 }
p r, buf
