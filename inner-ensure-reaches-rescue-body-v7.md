<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
def go
  begin
    begin
      raise TypeError, "deep"
    rescue ArgumentError
      puts "not reached"
    ensure
      puts "ensure 1"
    end
  rescue TypeError
    puts "rescued"
  ensure
    puts "ensure 2"
  end
end
go
puts "done"
```

prints `ensure 1`, `ensure 2` and dies of the TypeError, uncaught, at every level. CRuby prints `ensure 1`, `rescued`, `ensure 2`, `done`.

After: CRuby's lines.

An ensure region whose body is done passes the exception it holds to the ensure region around it, unless a begin with a rescue lies between the two: then it raises the exception again, for that rescue. The begin whose body the inner region is a statement of was not counted. The frame of its body serves its rescue clauses and its ensure both, so no frame lies between, and its clauses were never offered the exception. The same happens with no rescue on the inner begin.

A begin with rescue clauses now marks its ensure region while its body is emitted (`EnsureCtx.rescued`), and an inner region that finds the mark raises the exception again into the body's frame. The clauses are offered it there, and the ensure runs after them, taken or not.

Three cases stay as master has them, the exception handed on past the clauses. In each a clause's test could take an exception CRuby's would decline, and the hand-on is right for those:

- a program that may give a class a `===` of its own, which a clause's test never calls. That is asked of master's own walk, `an_prog_never_gives("===", 0)`, so a def or a Symbol of that name, or a mix-in, anywhere in the program keeps master's C;
- a begin with a clause whose operand is neither a constant nor a splat, since such a clause takes everything;
- with a bare clause in the list, an exception of a class the runtime does not know for a StandardError (one made at run time), which the bare clause's test takes.

Cost (callgrind, gcc -O2, on the pull request this depends on, then this). Nothing changes on the path with no exception: of the eighteen such programs measured none is dearer, and one, whose inner ensure now ends in the raise, is two instructions a call cheaper. An exception that leaves an inner ensure for a begin whose clauses do not take it now pays for their tests, as one raised in that body does: 20,000 such, 54,211,746 to 153,626,925, where 20,000 raised in the body itself take 144,974,335. Every other exception path measured is unchanged.

The first test raises through an inner ensure to the clauses of the begin around it: in a method, as a value, three deep, with a rescue of its own on the inner begin, many times over; then each kind of clause, taking the exception and missing it (a second clause, a parent class, a bare clause, a splat list, `rescue Exception`, a class that is no StandardError before a bare clause, a class made at run time), a raise in the clause, and `retry`. The second holds classes with a `===` of their own and prints what master prints.

Measured on master 5749e9566 with the pull request this depends on. The tests are right at -O0 to -O3, with clang, under both stress modes and as the gate's shared leg builds them; master has 68 of the first test's 70 lines wrong at every level and the second right. The C of one corpus program changes, the test `toplevel_proc_return_ensure`, which prints its `.expected`, and of 6,777 does not; no refusal changes. optcarrot's C is unchanged.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, on master 5749e9566 with the pull request this depends on: the build from nothing, the two tests in the seven builds and as the gate's shared leg builds them, `ruby tools/gate.rb check` with the commit staged, the C of every corpus program against the C beneath, the tests whose C changed built and run, `make backtrace-test`, `make scale-test`, `make int-min-test`, optcarrot's C, and twenty-seven cost programs under callgrind.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: the pull request "An ensure keeps the exception it holds while its body runs", which makes the exception raised again here an object
