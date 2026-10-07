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
  xs.each do |x|
    case x
    when MyErr then n += 1
    when Plain then n += 10
    end
  end
  i += 1
end
p n
