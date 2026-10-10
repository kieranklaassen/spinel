# As test/case_when_str_range_range_to_str.rb, with the to_str answered by
# a method_missing the program gives Range.
class Range
  def method_missing(name, *args)
    "c"
  end

  def respond_to_missing?(name, priv = false)
    true
  end
end

def held(v, r)
  case v
  when r then "in"
  else "out"
  end
end

q = [("a"..), 3]
puts "#{held(q[0], ("a"..))} #{held(q[1], ("a"..))}"
