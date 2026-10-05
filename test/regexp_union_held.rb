# Regexp.union takes a Regexp that is no literal the compiler can name --
# held in a parameter or a global, or answered by a call -- beside Strings
# and literals, and alone. It was refused at compile time.
$g = /b(z)/
def alone(re) = Regexp.union(re)
def three(re, s) = Regexp.union(re, s, /q/i)
def two(a, b) = Regexp.union(a, b)
def made = /a(y)/

p alone(/a.b/i), alone(/a.b/i).source
p three(/a|b/, "x.y"), three(/a|b/, "x.y").source
p two(/a/m, /b/x), Regexp.union($g, made, "c"), Regexp.union(made)
p "xaybzab" =~ three(/zz/, "bz"), "xQx" =~ three(/zz/, "bz"), "xaybzab" =~ three(/zz/, "zz")

# one never set is nil
re = /b/ if $g.source.empty?
[-> { Regexp.union(re) }, -> { Regexp.union(re, /a/) }].each do |f|
  begin
    p f.call
  rescue TypeError => e
    puts "TypeError: #{e.message}"
  end
end
