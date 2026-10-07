# test/boxed_string_key_not_index.rb with a String that has a `[]=` of its
# own: the key is that method's to take, so a boxed String given a Symbol,
# nil or true key raises nothing here, as in CRuby.
class String
  def []=(k, v)
    $n = $n.to_i + 1 if k.is_a?(Integer)
    v
  end
end

def pick(n) = n > 0 ? { a: 1 } : +"st"

keys = [:a, nil, true]
s = pick(0)
keys.each { |k| s[k] = "x" }
p s, $n
