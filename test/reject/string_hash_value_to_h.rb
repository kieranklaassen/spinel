# The block of `to_h` answers the pair that holds the String.
h = %w[a b].to_h { |k| [k, +"q"] }
h.each_value { |x| x << "!" }
p h
