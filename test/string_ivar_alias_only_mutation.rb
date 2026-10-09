# `@t = @s.replace(x)` makes its copy after the call has changed @s, each
# time it runs. Where that call is the program's only mutation, nothing
# changes either name afterwards and the two read the same: it builds.
class Box
  def initialize = @s = +"ab"

  def fill(x)
    @t = @s.replace(x)
    p @s, @t
  end
end
b = Box.new
b.fill("cd")
b.fill("ef")
