# A String variable on this route must not silently lose its append.
# A method that yields inside a Thread's body is compiled as a function,
# and its String parameter is a copy.
def tagged(out, n)
  out << "t"
  Thread.new { yield(out.size + n) }.value
end
buf = +"x"
r = tagged(buf, 3) { |v| v * 2 }
p r, buf
