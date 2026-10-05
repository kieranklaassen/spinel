# `h[k] = h.fetch(k, v)` stores v where k is missing. A String that is the
# default of `fetch` is not yet shared by reference, so the append through
# h[k] would land in a copy: refused, where the first store has to miss.
h = {}
%w[a b a].each do |w|
  k = w.to_sym
  h[k] = h.fetch(k, +"")
  h[k] << "!"
end
p h.to_a
