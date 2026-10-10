# spinel: gc-stress
# case/when with a String Range and a boxed subject: the arm is taken when
# the subject is a String the Range covers. The test was an equality of the
# subject and the Range, so no String took the arm.
def band(v)
  case v
  when "a".."m" then "low"
  when "n".."z" then "high"
  when 1..9 then "digit"
  else "other"
  end
end

def edge(v)
  case v
  when ("a"..."c") then "excluded"
  when (.."f") then "beginless"
  when ("x"..) then "endless"
  else "none"
  end
end

def many(v)
  case v
  when 1, ("a".."c"), :s then "hit"
  else "miss"
  end
end

def held(v, r)
  case v
  when r then "in"
  else "out"
  end
end

def value(v)
  w = case v
      when "a".."m" then 1
      else 2
      end
  w
end

h = {"k" => "a".dup, "p" => "q", "n" => 5}
h["k"] << "b"
a = ["zz".dup, 3]
a[0] << "z"

puts "band: #{band("c")} #{band("q")} #{band(5)} #{band(nil)} #{band(:c)} #{band("")} #{band("A")}"
puts "band hash: #{band(h["k"])} #{band(h["p"])} #{band(h["n"])} #{band(h["none"])}"
puts "band array: #{band(a[0])} #{band(a[1])}"
puts "edge: #{edge("b")} #{edge("c")} #{edge("e")} #{edge("y")} #{edge("m")} #{edge(4)}"
puts "edge hash: #{edge(h["k"])} #{edge(h["p"])} #{edge(a[0])}"
puts "many: #{many("b")} #{many("d")} #{many(1)} #{many(:s)} #{many(h["k"])}"
puts "held: #{held("m", ("a".."m"))} #{held("n", ("a".."m"))} #{held(h["k"], ("a".."m"))} #{held(7, ("a".."m"))}"
puts "value: #{value("c")} #{value("q")} #{value(3)} #{value(h["k"])}"

# a subject made by the case itself
def pick(i)
  i % 2 == 0 ? "k#{i % 10}" : i
end
bad = 0
i = 0
while i < 200
  got = case pick(i)
        when ("k0".."k9") then true
        else false
        end
  bad += 1 unless got == (i % 2 == 0)
  i += 1
end
puts "made by the case: #{bad}"

# a nil held where the Array holds handles is no String
def some(i)
  i > 0 ? "ab" : nil
end
n = ["a".dup, 2, some(0)]
n[0] << "b"
puts "nil beside a handle: #{band(n[2])} #{band(n[0])}"

# compared by the bytes: a NUL past the end is outside the Range
z = {"k" => "m\0", "n" => 5}
puts "NUL past the end: #{band(z["k"])} #{held(z["k"], ("a".."m"))}"

# a binary String is not the UTF-8 one of the same bytes
def accent(v)
  case v
  when "\u00E9".."\u00E9" then "in"
  else "out"
  end
end
e = {"b" => "\xC3\xA9".b, "u" => "\u00E9", "n" => 5}
puts "binary: #{accent(e["b"])} #{accent(e["u"])}"

# a Range whose two ends are made where it is written
vals = ["k5", 1, nil, "z5"]
lo = "k"
hits = 0
i = 0
while i < 200
  x = vals[i % 4]
  case x
  when (lo + "0")..(lo + "9") then hits += 1
  end
  i += 1
end
puts "ends made on the spot: #{hits}"
