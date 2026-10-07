# A container that stores many of its own elements (`h[:b] = h[:a]`,
# `h[:c] = h[:b]`, ...) and has a String changed in place through one. The
# walk that demands the container's Strings as handles met each of those
# reads inside the walk another had begun and walked the stores once more
# for it: n such stores cost n! walks, and the compiler did not come back.

h = {a0: +"s"}
h[:a1] = h[:a0]
h[:a2] = h[:a1]
h[:a3] = h[:a2]
h[:a4] = h[:a3]
h[:a5] = h[:a4]
h[:a6] = h[:a5]
h[:a7] = h[:a6]
h[:a8] = h[:a7]
h[:a9] = h[:a8]
h[:a10] = h[:a9]
h[:a11] = h[:a10]
h[:a12] = h[:a11]
h[:a0] << "v"
p h.length, h[:a12], h[:a12].equal?(h[:a0])
h[:a12] << "w"
p h[:a0], h[:a6]

# an Array's slots
a = [+"t", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
a[1] = a[0]
a[2] = a[1]
a[3] = a[2]
a[4] = a[3]
a[5] = a[4]
a[6] = a[5]
a[7] = a[6]
a[8] = a[7]
a[9] = a[8]
a[10] = a[9]
a[11] = a[10]
a[12] = a[11]
a[0] << "v"
p a.length, a[12], a[12].equal?(a[0])

# a Hash an instance variable holds, read into a local that is appended to
class Slots
  def initialize
    @m = {a0: +"u", z: [1]}
  end

  def run
    @m[:a1] = @m[:a0]
    @m[:a2] = @m[:a1]
    @m[:a3] = @m[:a2]
    @m[:a4] = @m[:a3]
    @m[:a5] = @m[:a4]
    @m[:a6] = @m[:a5]
    @m[:a7] = @m[:a6]
    @m[:a8] = @m[:a7]
    @m[:a9] = @m[:a8]
    @m[:a10] = @m[:a9]
    @m[:a11] = @m[:a10]
    @m[:a12] = @m[:a11]
    x = @m[:a0]
    x << "v"
    p @m.length, @m[:a12], @m[:a12].equal?(@m[:a0])
  end
end
Slots.new.run

# a Hash a parameter holds
def fill(g)
  g[:a1] = g[:a0]
  g[:a2] = g[:a1]
  g[:a3] = g[:a2]
  g[:a4] = g[:a3]
  g[:a5] = g[:a4]
  g[:a6] = g[:a5]
  g[:a7] = g[:a6]
  g[:a8] = g[:a7]
  g[:a9] = g[:a8]
  g[:a10] = g[:a9]
  g[:a11] = g[:a10]
  g[:a12] = g[:a11]
  g[:a0] << "v"
  p g.length, g[:a12], g[:a12].equal?(g[:a0])
end
fill({a0: +"w"})
