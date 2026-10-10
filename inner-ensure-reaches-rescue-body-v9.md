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

The raise must leave the exception as the hand-on does, and a raise can give it a cause: a landing gives an exception that has none the one being handled, or the one in flight through an ensure body. So the inner region raises only an exception that has a cause already, or when nothing is handled and nothing is in flight, and hands any other on. It asks that at run time, inside the test it already made of the held exception.

Not here, each handed on past the clauses as master has it:

- an exception that reaches the inner region's end with no cause while another exception is being handled (for one, `raise C.new("m")` in a rescue body through a begin that has only an ensure, or any raise with `cause: nil`): the raise here would give it the handled exception as its cause, where Ruby gives none or master's landing has not set it;
- a program that may give a class a `===` of its own, which a clause's test never calls, so the test could take an exception CRuby's would decline. That is asked of master's own walk, `an_prog_never_gives("===", 0)`, which answers for the program as written. So a def or a Symbol of that name, any include (`Comparable` too), a method named by a value (`send` with a computed name, `define_method` in a loop), or a required package that holds one of these (`require "set"`) keeps master's C byte for byte, and this fault with it;
- with a bare clause in the list, an exception whose class the runtime cannot place by its ancestry (a name with no parent on record), which the bare clause's test takes by default, whatever CRuby's would say. Where CRuby's clause would take it, as it takes `SocketError`, this fault stays. A class made with `Class.new` is placed, and is offered to the clauses like any other;
- an exception that leaves a `Mutex#synchronize` block or `select!`'s loop for such a begin: the pull request "An exception leaving a synchronize block reaches the rescue beside the outer ensure".

Cost (callgrind, -O2, master then this, with gcc 13.3 and with clang 18.1). The new test is on the exception's path only. With no exception gcc counts the same to the instruction: the eighteen such programs of the round, and the function that holds the begins in eight more (with a bare clause the program's start takes 26 instructions more, once). clang counts those eight as gcc does but for one, two begins nested in a third, which takes three instructions a pass more (335,175,254 to 338,175,254 for a million passes): it assigns that function's registers anew for any text at that place. An exception that leaves an inner ensure for a begin whose clauses do not take it now pays for their tests, as one raised in that body does: 20,000 such past one clause that names one class, 55,548,896 to 155,222,017 with gcc and 56,056,805 to 156,495,561 with clang, where 20,000 raised in the body itself take 145,791,391 (gcc). The rise grows with each further class the clauses name, by about 4,100 instructions an exception (4,200 with clang): with five names, 483,745,387. With a bare clause in the list the ancestry is asked before the raise: 20,000 of a class made at run time from Exception, which a named clause and the bare one both decline, 103,669,044 to 195,842,165 (gcc). The other exception paths measured (through one ensure and two, out of a synchronize block, raised in the body itself) are unchanged.

The first test raises through an inner ensure to the clauses of the begin around it: in a method, as a value, three deep, with a rescue of its own on the inner begin, many times over; then each kind of clause, taking the exception and missing it (a second clause, a parent class, a bare clause, a splat list, a class held in a local or answered by a call, an operand that is no class, `rescue Exception`, a class that is no StandardError before a bare clause, a class made at run time), a raise in the clause, and `retry`. The second holds classes with a `===` of their own and prints what master prints. The third holds the cause: an exception raised with `cause: nil` while another is handled, past a clause that names another class and under a bare one, and one raised again while its own effect is handled; master prints it right, and a raise without the test of the cause does not.

Measured on master c52df8a11. The tests are right at -O0 to -O3, with clang, under both stress modes and as the gate's shared leg builds them; master has 86 of the first test's 88 lines wrong at every level and the other two right. The C of one corpus program changes, the test `toplevel_proc_return_ensure`, which prints its `.expected`, and of 6,833 does not; no refusal changes. optcarrot's C is unchanged.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this head, one commit on master c52df8a11: the build from nothing, the three tests in the seven builds, as the gate's shared leg builds them and with clang at -O0 under `--int-overflow=wrap` and `promote`, `ruby tools/gate.rb check` with the commit staged, the C of every corpus program against master's, the tests whose C changed built and run, `make backtrace-test`, `make scale-test`, `make int-min-test`, `make share-strings-test`, optcarrot's C, and the cost programs under callgrind on master and here. And merged with master 55aa88e97: the build from nothing and the three tests, in the default build and with `--share-strings`, plain and under both stress modes, and with clang at -O0 under both overflow modes; and `ruby tools/gate.rb check-range HEAD^1 HEAD` over the commit there, which exits 0 (it found no Ruby 4.0 to check the `.expected` files with).

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (they match CRuby 3.3.6 run so; 4.0 is not on this machine)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: none
