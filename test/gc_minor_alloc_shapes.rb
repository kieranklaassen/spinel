# The allocation benchmarks' shapes at a size the generational verifier can
# walk. bm_gcbench, bm_binary_trees and bm_linked_list are where a change to
# the allocator, the write barrier or the rooting of a constructor is
# measured, and under SPINEL_GC_VERIFY_GEN=1 SPINEL_GC_STRESS=1 -- a
# collection at every allocation, the old-to-young invariant checked after
# each -- they would run for hours. These are the same programs with the
# depths cut down, and with every tree checked after it is built, so a node
# freed while still linked changes the answer as well as tripping the
# verifier:
#
#   * top-down: a node is made, survives its children's allocations (old by
#     then under stress), and has its fields filled afterwards
#   * bottom-up: the children are made first and the parent is the young one
#   * a constructor that takes its children as arguments
#   * a list built by pushing in front, then reversed in place
#   * a long-lived tree held across the churn of short-lived ones

class Node
  attr_accessor :left, :right, :i, :j
  def initialize
    @left = nil
    @right = nil
    @i = 0
    @j = 0
    @tag = "n"
  end
  def tag = @tag
end

def populate(depth, node)
  if depth > 0
    node.left = Node.new
    node.right = Node.new
    populate(depth - 1, node.left)
    populate(depth - 1, node.right)
  end
end

def make_tree(depth)
  if depth <= 0
    Node.new
  else
    n = Node.new
    n.left = make_tree(depth - 1)
    n.right = make_tree(depth - 1)
    n
  end
end

def count(node)
  return 0 if node == nil
  node.tag.length + count(node.left) + count(node.right)
end

class Pair
  attr_accessor :left, :right
  def initialize(left, right)
    @left = left
    @right = right
  end
end

def make_pairs(depth)
  return Pair.new(nil, nil) if depth == 0
  d = depth - 1
  Pair.new(make_pairs(d), make_pairs(d))
end

def check_pairs(node)
  return 1 if node.left == nil
  1 + check_pairs(node.left) + check_pairs(node.right)
end

class LNode
  attr_accessor :val, :nxt
  def initialize(val)
    @val = val
    @nxt = nil
    @tag = "ln"
  end
end

def list_push(head, val)
  node = LNode.new(val)
  node.nxt = head
  node
end

def list_reverse(head)
  prev = nil
  cur = head
  while cur != nil
    nxt = cur.nxt
    cur.nxt = prev
    prev = cur
    cur = nxt
  end
  prev
end

def list_sum(head)
  s = 0
  cur = head
  while cur != nil
    s = s + cur.val
    cur = cur.nxt
  end
  s
end

puts count(make_tree(10))

long_lived = Node.new
populate(9, long_lived)
long_pairs = make_pairs(9)

depth = 2
while depth <= 8
  total = 0
  iters = 1 << (9 - depth)
  i = 0
  while i < iters
    node = Node.new
    populate(depth, node)
    total = total + count(node) + count(make_tree(depth)) + check_pairs(make_pairs(depth))
    i = i + 1
  end
  puts total
  depth = depth + 2
end

head = nil
i = 0
while i < 300
  head = list_push(head, i)
  i = i + 1
end
head = list_reverse(head)
puts list_sum(head)
puts head.val

puts count(long_lived)
puts check_pairs(long_pairs)
