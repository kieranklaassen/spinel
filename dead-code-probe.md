<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Spinel types a slot from every write it can see, reached or not, so a statement that never runs changes what the compiler decides and nothing the program does: `x = :dead if ::ARGV.length == 9123` ahead of `x = 1` boxes `x`, and the program has to print what it printed. Nothing in the tree asks whether it does. `tools/dead_code_probe.rb` takes each test given, puts such statements into it through `tools/dead_code_edit.rb` (eleven kinds: a local, an instance variable, a global, an element, a parameter, a return, a block's value, a capture, an escape, a raise, and a bare `nil` as the control), builds it, runs it as the suite runs the test and compares stdout and stderr with the test's own `.expected`. No other oracle is needed, and every test of the corpus becomes a test of the boxed path it does not name. A pass that does not print the answer is cut down to the edits that carry the difference, and each finding is left as a program of its own that `spinel diff` and `spinel-reduce` take as it is.

On d83c5bd5, `--sample 300 --seed 7` finds a place for an edit in 275 of the 300 tests (9,811 sites) and lists 229 wrong results in 69 of them, with 29 refusals listed and not counted: 139 other answers, 2 crashes, 1 run that does not end and 87 programs whose C does not build. 210 of the 229 are still there with the 46 open pull requests that merge with master merged in. Three of them, cut down:

```ruby
f = :dead if ::ARGV.length == 9123
f = proc { |t| [t] }
p f.call("x")                  # [94151192543289]

e = :dead if ::ARGV.length == 9123
e = [10, 20, 30].each
p e.peek                       # NoMethodError

class B
  def self.c(a, z)
    c(:dead, z) if ::ARGV.length == 9123; [a, z]
  end
end
class C < B
  def self.c(p, q) = super
end
p C.c(1, 5)                    # [:dead, 5]
```

The families, largest first. `next` at the top of a block given to `Fiber.new`, `Enumerator.new`, `Thread.new` or `instance_eval` is written as a C `continue` outside any loop, which is 64 of the 87 and not about types (`Fiber.new { next 7 if c; 5 }` does not build). A NoMethodError CRuby does not raise, 22 results in 18 families (on a boxed receiver `Enumerator#peek` and `#rewind`, `StringIO#<<`, `Method#call`, `MatchData#string`, `Time#deconstruct_keys`). A String shared on the typed path and copied on the boxed one, the route CONTRIBUTING.md asks to be refused. A user's `to_s`, `inspect` or `name` ignored once its return is boxed. A block's value dropped (`each_with_index.filter_map` answers `[]` once its block has a second `next`). And five from the control, three of them a method the compiler knows by the shape of its body: after `def s = (nil if c; (@s ||= +""))`, `o.s << "q"` and then `p o.s` prints `""`. This pull request sends the probe and no fix: most of these sit in work others are doing, and each finding names its test, its edit and its line.

The edits were checked under CRuby over the whole corpus: 172,327 sites in 5,081 tests, and with every one filled in at once ruby 3.3.6 prints the same from all but four (three print their own path or run finalizers in an order of their own, and one it does not parse). The tiers are those of the generated-case probes, and three checks stand before a finding: the unedited test has to print its `.expected` from a copy, the edited program has to print under CRuby what the unedited one prints under it, and an answer that differs is asked for twice.

A probe to run by hand, like `order_probe`: a CRuby script that needs only Prism, not a gate, and not one of the tools make builds. It adds two files under `tools/`, a section in `tools/README.md`, one sentence in `docs/emit-types.md` and an `input:` keyword on `ProbeCommon.run_timed` (for a test's `.stdin`; the other probes call it as before). Nothing under `src/`, `lib/` or `test/` changes.

## `make gate` (on this branch merged with current master)

```
scale-test: instance_eval forwarding work at 2x the wrappers is 1.73x (limit 2.50)
scale-test: work at 4x the program is 4.82x (linear 4.00, limit 5.20)
scale-test: work at 4x the program, compiled to C, is 6.32x (limit 6.90)
scale-test: call-shape work at 4x the units, compiled to C, is 4.26x (linear 4.00, limit 4.50)
Tests: 5580 pass, 2 fail, 0 error
```

Run on this branch at 7629f51f, which is 7337219d plus this commit. The two failures come from the container the gate ran in, and neither test is touched here: `packages/tmpdir/test/tmpdir_expand_usable.rb` makes a directory of mode 0500 and expects it not to be writable, and the gate ran as root; `test/socket_ipv6_and_class_methods.rb` needs IPv6, which the container does not have (CRuby raises `EAFNOSUPPORT` on `UDPSocket.new(Socket::AF_INET6)` there too). The gate stops there, so it prints no `gate:` line. Run with `make -k`, the other legs pass: benchmarks 64 of 64, optcarrot with checksum 59662, ruby/spec (language 791, core/array 522, core/string 657, core/hash 195, core/integer 170, core/range 111), spin-e2e and the property tests.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no test is added)
- [ ] Values past 2^31 are marked `# spinel: int64` (no test is added)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change; nothing under `src/` or `lib/` is touched)
- [ ] Depends on: # (nothing)
