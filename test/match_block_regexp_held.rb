# String#match with a block takes a Regexp that is no literal the compiler can
# name -- held in a parameter or a global, answered by a call, or
# interpolated -- as it takes the literal: the block runs on a hit and its
# value is the call's. The generated C did not compile.
$g = /b(z)/
def size_of(s, re)
  s.match(re) do |m|
    puts "hit #{m[0]} at #{m.begin(0)}"
    m[0].size
  end
end
def joined(s, re) = s.match(re) { |m| m[0] + m.pre_match }
def made = /a(y)/

p size_of("xaybzab", /a./), size_of("xaybzab", /Q/)
p joined("xaybzab", /b/), joined("xaybzab", /q/)
p "xaybzab".match($g) { |m| m[1] }, "xaybzab".match(made) { |m| m[1] }
x = "z"
p "xaybzab".match(/b#{x}/) { |m| m.post_match }

# one never set is nil
re = /b/ if x.empty?
begin
  p "xaybzab".match(re) { |m| m[0] }
rescue TypeError => e
  puts "TypeError: #{e.message}"
end
