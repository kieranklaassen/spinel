# Regexp#match?(str, pos) counts pos in characters, as String#match?(re, pos)
# and Regexp#match(str, pos) do. It counted bytes, so past a multi-byte
# character the search began too early or was let begin beyond the end.
s = "éab"
p /a/.match?(s, 1), /a/.match?(s, 2), /b/.match?(s, 2), /b/.match?(s, 3)
p /é/.match?(s, 0), /é/.match?(s, 1)
p //.match?(s, 3), //.match?(s, 4)
p /a/.match?(s, -2), /a/.match?(s, -1), /é/.match?(s, -3), /é/.match?(s, -4)
p /\Aa/.match?(s, 1), /\Ga/.match?(s, 1), /\Ga/.match?(s, 0)

t = "日本語のテキスト"
p /の/.match?(t, 3), /の/.match?(t, 4), /ト\z/.match?(t, 7), /ト/.match?(t, 8), //.match?(t, 9)

# the String's own form and Regexp#match agree
p s.match?(/a/, 2), s.match?(/b/, 2), /a/.match(s, 2).nil?, /b/.match(s, 2)[0]

# a String of single bytes counts as it did
u = "xaybzab"
p /b/.match?(u, 0), /b/.match?(u, 4), /b/.match?(u, 6), /b/.match?(u, 7), /b/.match?(u, -1), /b/.match?(u, -8)
b = "\xC3\xA9ab".b
p /a/n.match?(b, 2), /a/n.match?(b, 3), //n.match?(b, 4), //n.match?(b, 5)
