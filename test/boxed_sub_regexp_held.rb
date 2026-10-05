# sub and gsub on a boxed String take a Regexp that is no literal the compiler
# can name -- held in a parameter or a global -- as they take the literal.
# They raised NoMethodError.
def first(v, re) = v.sub(re, "Q")
def every(v, re) = v.gsub(re, "Q")
def table(v, re) = v.gsub(re, "a" => "1", "b" => "2")
$g = /[ab]/
v = [1, "xaybzab"][1]
p first(v, /b/), every(v, /b/), table(v, /[ab]/), first(v, /q/)
p v.sub($g, "Q"), v.gsub($g, "<\\0>")

# one never set is nil
re = /b/ if v.empty?
begin
  p v.sub(re, "Q")
rescue TypeError => e
  puts "TypeError: #{e.message}"
end
