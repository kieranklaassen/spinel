# An `each` the program gives Array is no part of what case/when with a
# String Range asks: in a block that map runs, a boxed String the Range
# covers takes the arm.
class Array
  def each
    self
  end
end

m = ["c", 5, "q", nil]
p m.map { |e|
  case e
  when "a".."m" then "low"
  else "other"
  end
}
