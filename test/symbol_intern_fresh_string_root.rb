# A String made in place is kept alive while it becomes a new Symbol.

# names long enough that the pool's own copy collects in a plain run
pad = "k" * 20000
syms = []
200.times { |i| syms << (pad + i.to_s).to_sym }
lost = 0
syms.each_with_index { |s, i| lost += 1 unless s.to_s == pad + i.to_s }
p lost

p ("a" + "b").to_sym
p "x".succ.to_sym
p ("k" + 1.to_s).to_sym.to_s
p :"q#{1 + 1}"
a = [("m" + "1").to_sym, ("m" + "2").to_sym]
p a
p ("n" + "1").to_sym == ("n" + "1").to_sym

bad = 0
i = 0
while i < 2000
  s = ("k" + i.to_s).to_sym
  bad += 1 unless s.to_s == "k#{i}" && s == ("k" + i.to_s).to_sym
  i += 1
end
p bad
