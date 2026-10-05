# Literals that are not what the block form answers: each method here
# answers self to a caller with a block, and stays each-like.
#
# `block_given?.nil?` never holds, so a return under it is not the to_enum
# guard: the Array that ends Tree#each runs only without a block.
class Tree
  def initialize
    @kids = [1, 2]
  end
  def each
    return nil if block_given?.nil?
    if block_given?
      @kids.each { |x| yield x }
      return self
    end
    return to_enum(:each) unless $skip
    [0]
  end
end
class Bush
  def initialize
    @kids = [3]
  end
  def each
    return to_enum(:each) unless block_given?
    @kids.each { |x| yield x }
    self
  end
end
$skip = false
[Tree.new, Bush.new].each { |t| p t.each.with_index.to_a }
[Tree.new, Bush.new].each { |t| p t.each.to_a }
