<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`case x in Klass` answered `x.is_a?(Klass)` for a class that defines `===` itself.

Refused now: a class whose `===` has a body the compiler does not build (`def self.===(o) = o.hash == hash`). Under `in Klass` that body was never compiled. It now is, as it is under `when Klass`, where master refuses the same program. 4 of the 90 programs tried, each with a wrong line on master.

```ruby
class Even
  def self.===(o) = o.is_a?(Integer) && o.even?
end
[4, 3, "x", Even.new].each do |v|
  case v
  in Even then puts "even"
  else puts "other"
  end
end
```

Master (42557a3c) prints `other`, `other`, `other`, `even`. CRuby prints `even`, `other`, `other`, `other`.

`emit_pm_cond`'s class arm now calls the method `when Klass` calls (`emit_when_class_own_eqq`): for the pattern itself, a captured value, an alternative, an element of an Array or Hash pattern, and the class such a pattern names. Its parameter is boxed, as there.

No call written out reaches the method in a program whose only use of it is a pattern. `compute_reachable` marks it for the `in` arms, as it marks `===` for a `when` (`a_pattern_own_eqq`). `class_recv_own_eqq_def` is `class_recv_own_eqq` before inference: it does not ask the parameter's type.

A builtin class's name keeps the class test (Integer, Float, String, Symbol, NilClass, Array, Hash and the others the compiler holds as its own values): a capture `Integer => t` is read as binding a value of that class. So does a subject held with its nil sentinel.

Not here:

- The class's `===` is now run, so a fault inside its body is reached where the class test answered. One is known, Class#dup: `o.dup` of a boxed value that holds a class hands back the class itself, so `def self.===(o) = o.dup.equal?(self)` with its own class as the subject takes the arm. The class test did not, as CRuby does not: 2 lines of the programs tried. The same body under a plain name (`def self.ask(o)`) answers `true` on master.

No program of the corpus changes its C (`tools/cident.sh`: 1 differ, the new test).

Test: `test/case_in_class_own_eq.rb`, 47 lines; 37 differ on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "`when Klass` asks a class that defines === itself": this one calls its `emit_when_class_own_eqq`)
