# Under --int-overflow=promote an Integer `+`, `-` or `*` whose operands are
# not both literals is a boxed value, and so is the row that holds it. A
# constant mapped from a literal table with such a row read the row as an
# Integer array all the same.

BASE = 3
STEP = 5

ADDED = [[1, 2], [BASE + 1, 2]].map { |row| row.map { |n| n * 2 } }
p ADDED[0][0], ADDED[1][0], ADDED[1][1]

SUBBED = [[BASE - 1, 2], [3, 4]].map { |row| row.map { |n| n + 1 } }
p SUBBED[0][0], SUBBED[0][1], SUBBED[1][0]

TIMES = [[1, 2], [3, BASE * STEP]].map { |row| row.map { |n| n - 1 } }
p TIMES[1][1], TIMES[1][0], TIMES[0][0]

# below a division and inside parentheses, and three literals in a row
NESTED = [[1, 2], [(BASE + 1) / 2, 1 + 2 + 3]].map { |row| row.map { |n| n * 3 } }
p NESTED[1][0], NESTED[1][1], NESTED[0][1]

# the block reads the row itself
SUMS = [[1, 2], [BASE + STEP, 2]].map { |row| row.sum }
p SUMS[0], SUMS[1]

module Held
  CELLS = [[STEP * 2, 1], [2, 1 + BASE]].map { |row| row.map { |n| n + 100 } }
  def self.cell(i, j) = CELLS[i][j]
end
p Held.cell(0, 0), Held.cell(1, 1), Held.cell(1, 0)

# as before: literals, two literals that stay in the word, and the
# operators that cannot leave it
PLAIN = [[7, 8], [9, 10 + 1]].map { |row| row.map { |n| n * 12 } }
p PLAIN[1][1], PLAIN[0][0]
KEPT = [[BASE / 2, BASE % 2], [-BASE, 6 * 7]].map { |row| row.map { |n| n + 1 } }
p KEPT[0][0], KEPT[0][1], KEPT[1][0], KEPT[1][1]
