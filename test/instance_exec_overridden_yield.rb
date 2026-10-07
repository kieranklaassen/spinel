# A bare call, inside instance_exec or instance_eval, of a yielding method
# that a subclass of the receiver overrides: the call goes through the class
# switch, and its value is the block's.
class B
  def m(x)
    yield x
  end
end
class S < B
  def m(x)
    yield x + 10
  end
end
p(B.new.instance_exec { m(10) { |v| v + 1 } })
p(S.new.instance_exec { m(10) { |v| v + 1 } })
p(B.new.instance_eval { m(10) { |v| v * 2 } })
p(S.new.instance_eval { m(10) { |v| v.to_s } })
x = S.new.instance_exec { m(1) { |v| v > 5 } }
p x
B.new.instance_exec { m(3) { |v| v + 1 }; nil }
p(S.new.instance_exec { m(2) { |v| [v] } })
