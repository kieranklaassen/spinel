# A global assigned only an empty `{}` or `Hash.new` and filled through
# another name -- a method's parameter, a block's -- has no `$g[k] = v` to
# say what it holds. It had no type until the end of inference, where it
# took the boxed slot after every call on it had been typed as answering
# nothing: `$g[k]`, `$g.keys`, `$g.values` and `$g.to_a` computed their
# answer and read nil. `$g ||= {}` did so even with a `$g[k] = v` beside it.

# filled through a method's parameter
$cache = {}
def remember(c, k, v); c[k] = v; end
remember($cache, :a, 1)
remember($cache, "b", 2.5)
p $cache[:a]
p $cache["b"]
p $cache[:zz]
p $cache.keys
p $cache.values
p $cache.to_a
p $cache.fetch(:a)
p $cache.fetch(:zz, 0)
p $cache.dig("b")
p $cache.key?(:a)
p $cache.size
p($cache.map { |k, v| [v, k] })
p($cache.map { |k, v| "#{k}=#{v}" })
p($cache.select { |k, v| k == :a }.to_a)
p $cache.values.sum
$cache.each { |k, v| p [k, v] }
def cached(k) = $cache[k]
p cached(:a)
x = $cache["b"]
p x
p $cache[:a] + 1

# never filled
$empty = {}
p $empty.keys
p $empty.values
p $empty.to_a
p $empty[:a]
def count(h) = h.size
p count($empty)

# through a class method, two methods deep, and a block
class Registry
  def self.put(h, k, v) = h[k] = v
end
$reg = {}
Registry.put($reg, "name", :sym)
p $reg["name"]
p $reg.fetch("name")
$deep = {}
def inner(h, k, v); h.store(k, v); end
def outer(h, k, v); inner(h, k, v); end
outer($deep, 3, :three)
outer($deep, 4, :four)
p $deep[3]
p $deep.to_a
$blk = {}
def with(h); yield h; end
with($blk) { |h| h[:x] = 1; h[:y] = 2 }
p $blk[:x]
p $blk.keys
3.times { |i| remember($blk, i, i * 2) }
p $blk[2]
p $blk.size

# filled by merge!
$merged = Hash.new
$merged.merge!({"k" => 1, :s => 2.5})
$merged.update(t: true)
p $merged["k"]
p $merged.values

# `||=`, with and without a write that names the global
$memo ||= {}
$memo[:n] = 1
remember($memo, :m, 2)
p $memo[:n]
p $memo.keys
def table = $table ||= {}
remember(table, "r", 1.5)
p table["r"]
p $table.to_a
def fib(n) = n < 2 ? n : ($fib[n] ||= fib(n - 1) + fib(n - 2))
$fib = Hash.new
p fib(30)
p $fib.size
p $fib[30]

# emptied and made again
$again = {}
remember($again, :a, 1)
p $again[:a]
$again = nil
p $again.nil?
$again = {}
p $again.keys

# the shapes that already worked keep their answers
$lit = {}
$lit["b"] = 1
p [$lit["b"], $lit["zz"]]
$two = {}
$two = {"a" => 1}
p $two["a"]
p $two.keys
$strs = {}
$strs[:s] = +"q"
p $strs[:s]
