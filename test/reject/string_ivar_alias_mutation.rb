# An instance variable assigned from another is a second name for the one
# String. No alias walk makes the two one handle, so @t holds a copy and
# the append never reaches @s: refused, not compiled with "a".
# spinel: reject-share
class Box
  def initialize = @s = +"a"
  def go
    @t = @s
    @t << "!"
    p @s
  end
end
Box.new.go
