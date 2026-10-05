# A String grown with << and read back out of a Hash or an Array is found by
# its text: in an Array of Strings (include?, member?, index, find_index,
# rindex, delete), in a Range of Strings (include?, member?, cover?) and by
# casecmp and casecmp?.
s = +"cd"
s << "e"
h = { k: s, n: 1 }       # same with h[:k] = s, an Array element, a String key
v = h[:k]
p v                      # "cde"

words = ["cd", "cde", "cdf"]
p words.include?(v)
p words.member?(v)
p words.index(v)
p words.find_index(v)
p words.rindex(v)
p %w[cd cde].include?(h[:k])
p words.include?(h.fetch(:k))
puts "known" if words.include?(v)

def known?(x) = %w[cd cde].include?(x)
p known?(h[:k])
p known?(h[:n])          # an Integer is still not there
p known?(nil)

a = [s, 2]
p words.index(a[0])
p words.include?(a.first)

d = ["cd", "cde", "cdf", "cde"]
p d.delete(v)
p d
p d.delete(v)            # nil: both are gone
p d.delete(v) { "none" }
e = ["cde"]
p e.delete(h[:k]) { "none" }
p e
e.delete(h[:n])
p e

r = "cda".."cdz"
p r.include?(v)
p r.member?(v)
p r.cover?(v)
p ("cdf".."cdz").include?(v)
p r.include?(h[:n])
begin
  p ("cda"..).include?(v)
rescue => x
  puts "#{x.class}: #{x.message}"
end

p "CDE".casecmp(v)
p "CDE".casecmp?(v)
p "CDF".casecmp(v)
p "CDF".casecmp?(v)
p "CDE".casecmp(h[:n])
p "CDE".casecmp?(h[:n])

# the same String never grown is found as before
t = "cd" + "e"
g = { k: t, n: 1 }
p words.include?(g[:k]), words.index(g[:k]), r.include?(g[:k]), "CDE".casecmp?(g[:k])
