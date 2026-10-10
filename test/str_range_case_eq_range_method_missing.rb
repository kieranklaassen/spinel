# As test/str_range_case_eq_range_to_str.rb, with the to_str answered by a
# method_missing the program gives Range.
class Range
  def method_missing(name, *args)
    "c"
  end

  def respond_to_missing?(name, priv = false)
    true
  end
end

e = ("a"..)
q = [("a"..), 3]
puts "#{e === q[0]} #{e === q[1]}"
