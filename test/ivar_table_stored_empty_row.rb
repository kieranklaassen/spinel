# An empty row stored into an instance variable's table of Integer rows is
# built as a row of that table: its reader takes each row as an Integer Array.

class Grid
  def initialize
    @rows = [[1, 2], [3, 4]]
  end

  def push_row
    @rows << []
    p @rows[2], @rows[2].size, @rows[2].empty?
    @rows[2] << 5
    p @rows[2], @rows[2][0] + 1
  end

  def set_row
    @rows[0] = []
    p @rows[0], @rows[0].size, @rows.size
    r = @rows[0]
    r << 7
    p @rows[0], @rows[1][1]
  end

  def two_rows
    @rows.push([], [8])
    @rows.append([])
    p @rows[3].size, @rows[4], @rows[5].size, @rows.last.empty?
  end
end
g = Grid.new
g.push_row
g.set_row
g.two_rows

# an adjacency list whose nodes lose their edges
class Adj
  def initialize(n)
    @adj = Array.new(n) { [0] }
  end

  def reset(i)
    @adj[i] = []
  end

  def link(a, b)
    @adj[a].push(b)
  end

  def degree(i)
    @adj[i].size
  end

  def edges(i)
    @adj[i]
  end
end
a = Adj.new(3)
a.reset(1)
p a.degree(1), a.edges(1), a.degree(0)
a.link(1, 2)
a.link(1, 0)
p a.degree(1), a.edges(1), a.edges(1).sum
