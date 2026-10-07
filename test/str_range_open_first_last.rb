# #first of a beginless String Range and #last of an endless one raise
# RangeError. They answered nil, which is #begin's and #end's answer.
def t
  p yield
rescue RangeError => e
  puts "RangeError: #{e.message}"
end
t { ("aa"..).last }
t { (.."ad").first }
t { ("aa"...).last }
t { (..."ad").first }
r = ("aa"..)
t { r.last }
t { r.first }
t { r.begin }
t { r.end }
q = (.."ad")
t { q.first }
t { q.last }
t { q.begin }
t { q.end }
t { ("aa".."ad").first }
t { ("aa".."ad").last }
