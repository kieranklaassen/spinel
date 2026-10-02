# A mark that takes the collector's plain path keeps every object it reaches
class Link
  attr_accessor :val, :nxt
  def initialize(val, nxt)
    @val = val
    @nxt = nxt
  end
end

class Leaf
  attr_reader :n, :name
  def initialize(n)
    @n = n
    @name = "leaf" + n.to_s
  end
end

class Fork
  attr_reader :left, :right, :leaf
  def initialize(left, right, leaf)
    @left = left
    @right = right
    @leaf = leaf
  end
end

# 260 references and a header are past the slab's largest block, so a Big is
# malloc's and its mark is not the plain one
class Big
  def initialize(leaf)
    @f000 = @f001 = @f002 = @f003 = @f004 = @f005 = @f006 = @f007 = @f008 = @f009 = leaf
    @f010 = @f011 = @f012 = @f013 = @f014 = @f015 = @f016 = @f017 = @f018 = @f019 = leaf
    @f020 = @f021 = @f022 = @f023 = @f024 = @f025 = @f026 = @f027 = @f028 = @f029 = leaf
    @f030 = @f031 = @f032 = @f033 = @f034 = @f035 = @f036 = @f037 = @f038 = @f039 = leaf
    @f040 = @f041 = @f042 = @f043 = @f044 = @f045 = @f046 = @f047 = @f048 = @f049 = leaf
    @f050 = @f051 = @f052 = @f053 = @f054 = @f055 = @f056 = @f057 = @f058 = @f059 = leaf
    @f060 = @f061 = @f062 = @f063 = @f064 = @f065 = @f066 = @f067 = @f068 = @f069 = leaf
    @f070 = @f071 = @f072 = @f073 = @f074 = @f075 = @f076 = @f077 = @f078 = @f079 = leaf
    @f080 = @f081 = @f082 = @f083 = @f084 = @f085 = @f086 = @f087 = @f088 = @f089 = leaf
    @f090 = @f091 = @f092 = @f093 = @f094 = @f095 = @f096 = @f097 = @f098 = @f099 = leaf
    @f100 = @f101 = @f102 = @f103 = @f104 = @f105 = @f106 = @f107 = @f108 = @f109 = leaf
    @f110 = @f111 = @f112 = @f113 = @f114 = @f115 = @f116 = @f117 = @f118 = @f119 = leaf
    @f120 = @f121 = @f122 = @f123 = @f124 = @f125 = @f126 = @f127 = @f128 = @f129 = leaf
    @f130 = @f131 = @f132 = @f133 = @f134 = @f135 = @f136 = @f137 = @f138 = @f139 = leaf
    @f140 = @f141 = @f142 = @f143 = @f144 = @f145 = @f146 = @f147 = @f148 = @f149 = leaf
    @f150 = @f151 = @f152 = @f153 = @f154 = @f155 = @f156 = @f157 = @f158 = @f159 = leaf
    @f160 = @f161 = @f162 = @f163 = @f164 = @f165 = @f166 = @f167 = @f168 = @f169 = leaf
    @f170 = @f171 = @f172 = @f173 = @f174 = @f175 = @f176 = @f177 = @f178 = @f179 = leaf
    @f180 = @f181 = @f182 = @f183 = @f184 = @f185 = @f186 = @f187 = @f188 = @f189 = leaf
    @f190 = @f191 = @f192 = @f193 = @f194 = @f195 = @f196 = @f197 = @f198 = @f199 = leaf
    @f200 = @f201 = @f202 = @f203 = @f204 = @f205 = @f206 = @f207 = @f208 = @f209 = leaf
    @f210 = @f211 = @f212 = @f213 = @f214 = @f215 = @f216 = @f217 = @f218 = @f219 = leaf
    @f220 = @f221 = @f222 = @f223 = @f224 = @f225 = @f226 = @f227 = @f228 = @f229 = leaf
    @f230 = @f231 = @f232 = @f233 = @f234 = @f235 = @f236 = @f237 = @f238 = @f239 = leaf
    @f240 = @f241 = @f242 = @f243 = @f244 = @f245 = @f246 = @f247 = @f248 = @f249 = leaf
    @f250 = @f251 = @f252 = @f253 = @f254 = @f255 = @f256 = @f257 = @f258 = @f259 = leaf
  end

  def first
    @f000
  end

  def last
    @f259
  end
end

def chain(n)
  head = nil
  i = 0
  while i < n
    head = Link.new(i, head)
    i += 1
  end
  head
end

def chain_sum(head)
  s = 0
  cur = head
  while cur != nil
    s += cur.val
    cur = cur.nxt
  end
  s
end

def reverse(head)
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

def tree(depth, n)
  return Fork.new(nil, nil, Leaf.new(n)) if depth == 0
  Fork.new(tree(depth - 1, n * 2), tree(depth - 1, n * 2 + 1), Leaf.new(n))
end

def tree_count(t)
  return 0 if t == nil
  1 + tree_count(t.left) + tree_count(t.right)
end

# the nodes whose name is still the one they were built with
def tree_named(t)
  return 0 if t == nil
  n = t.leaf.name == "leaf" + t.leaf.n.to_s ? 1 : 0
  n + tree_named(t.left) + tree_named(t.right)
end

# one object a pop: a chain marked young, then old, then written into
head = chain(60_000)
p chain_sum(head)
GC.start
p chain_sum(head)
head = reverse(head)
chain(30_000)
GC.start
p head.val
p chain_sum(head)

# more objects waiting than the mark stack starts with room for: the array's
# scan reaches every Leaf before the drain scans one of them
wide = []
90_000.times { |i| wide << Leaf.new(i) }
GC.start
p wide.size
p wide[0].name
p wide[89_999].name
# a name the mark missed was freed: strings of its size, kept, take its place
fill = []
60_000.times { |i| fill << "fill" + i.to_s }
p wide.count { |l| l.name == "leaf" + l.n.to_s }
p fill.size

# blocks off the slab among the slab's, reached in the same drain
bigs = []
50.times { |i| bigs << Big.new(Leaf.new(i)) }
GC.start
fill = []
20_000.times { |i| fill << "fill" + i.to_s }
p bigs.count { |b| b.first.name == "leaf" + b.first.n.to_s && b.last.n == b.first.n }

# two references an object, and a heap string behind every one
t = tree(12, 1)
3.times { chain(20_000) }
GC.start
p tree_count(t)
p tree_named(t)

# dropped, collected and built again in the same slots
wide = nil
fill = nil
head = nil
GC.start
head = chain(60_000)
t2 = tree(12, 1)
GC.start
p chain_sum(head)
p tree_count(t2)
p tree_named(t)
p tree_named(t2)
