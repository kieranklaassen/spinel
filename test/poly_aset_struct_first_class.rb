# A Struct that is the program's first class has class id 0, and so does the
# box of a value that is no object. `x[k] = v` on such a value took the
# Struct's arm of the dispatch and wrote a member through a pointer that is
# no Struct: a crash for an Integer, a Float, nil or true, and a member's
# box written into the bytes of a String.
Pt = Struct.new(:m, :n)
pt = Pt.new(1, 2)

[5, nil, 1.5, true, pt, [1, 2]].each do |x|
  begin
    x[0] = 7
    p x
  rescue NoMethodError => e
    puts "#{x.inspect}: #{e.class}"
  end
end

i = [5, pt][0]
begin
  i[:m] = 7
rescue NoMethodError => e
  p e.class
end
p i

# the Struct's own arm is as it was
o = [pt, 5][0]
o[1] = 8
o[:m] = 9
p o, pt
begin
  o[2] = 1
rescue IndexError => e
  p e.class
end

# a String keeps its bytes. Only those past the one assigned are printed:
# the store itself is dropped by the dispatch's default arm, with or without
# the Struct, and is not what this test is about.
s = [+("draft" * 4), pt][0]
s[0] = "D"
p s[1..], s.length
t = [+("draft" * 4), 1][0]
t[2] = "A"
p t[3..], t.bytes.count(0)
