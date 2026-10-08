# A Regexp's own =~, !~, ===, match and match? over a subject that is nil:
# nothing matches, and $~ reads nil afterwards (match? leaves $~ alone).
# The earlier match stayed in $~, and a boxed nil was matched as "".

def str_or_nil(f) = f ? "abc" : nil
def boxed(i) = [nil, "abc"][i]

w = "x"
dyn = Regexp.new(w + "*")

puts "=~"
"abc" =~ /b/
p(/x*/ =~ nil, $~)
"abc" =~ /b/
p(/x*/ =~ str_or_nil(false), $~)
"abc" =~ /b/
p(/x*/ =~ boxed(0), $~)
"abc" =~ /b/
p(/#{w}*/ =~ str_or_nil(false), $~)
"abc" =~ /b/
p(dyn =~ boxed(0), $~)

puts "!~"
"abc" =~ /b/
p(/x*/ !~ nil, $~)
"abc" =~ /b/
p(/x*/ !~ str_or_nil(false), $~)
"abc" =~ /b/
p(/x*/ !~ boxed(0), $~)
"abc" =~ /b/
p(dyn !~ str_or_nil(false), $~)

puts "match"
"abc" =~ /b/
p(/x*/.match(nil), $~)
"abc" =~ /b/
p(/x*/.match(str_or_nil(false)), $~)
"abc" =~ /b/
p(/x*/.match(boxed(0)), $~)
"abc" =~ /b/
p(/x*/.match(boxed(0), 0), $~)
"abc" =~ /b/
p(/x*/.match(boxed(0)) { |m| m[0] + "!" }, $~)
"abc" =~ /b/
p(dyn.match(boxed(0)), $~)
"abc" =~ /b/
p(dyn.match(nil) { |m| m[0] + "!" }, $~)

puts "match?"
"abc" =~ /b/
p(/x*/.match?(boxed(0)), $~[0])
"abc" =~ /b/
p(/x*/.match?(boxed(0), 0), $~[0])
"abc" =~ /b/
p(dyn.match?(boxed(0)), $~[0])

puts "==="
"abc" =~ /b/
p(/x*/ === str_or_nil(false), $~)
"abc" =~ /b/
p(dyn === nil, $~)
"abc" =~ /b/
p(dyn === boxed(0), $~)

puts "named"
"abc" =~ /(?<n>b)/
if /(?<n>b)/ =~ str_or_nil(false)
  p 1
else
  p n, $~
end

puts "a String still matches"
p(/x*/ =~ str_or_nil(true), $~[0])
p(/b/ !~ boxed(1), $~[0])
p(/b/.match(boxed(1))[0], $~[0])
p(/c/.match?(boxed(1)), $~[0])
p(/c/ === str_or_nil(true), $~[0])
p(dyn === "abc", dyn === boxed(1))
