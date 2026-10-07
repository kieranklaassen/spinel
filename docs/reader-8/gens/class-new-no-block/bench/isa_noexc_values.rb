class MyErr < StandardError; end
class Plain; end
xs = [MyErr.new("never"), Plain.new, 3, "s", nil, 4.5, :sym, [1], { a: 1 }, 1..2]
n = 0
i = 0
while i < 200_000
  xs.each { |x| n += 1 if x.is_a?(MyErr) }
  i += 1
end
p n
