class MyErr < StandardError; end
class Other < StandardError; end
class Plain; end
xs = []
begin; raise MyErr, "a"; rescue => e; xs << e; end
begin; raise Other, "b"; rescue => e; xs << e; end
begin; raise KeyError, "c"; rescue => e; xs << e; end
xs << MyErr.new("never") << Plain.new << 3 << "s" << nil << 4.5 << :sym
n = 0
i = 0
while i < 200_000
  xs.each { |x| n += 1 if x.is_a?(Plain) }
  i += 1
end
p n
