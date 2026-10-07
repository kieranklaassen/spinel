# scrub with a block on a boxed receiver dropped its block: each invalid
# sequence became U+FFFD, the block was never called, and a replacement
# given beside the block did not raise.

# a String read out of an Array of mixed values
a = ["ab\xFEcd\xFD\xFCef", 1]
p a[0].scrub { "?" }
p a[0].scrub { |b| "<" + b.unpack1("H*") + ">" }
seen = []
r = a[0].scrub { |b| seen << [b.bytes, b.encoding.to_s, b.valid_encoding?]; "-" }
p seen
p r, r.encoding.to_s, r.valid_encoding?

# a Hash's value, a method's value, a reader's value
h = { "k" => "x\xE3\x81y", "n" => 2 }
p h["k"].scrub { |b| b.bytesize.to_s }
def pick(v) = v
x = pick("q\xFFr")
i = pick(3)
p x.scrub { |b| "!" }, i
class Box
  def initialize(v)
    @v = v
  end
  def v = @v
end
b1 = Box.new("m\xC0\xAFn")
b2 = Box.new(7)
p b1.v.scrub { |b| "_" }, b2.v

# the block is called once for each invalid sequence, and not for a valid String
n = 0
p a[0].scrub { n += 1; n.to_s }, n
v = ["a\xC3\xA9b", 1]
p v[0].scrub { n += 10; "?" }, n

# nil beside the block is no replacement; a String beside it raises
p a[0].scrub(nil) { |b| b.bytesize.to_s }
begin
  p a[0].scrub("!") { |b| "?" }
rescue ArgumentError => e
  puts e.message
end

# the block's answer is converted and checked as for a String receiver
begin
  p a[0].scrub { 1 }
rescue TypeError => e
  puts e.class
end

# a binary String has no invalid sequence
bin = ["ab\xFE\xFDcd".b, 1]
r = bin[0].scrub { n += 100; "?" }
p r, r.encoding.to_s, n

# a receiver that is no String at run time
a.each do |e|
  begin
    p e.scrub { |b| "." }
  rescue NoMethodError => err
    puts err.class
  end
end

# without a block, as before
p a[0].scrub, a[0].scrub("!")
