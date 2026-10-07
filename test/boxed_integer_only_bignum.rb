# spinel: int64
# A boxed Bignum is an Integer: odd? and even? answer its own parity, and
# chr with an encoding raises RangeError, as before the receiver's class
# was tested.

def t
  p yield
rescue NoMethodError, ArgumentError, RangeError => e
  p e.class
end

k = ARGV.size
[2**70 + 1, 2**70, -(2**70) - 1, "s"].each do |v|
  n = [v, 0][k]
  t { n.odd? }
  t { n.even? }
  t { n.chr(Encoding::UTF_8) }
end
