def show
  r = yield
  puts "#{r.inspect} #{r.class}"
rescue StandardError => e
  puts "#{e.class}"
end
module Loud
  refine String do
    def *(o) = "custom(#{o})"
  end
end
using Loud
row = ["ab", 7]
src = [2.5, :k]
show { row[0] * src[0] }
