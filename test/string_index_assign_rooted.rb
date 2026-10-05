# s[i] = v with an Integer index cuts the String in two and joins three
# pieces. Built in one nested call, the piece C made first was in flight,
# unrooted, while the next one allocated: under SPINEL_GC_STRESS=2 the
# assignment aborted on a freed String. It goes through sp_str_splice_at,
# which roots each piece (run by gc-stress-test too).
3.times do |k|
  s = "qrst".dup
  n = s.size + k
  s[1] = %w[a bb ccc dddddddd].select { |w| w.size < n }.join
  p s
  s[-1] = "z" * n
  p s
  s[s.size] = "!"
  p s
end

# a String two names hold, and the value of the assignment
t = "qrst".dup
u = t
r = (t[0] = [1, 2].map { |x| (x + 4).to_s }.join)
p r, u, u.equal?(t)

# the bounds are CRuby's: one past the end appends, further is IndexError
v = +"ab"
v[2] = "c"
p v
[4, -4].each do |i|
  begin
    v[i] = "x"
  rescue IndexError => e
    puts "IndexError: #{e.message}"
  end
end
p v

w = +"héllo"
w[1] = "e"
w[-1] = "ö"
p w.size, w.bytesize, w == "hellö"

# a frozen receiver raises
f = "ab"
begin
  f[0] = "x"
rescue FrozenError => e
  puts "FrozenError: #{e.message}"
end
p f

# a value that changes the receiver is read before the receiver is
o = +"abcd"
o[1] = (o << "ef"; "x")
p o
