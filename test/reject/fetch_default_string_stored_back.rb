# A String that is the default of `fetch`, stored back into the Hash it was
# fetched from and appended to through the Hash, is not yet shared by
# reference: refused, not silently appended to a copy.
h = {}
%w[a b a].each do |w|
  h[w] = h.fetch(w) { +"" }
  h[w] << "!"
end
p h
