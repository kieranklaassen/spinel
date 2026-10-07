# A local assigned from the value parameter names the stored String too:
# its append must not go to a copy.
h = {}
h[:k] = +"a"
h.each_value { |v| t = v; t << "!" }
p h
