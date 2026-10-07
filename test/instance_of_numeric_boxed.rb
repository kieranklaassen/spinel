# spinel: int64 -- a Bignum among the values
# instance_of? asks for the object's own class: no number is an instance of
# Numeric itself, on a boxed receiver as on a typed one.
vals = [1.5, "s", 1, :a, nil, 2**70, 1r, 2i]
vals.each do |v|
  p [v.instance_of?(Numeric), v.is_a?(Numeric), v.kind_of?(Numeric), Numeric === v]
end
p vals.count { |v| v.instance_of?(Numeric) }, vals.count { |v| v.is_a?(Numeric) }
p vals.select { |v| v.instance_of?(Numeric) }.size

def exact(v) = v.instance_of?(Numeric) ? "numeric" : "other"
p exact(1), exact(1.5), exact("s")

def own(v) = v.instance_of?(Integer) || v.instance_of?(Float)
p own(1), own(1.5), own(1r)

p 1.5.instance_of?(Numeric), 1.instance_of?(Numeric)
