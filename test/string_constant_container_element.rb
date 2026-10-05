# A String in a constant's Array or Hash that is changed in place through
# the constant (`A[0] << "x"`, `H[:k].upcase!`) changed a copy: the walk
# from a container back to the Strings its writes store followed a local,
# an ivar and a global, and stopped at a constant, so the constant's
# Strings were never made shared. Once they are, an `each` whose block
# appends and a local read from the Array reach them too. Each append is
# 100 bytes, so it cannot land in spare capacity by chance.
A = [+"a", +"b"]
A[0] << "x" * 100
p A[0].size, A[1]
A[1].replace("q" * 50)
A[1].insert(0, ">")
A[1].gsub!("q", "Q")
p A[1].size, A[1][0, 3]
A.each { |s| s << "!" }
p A.map(&:size)
t = A[1]
t << "?"
p A[1].size

H = { "k" => +"v", "j" => +"w" }
H["k"] << "y" * 100
H["j"].upcase!
p H["k"].size, H["j"]
H.each_value { |v| v << "." }
p H["j"]

# nested, built by map, and read inside a method and a block
N = [[+"n"], [+"o"]]
N[0][0] << "!"
p N[0][0], N[1][0]
B = %w[a b].map { |x| x + "" }
B[1] << "+" * 100
p B[1].size, B[0]
class Table
  ROWS = [+"r1", +"r2"]
  def mark(i) = ROWS[i] << "*" * 100
  def row(i) = ROWS[i]
end
Table.new.mark(1)
p Table.new.row(1).size, Table::ROWS[0]
[0, 1].each { |i| A[i] << "#" }
p A.map(&:size)

# a frozen element still raises, a frozen Array of Strings made there is
# still changed, and the Strings survive collections
F = ["lit", "x"]
begin; F[0] << "z"; rescue FrozenError => e; p e.class; end
p F[0]
G = [+"g"].freeze
G[0] << "h" * 100
p G[0].size
500.times { A[0] << "z" * 100 }
p A[0].size
