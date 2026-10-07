<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
S = Struct.new(:x, keyword_init: true)

begin
  raise ArgumentError, "x"
rescue => e
  p e.class                    # CRuby: ArgumentError. master: S(keyword_init: true)
  p e.class.new("z").message   # CRuby: "z". master: wrong number of arguments (given 1, expected 0)
end
```

With any class first in the program the second line fails the same way, and so does a class method of the program's own exception class (`class MyErr < StandardError; def self.build = new("b"); end`, then `e.class.build` raises NoMethodError) unless `MyErr` is the program's first class.

An exception carries its class as a name. The class value `e.class` built from the name wrote 0 as its id, and 0 is the id of the program's first class: inspect, `new` and a class method go by the id before the name. So the value was the first class under the exception's name.

The value carries -1 now, the id of a class known only by name. Where the program defines a class under a builtin exception, `sp_exc_class_of` answers a class of the program by its own id and any other by name; both `class` arms use it, and its text is spliced in only where the unit calls it, as the class arms of `sp_poly_is_a` are.

Not in this change: a Range's and a Random's class are written with id 0 the same way (`r = ("a".."c"); p r.class` prints S(keyword_init: true) beside that Struct). By name alone their ancestors are not CRuby's, so -1 there turns right answers wrong (`r.class.ancestors.include?(Enumerable)`); they are left as they are.

Some readings of an exception's ancestors answer CRuby's line on master and not here: the count (`ancestors.size`) and every position past the second (`ancestors[2]`, `ancestors.index(StandardError)`, `ancestors.take(3).last`). That is so where the program's first class has one module among its ancestors (it includes Comparable or Enumerable, or is a subclass of a class that does) and the error is one CRuby gives a gem's module: ArgumentError and TypeError (`ErrorHighlight::CoreExt`), KeyError (`DidYouMean::Correctable`), and NameError for a test such as `ancestors.size > 6`.

```ruby
class A
  include Comparable
  def <=>(o) = 0
end

begin
  raise ArgumentError, "m"
rescue => e
  p e.class.ancestors.size     # CRuby: 7. master: 7. here: 6
end
```

CRuby's list is `[ErrorHighlight::CoreExt, ArgumentError, StandardError, Exception, Object, Kernel, BasicObject]`; with `--disable-error_highlight` it is the last six. master's is `[ArgumentError, Comparable, StandardError, Exception, Object, Kernel, BasicObject]`: the first class's module, by the id 0, stands second where CRuby's gem module stands first, so the count and every place past the second agree by an accident of position. Here the list is `[ArgumentError, StandardError, Exception, Object, Kernel, BasicObject]`, as on master where the first class includes no module.

The tests are `test/exception_class_beside_kwinit_struct.rb` (14 lines printed, 13 differ on master) and `test/exception_class_own_id.rb` (27 lines, 19 differ on master). `tools/cident.sh` against master 12fc5dd9 answers `5546 identical, 817 differ`: 755 differ in the one token `{0, ` written `{-1,`, 60 define a class under a builtin exception and read an exception's class (each prints what it prints on master), and two are the tests. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the tests)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
