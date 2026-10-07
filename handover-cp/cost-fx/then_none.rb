class K; end
row = [5, 6, 7, 8, K.new, "q"]
n = 0
i = 0
while i < 300_000
  x = row[i % 4]
  e = x.then
  n += 1 if e
  i += 1
end
p n
