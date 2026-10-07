# An instance variable handed to the aliased method: CRuby prints "az!".
class K
  def add(v) = v << "!"
  alias add2 add
  def run
    @s = +"az"
    add(@s)
    @s
  end
end
p K.new.run
