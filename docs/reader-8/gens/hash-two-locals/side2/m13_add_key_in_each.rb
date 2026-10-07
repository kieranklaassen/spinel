h = {a: 1, b: 2, c: 7}
begin
  h.each { |_k, v| h[:n] = v }
rescue => e
  p e.class
end
p h.size
