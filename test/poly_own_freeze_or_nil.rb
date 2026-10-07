# A box of an object or nil, where the class has its own freeze: the object
# is frozen by its own method and comes back, and nil stays nil.
class Doc
  def initialize = @sealed = false
  def freeze
    @sealed = true
    super
  end
  def sealed = @sealed
  def set(x) = @x = x
end
none = nil
d = Doc.new
some = ARGV.size < 5 ? d : none
back = some.freeze
p back.equal?(d)
p d.sealed
p d.frozen?
p(((d.set(1); :ok) rescue $!.class))

gone = ARGV.size > 5 ? d : none
kept = gone.freeze
p kept.nil?
gone.freeze
p gone.nil?

# the value dropped
e = Doc.new
late = ARGV.size < 5 ? e : none
late.freeze
p e.sealed
p e.frozen?
