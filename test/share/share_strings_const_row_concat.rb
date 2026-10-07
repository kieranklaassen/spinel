# --share-strings: a row of a constant's table held under a local and given
# a String Array by concat. Without the flag the local is the row
# (test/const_table_row_under_local.rb). Under the flag it is as it was:
# with the rows general Arrays the flag refuses the String literal handed
# to concat once the table is walked.

T = [[1, 2], [3, 4], [5, 6]]
e = T[1]
e.concat(["s"])
p e
T.each { |a, b| p [a, b] }
