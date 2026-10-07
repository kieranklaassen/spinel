# An END body runs at exit inside whichever method is running. A program whose
# END body reads the registers keeps them as they are, so a method that matches
# only in a `when` arm saves no frame there: the END body reads the top level's
# match from inside it.
END { p $1 }

def kind(v)
  exit if v == "x"
  case v
  when /a/ then :a
  else :other
  end
end

"top" =~ /t(o)p/
kind("x")
