# A constant whose String the program made (`String.new`, `+"lit"`, a dup)
# handed to a proc that appends to its parameter: the proc is handed a copy,
# so the append would not reach the constant's String. Refused rather than
# compiled with the append lost, as a global's is.
BUF = String.new
add = ->(t) { t << "!" }
add.call(BUF)
puts BUF
