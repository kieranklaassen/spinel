module A
  def who = "A"
  def initialize
    @n = 1
  end
end
module B
  include A
  def who = "B#{@n}#{@m}"
  def initialize
    @m = 2
  end
end
class C
  include B
  include A
end
p C.new.who
