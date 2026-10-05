# A String kept in a Hash or an Array beside an Integer sits in a box, and
# once the program appends to it the box holds the shared String. A String
# Array's search, a String Range's include?, casecmp and pack read it as
# the String it is.
h = { "k" => +"ab", "n" => 1 }
h["k"] << "c"
words = %w[abc cd abc]
p words.include?(h["k"]), words.member?(h["k"])
p words.index(h["k"]), words.find_index(h["k"]), words.rindex(h["k"])
p words.include?(h["n"]), words.index(h["n"])
p "x abc y".split.include?(h["k"])
p ("abb".."abd").include?(h["k"]), ("abb".."abd").cover?(h["k"])
p "ABC".casecmp(h["k"]), "ABC".casecmp?(h["k"]), "abd".casecmp(h["k"])
p "ABC".casecmp(h["n"]), "ABC".casecmp?(h["n"])
p [h["k"]].pack("a4"), [h["k"], 65].pack("A2C"), [h["k"]].pack("m0")
p words.delete(h["k"]), words
p words.delete(h["k"]) { |x| "none" }
h["k"] << "d"
p %w[abc abcd].index(h["k"])

a = [+"ab", 1]
a[0] << "c"
p %w[x abc].include?(a[0]), %w[x abc].index(a[0])
p "Abc".casecmp?(a[0]), [a[0]].pack("a2")
