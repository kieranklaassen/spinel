# cover? of a String Range stands on String#<=>. This program puts
# Kernel's <=> ahead of String's by a prepend. No text of the program's
# has a <=>: Kernel's answers nil for two Strings that differ, so the
# Range covers nothing. The cover? of a boxed appended String keeps the
# answer it had, which is CRuby's.
class String
  prepend Kernel
end

h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("aa".."az")
p r.cover?(h["k"])
p r.cover?(h["n"])
