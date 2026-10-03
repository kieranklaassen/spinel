Reproduced, and fixed in 5e7e8d41.

```ruby
class B
  def initialize = @on = true
  def call_it(name, &b) = b.call
  alias define_method call_it
  def run
    v = define_method(:a) { next 1 if @on; 2 }
    [v, :after]
  end
end
p B.new.run
```

Master builds this and prints `[1, :after]`. At 75c390c2 the C did not compile: the `return` the rewrite left was read as `run`'s. The same call in a class body, reaching an alias in the singleton class, built and printed nothing.

The call is not resolved, because which method it reaches is not known where the rewrite runs: the class table is still being filled there. The whole-program check is wider instead. Besides a def of either name it now stops at a Symbol or String literal spelling `define_method` or `define_singleton_method` anywhere in the program, which is how `alias` and `alias_method` name the method they make. `test/define_method_alias_block_next.rb` and `test/define_method_alias_string_block_next.rb` pin it. Of the 46 programs I built around this, 15 answered as CRuby on master and broke at 75c390c2; with 5e7e8d41 all 46 do what they do on master. af34c8c3 adds one more case, found while checking this: a `define_method` call whose interpolated name can spell either name, as an `each` over literals can put one together (`test/define_method_unrolled_name_block_next.rb`).
