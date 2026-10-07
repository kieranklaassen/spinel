# #first of a beginless String Range and #last of an endless one raise
# RangeError on a boxed Range too. sp_poly_first and sp_poly_last answered
# the absent bound, which printed nil.
def t
  p yield
rescue RangeError => e
  puts "RangeError: #{e.message}"
end
h = { a: ("aa"..), b: (.."ad"), c: ("aa".."ad"), n: 1 }
t { h[:a].last }
t { h[:b].first }
t { h[:a].first }
t { h[:b].last }
t { h[:c].first }
t { h[:c].last }
t { [(.."ad"), 1].first.first }
t { [("aa"..)].map { |r| r.last } }
t { [(.."ad")].map(&:first) }
def one(x) = x.first
p one([1, 2])
t { one((.."ad")) }
t { h.fetch(:a).send(:last) }
