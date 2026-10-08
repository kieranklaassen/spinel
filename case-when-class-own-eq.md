<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`case x when Klass` answered `x.is_a?(Klass)` for a class that defines `===` itself.

```ruby
class Even
  def self.===(o) = o.is_a?(Integer) && o.even?
end
[4, 3, "x", Even.new].each do |v|
  case v
  when Even then puts "even"
  else puts "other"
  end
end
```

Master (42557a3c) prints `other`, `other`, `other`, `even`. CRuby prints `even`, `other`, `other`, `other`.

Both case emitters now call the method `Klass === x` written out calls, the one `class_recv_own_eqq` finds (`emit_when_class_own_eqq`). Its parameter is boxed, and the subject is handed over boxed. The class the arm names is the method's `self`. The subject is rooted for the call as it is for an arm that allocates.

The class test stays, master's C, where a written call has given the parameter one type, as it does for `Klass === x`; where the method's answer is neither a boolean nor boxed; and where the `===` only calls `super`, which is Module#===.

Not here:

- `in Klass` still folds: the next pull request.
- The class's `===` is now run, so a fault inside its body is reached where the class test answered. One is known, Class#dup: `o.dup` of a boxed value that holds a class hands back the class itself, so `def self.===(o) = o.dup.equal?(self)` with its own class as the subject takes the arm. The class test did not, as CRuby does not: 4 lines of the programs tried. The same body under a plain name (`def self.ask(o)`) answers `true` on master.

No program of the corpus changes its C (`tools/cident.sh`: 1 differ, the new test).

Test: `test/case_when_class_own_eq.rb`, 23 lines; 10 differ on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A class that defines === itself is asked it by `Klass === x`": this one calls its `class_recv_own_eqq`)
