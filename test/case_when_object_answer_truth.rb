# `when obj` asks the object's own ===, and whatever it answers is read for
# its Ruby truth: only nil and false are a miss. The C word was read as it
# stood, so a 0 or a 0.0 was a miss and the nil of an Integer or a Float a
# hit; in a case value the arm was compared with == and never matched.
class IntOrNil
  def ===(o) = o > 2 ? 1 : nil
end
class Zero
  def ===(o) = 0
end
class FloatOrNil
  def ===(o) = o > 2 ? 0.0 : nil
end
class SymOrNil
  def ===(o) = o > 2 ? :yes : nil
end
class StrOrNil
  def ===(o) = o > 2 ? "yes" : nil
end
class Mixed
  def ===(o) = o > 2 ? "yes" : (o > 1 ? 0 : nil)
end
class Flag
  def ===(o) = o > 2
end
class EqZero
  def ==(o) = 0
end

def ask(n)
  out = []
  case n
  when IntOrNil.new then out << :int
  else out << :no_int
  end
  case n
  when Zero.new then out << :zero
  else out << :no_zero
  end
  case n
  when FloatOrNil.new then out << :float
  else out << :no_float
  end
  case n
  when SymOrNil.new then out << :sym
  else out << :no_sym
  end
  case n
  when StrOrNil.new then out << :str
  else out << :no_str
  end
  case n
  when Mixed.new then out << :mixed
  else out << :no_mixed
  end
  case n
  when Flag.new then out << :flag
  else out << :no_flag
  end
  case n
  when EqZero.new then out << :eq
  else out << :no_eq
  end
  out
end

p ask(1)
p ask(2)
p ask(5)

# a search that answers where it found the subject, in a case value
class OneOf
  def initialize(*xs) = @xs = xs
  def ===(o) = @xs.index(o)
end
small = OneOf.new(1, 2, 3)
p(case 1 when small then :hit else :miss end)
p(case 9 when small then :hit else :miss end)
p(case 5 when Zero.new then :hit else :miss end)
p(case 1 when IntOrNil.new then :hit else :miss end)
