# The Hash's default block stores the String.
h = Hash.new { |hh, k| hh[k] = +"q" }
h[:a]
h.each_value { |x| x << "!" }
p h
