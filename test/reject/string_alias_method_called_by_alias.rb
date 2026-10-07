# The same by the alias's own name, with `alias_method` and a call on
# self: CRuby prints "az!".
class K
  def add(v)
    v << "!"
    v
  end
  alias_method :add2, :add
  def run
    s = +"az"
    add2(s)
    s
  end
end
p K.new.run
