# The snapshot is hand-written: CRuby builds a String Range for (x..y) with
# two Strings, which a Range decided at run time cannot hold here.
# A boxed String or Symbol as a bound of an Integer Range was converted (a
# String as its leading digits, a Symbol as its id): (1..x) with x "ab" was
# 1..0 and (x..x) was 0..0. Beside an Integer begin it is CRuby's
# ArgumentError; otherwise the Range is refused when it is built.
h = {"s" => "ab", "d" => "7", "y" => :a, "i" => 3, "f" => 2.5, "n" => nil}
def t
  p yield
rescue ArgumentError, NotImplementedError => e
  puts "#{e.class}: #{e.message}"
end
t { (1..h["s"]).to_a }
t { (1..h["d"]).to_a }
t { (1...h["s"]).size }
t { (1..h["y"]).to_a }
t { (h["i"]..h["s"]).to_a }
t { (1..h["s"]).include?(0) }
t { [*1..h["s"]] }
t { case 0 when 0..h["s"] then :in else :out end }
t { for i in 1..h["s"] do p i end; :done }
t { (h["s"]..h["s"]).to_a }
t { (h["s"]..3).to_a }
t { (h["y"]..h["y"]).to_a }
t { (h["n"]..h["s"]).end }
t { for i in h["s"]..3 do p i end; :done }
# the bounds an Integer Range does take are read as before
t { (1..h["i"]).to_a }
t { (h["i"]..5).to_a }
t { (h["i"]..h["i"]).to_a }
t { (1..h["f"]).to_a }
t { (1..h["n"]).first(2) }
t { for i in 1..h["i"] do print i end; :done }
