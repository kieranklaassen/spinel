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

A begin with rescue clauses now marks its ensure region while its body is emitted (`EnsureCtx.rescued`), and an inner region that finds the mark raises the exception again into the body's frame. The clauses are offered it there, and the ensure runs after them, taken or not. A clause whose operand is not a constant (a local, a call) is matched by its class at run time, and is offered the exception like any other.

Two cases stay as master has them, the exception handed on past the clauses. In each a clause's test could take an exception CRuby's would decline, and the hand-on is right for those:

- a program that may give a class a `===` of its own, which a clause's test never calls. That is asked of master's own walk, `an_prog_never_gives("===", 0)`, which answers for the program as written. So a def or a Symbol of that name, any include (`Comparable` too), a method named by a value (`send` with a computed name, `define_method` in a loop), or a required package that holds one of these (`require "set"`) keeps master's C byte for byte, and this fault with it;
- with a bare clause in the list, an exception whose class the runtime cannot place by its ancestry (a name with no parent on record), which the bare clause's test takes by default, whatever CRuby's would say. Such a class is handed on as before, and where CRuby's clause would take it, as it takes `SocketError`, this fault stays. A class made with `Class.new` is placed, and is offered to the clauses like any other.

Cost (callgrind, gcc 13.3 -O2, master then this). Nothing changes on the path with no exception: the eighteen such programs measured take the instructions they took, to the instruction. An exception that leaves an inner ensure for a begin whose clauses do not take it now pays for their tests, as one raised in that body does: 20,000 such past one clause that names one class, 55,548,864 to 155,041,985, where 20,000 raised in the body itself take 145,791,373. With a bare clause in the list the ancestry is asked before the raise: 20,000 of a class made at run time from Exception, which a named clause and the bare one both decline, 103,817,802 to 195,770,923. The other exception paths measured (through one ensure and two, out of a synchronize block, raised in the body itself) are unchanged.

The first test raises through an inner ensure to the clauses of the begin around it: in a method, as a value, three deep, with a rescue of its own on the inner begin, many times over; then each kind of clause, taking the exception and missing it (a second clause, a parent class, a bare clause, a splat list, a class held in a local or answered by a call, an operand that is no class, `rescue Exception`, a class that is no StandardError before a bare clause, a class made at run time), a raise in the clause, and `retry`. The second holds classes with a `===` of their own and prints what master prints.

Measured on master c52df8a11. The tests are right at -O0 to -O3, with clang, under both stress modes and as the gate's shared leg builds them; master has 86 of the first test's 88 lines wrong at every level and the second right. The C of 4 corpus programs changes, the tests `conditional_require_line`, `require_expression_lines`, `source_file_required` and `toplevel_proc_return_ensure`, which print their `.expected`, and of 6,830 does not; no refusal changes. optcarrot's C is unchanged.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, one commit on master c52df8a11: the build from nothing, the two tests in the seven builds, as the gate's shared leg builds them and with clang at -O0 under `--int-overflow=wrap` and `promote`, `ruby tools/gate.rb check` with the commit staged, the C of every corpus program against master's, the tests whose C changed built and run, `make backtrace-test`, `make scale-test`, `make int-min-test`, `make share-strings-test`, optcarrot's C, and twenty-nine cost programs under callgrind on master and here.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: none
