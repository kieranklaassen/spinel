# A bare call of a builtin written in Ruby, in a class that includes
# Enumerable, is spliced whatever follows the name: `;`, `{`, `,`, `]`, `.`
# or `==`, not only `(`, a space or the end of the line.
class Bag
  include Enumerable
  def initialize(a); @a = a; end
  def each; @a.each { |x| yield x }; end
  def counts; tally; end
  def split; partition{ |x| x > 1 }; end
  def twice; [tally, tally]; end
  def label = "kinds=#{tally.size}"
  def same?(other) = tally==other.counts
end

bag = Bag.new([1, 1, 2])
p bag.counts.to_a
p bag.split
p bag.twice.map(&:to_a)
puts bag.label
p bag.same?(Bag.new([2, 1, 1])), bag.same?(Bag.new([2]))
