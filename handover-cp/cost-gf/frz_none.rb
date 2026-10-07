class K; end
row = [5, "q", nil, :s, 2.5, K.new]
n = 0
i = 0
while i < 3_000_000
  x = row[i % 6]
  n += 1 if x.frozen?
  i += 1
end
p n
