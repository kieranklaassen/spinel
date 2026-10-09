# cover? of a String Range stands on String#<=>. This program gives String
# a <=> of its own in the text of an ERB template. This compiler's ERB
# does not run the text. The cover? of a boxed appended String keeps the
# answer it had: the one the program's <=> gives in CRuby.
require "erb"
h = {"k" => "a".dup, "n" => 1}
h["k"] << "b"
r = ("aa".."az")
begin
  ERB.new("<% class String; def <=>(o) = 1; end %>", trim_mode: nil).result_with_hash({})
rescue StandardError
end
p r.cover?(h["k"])
p r.cover?(h["n"])
