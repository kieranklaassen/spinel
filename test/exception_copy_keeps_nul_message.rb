# Exception#exception(m) keeps the bytes of a message past its NUL, as a raise does.
class Mine < StandardError
  def initialize(m, code)
    super(m)
    @code = code
  end
  attr_reader :code
end

def made(s)
  s + ""
end

def show(tag, e)
  m = e.message
  puts "#{tag} #{e.class} #{m.bytesize} #{m.bytes.inspect}"
end

e = RuntimeError.new("first")
show "literal", e.exception("AAAAAAAAAA\0tail")
show "built", e.exception(made("ab") + "\0" + made("cd"))
show "leading", e.exception("\0abc")
show "trailing", e.exception("abc\0")
show "two", e.exception("a\0b\0c")
show "plain", e.exception("plain")
show "receiver", e

m = Mine.new("mine", 7)
c = m.exception("x\0y")
show "subclass", c
puts c.code
show "its receiver", m

x = [5, "p\0q"][1]
show "mixed", e.exception(x)

begin
  raise e.exception("in\0raise")
rescue => r
  show "raised", r
  puts r.inspect.bytes.inspect
end

show "twice", e.exception("l1\0l2").exception("again\0again")

t = 0
300.times { |i| t += e.exception("n#{i}\0z").message.bytesize }
puts t
