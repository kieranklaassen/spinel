# spinel: not-cruby -- the C fragment is one side of a proc call caught half made; CRuby has no ffi_source
# A Signal.trap block runs inside the signal handler, and it is called
# through the side channel every proc call uses: the arguments, the block,
# the keyword flag, the answer. A signal that arrives after one side of a
# call has written the channel and before the other has read it must find
# the channel as it was when the block returns. Each C function below is one
# side of a call at that point: it writes its part, sends the signal, and
# answers what it reads back. The block calls procs of its own with
# arguments, a block and keywords, and collects, so a value set aside that
# nothing else points at has to be marked.
module Half
  ffi_source <<~C
    #include <signal.h>
    /* through a pointer: the C library declares raise() as a leaf, and the
       compiler would keep the channel in registers across a direct call */
    static int (*volatile half_send)(int) = raise;
    long half_args(long v) {
      _sp_proc_poly_args[0] = sp_box_int((sp_int)v);
      _sp_proc_poly_args[1] = sp_box_int((sp_int)(v + 1));
      half_send(SIGUSR1);
      return (long)(_sp_proc_poly_args[0].v.i * 100 + _sp_proc_poly_args[1].v.i);
    }
    long half_answer(long v) {
      _sp_proc_poly_ret = sp_box_int((sp_int)v);
      half_send(SIGUSR1);
      return (long)_sp_proc_poly_ret.v.i;
    }
    long half_keywords(long v) {
      _sp_proc_kwpos = (int)v;
      half_send(SIGUSR1);
      return (long)_sp_proc_kwpos;
    }
    long half_block(void) {
      sp_Proc *mine = (sp_Proc *)sp_trap_proc[SIGUSR1];
      _sp_proc_blk = mine;
      half_send(SIGUSR1);
      long same = _sp_proc_blk == mine;
      _sp_proc_blk = NULL;
      return same;
    }
    const char *half_answer_string(void) {
      _sp_proc_poly_ret = sp_box_str(sp_str_concat("ke", "pt"));
      half_send(SIGUSR1);
      const char *s = _sp_proc_poly_ret.tag == SP_TAG_STR ? _sp_proc_poly_ret.v.s : "lost";
      _sp_proc_poly_ret = sp_box_int(0);
      return s;
    }
    const char *half_arg_string(void) {
      _sp_proc_poly_args[0] = sp_box_str(sp_str_concat("he", "ld"));
      half_send(SIGUSR1);
      const char *s = _sp_proc_poly_args[0].tag == SP_TAG_STR ? _sp_proc_poly_args[0].v.s : "lost";
      _sp_proc_poly_args[0] = sp_box_int(0);
      return s;
    }
  C
  ffi_func :half_args, [:long], :long
  ffi_func :half_answer, [:long], :long
  ffi_func :half_keywords, [:long], :long
  ffi_func :half_block, [], :long
  ffi_func :half_answer_string, [], :str
  ffi_func :half_arg_string, [], :str
end

$seen = 0
inner = proc { |a, b = 5, k: 2, &blk| a + b + k + (blk ? blk.call(1) : 0) }
three = proc { |a, b, c| ("j" * 40) + (a + b + c).to_s }
Signal.trap("USR1") do |no|
  $seen += inner.call(no, 3)
  $seen += inner.call(no, k: 4) { |x| x + 1 }
  $junk = three.call(no, 1, 2)
  GC.start
end

p Half.half_args(41)
p Half.half_answer(43)
p Half.half_keywords(7)
p Half.half_block
p Half.half_answer_string
p Half.half_arg_string
p $seen > 0
