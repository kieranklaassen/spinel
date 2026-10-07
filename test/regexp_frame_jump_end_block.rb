# An END body runs at exit inside whichever method is running. A program whose
# END body reads the registers keeps them as they are: here it reads the top
# level's match, from inside a method that matches further down.
END { p $1 }

def late(s)
  exit if s == "x"
  s =~ /a(b)/
end

"top" =~ /t(o)p/
late("x")
