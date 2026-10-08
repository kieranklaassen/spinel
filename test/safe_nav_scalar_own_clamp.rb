# A program with a clamp of its own on Numeric: a Float's `&.` call with a
# boxed bound still reaches it.
def id(x) = x
id(:s)
class Numeric
  def clamp(a, b) = "num"
end
def flt(v) = v ? 1.5 : nil
f = flt(true); g = flt(false)
p f&.clamp(id(1.0), id(1.2)), g&.clamp(id(1.0), id(1.2))
p f&.clamp(1.0, id(1.2)), f&.clamp(id(1), 2)
