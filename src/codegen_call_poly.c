/* codegen_call_poly.c -- emit_call_body's arms on a poly (boxed) receiver that the runtime answers by the value it holds.
   Moved from emit_call_body (codegen_call.c) unchanged: each function holds
   a run of its arms, in their order, and answers 1 when one emitted the call
   (codegen_call_arms.h). */

#include "codegen_internal.h"
#include "codegen_poly.h"
#include "builtin_ops.h"
#include "call_plan.h"
#include "codegen_call_arms.h"
#include "repr.h"

/* A splat asks its operand to_a, and a Range's to_a walks its each. The
   splat arms of values_at below answer for the built-in ones, so they are
   taken only in a program that cannot have given a class its own: one with
   no def, Symbol or String of the name (to_a; each too for a Range; and
   method_missing, respond_to_missing? and respond_to?, which a splat asks
   where there is no to_a, and which an alias can give), and no
   define_method, define_singleton_method or alias_method whose name is not
   written out, or that is itself named by a Symbol or a String; and no
   class_eval, module_eval or instance_eval given a text, nor one of them or
   eval named by a Symbol or a String. That is read of the nodes as they
   are now; the walk of the program as written, ahead of every desugar,
   is asked for each name as well (an_prog_never_gives): it also knows a
   name sent by value, a block passed by value, a text evaluated and a
   binding, which give a method that no node shows. Nor are they taken
   where any of these can stand in what the compiler does not see: a file
   it did not read (g_require_unread), or an arm the analysis dropped
   under a test it decided for this engine (g_engine_decided), which CRuby
   runs. Nor in a program that reopens a builtin exception class
   (any_exc_reopen): a scalar pushed as an index can be values_at's
   RangeError or TypeError, and a `raise` the program writes runs the
   `initialize` such a class gives where a raise by the runtime does not.
   Answered once for each arm. */
static int splat_asks_builtin_scan(Compiler *c, int range);
static int splat_asks_builtin(Compiler *c, int range) {
  static const Compiler *memo_c; static int memo[2];
  if (memo_c != c) { memo_c = c; memo[0] = memo[1] = -1; }
  if (memo[range] < 0) memo[range] = splat_asks_builtin_scan(c, range);
  return memo[range];
}
/* class_eval, module_eval and instance_eval take a text and run it as a
   body: what they define is in no node. */
static int splat_names_eval_of_text(const char *nm) {
  return sp_streq(nm, "class_eval") || sp_streq(nm, "module_eval") || sp_streq(nm, "instance_eval");
}
static int splat_asks_builtin_scan(Compiler *c, int range) {
  static const NodeKind kinds[] = { NK_DefNode, NK_SymbolNode, NK_StringNode };
  static const char *const fields[] = { "name", "value", "content" };
  const NodeTable *nt = c->nt;
  if (g_require_unread || g_engine_decided || any_exc_reopen(c)) return 0;
  if (!an_prog_never_gives("to_a", 0) || (range && !an_prog_never_gives("each", 0)) ||
      !an_prog_never_gives("method_missing", 0) || !an_prog_never_gives("respond_to_missing?", 0) ||
      !an_prog_never_gives("respond_to?", 0)) return 0;
  for (int j = 0; j < 3; j++)
    for (int n = comp_kind_first(c, kinds[j]); n >= 0; n = comp_kind_next(c, n)) {
      const char *nm = nt_str(nt, n, fields[j]);
      if (!nm) continue;
      if (sp_streq(nm, "to_a") || (range && sp_streq(nm, "each")) || sp_streq(nm, "method_missing") ||
          sp_streq(nm, "respond_to_missing?") || sp_streq(nm, "respond_to?")) return 0;
      if (j != 0 && (sp_streq(nm, "define_method") || sp_streq(nm, "define_singleton_method") ||
                     sp_streq(nm, "alias_method") || sp_streq(nm, "eval") || splat_names_eval_of_text(nm))) return 0;
    }
  for (int k = comp_kind_first(c, NK_CallNode); k >= 0; k = comp_kind_next(c, k)) {
    const char *kn = nt_str(nt, k, "name");
    if (kn && splat_names_eval_of_text(kn) && nt_ref(nt, k, "arguments") >= 0) return 0;
    if (!kn || (!sp_streq(kn, "define_method") && !sp_streq(kn, "define_singleton_method") &&
                !sp_streq(kn, "alias_method"))) continue;
    int a = nt_ref(nt, k, "arguments"), ac = 0;
    const int *av = a >= 0 ? nt_arr(nt, a, "arguments", &ac) : NULL;
    for (int i = 0; i < ac || i == 0; i++) {
      NodeKind ak = i < ac ? nt_kind(nt, av[i]) : NK_NilNode;
      if (ak != NK_SymbolNode && ak != NK_StringNode) return 0;
      if (!sp_streq(kn, "alias_method")) break;
    }
  }
  return 1;
}
/* Is a node held in a temp (g_argov) at `id` or under it? */
static int holds_a_temp_under(const NodeTable *nt, int id) {
  if (id < 0) return 0;
  for (int i = 0; i < g_n_argov; i++) if (g_argov_node[i] == id) return 1;
  for (int i = 0; i < nt_num_refs(nt, id); i++)
    if (holds_a_temp_under(nt, nt_ref_at(nt, id, i))) return 1;
  for (int i = 0; i < nt_num_arrs(nt, id); i++) {
    int n = 0;
    const int *ids = nt_arr_at(nt, id, i, &n);
    for (int j = 0; j < n; j++) if (holds_a_temp_under(nt, ids[j])) return 1;
  }
  return 0;
}
/* The last argument that holds a temp at it or under it, -1 where none
   does: one walk from the end for the whole call. */
static int last_arg_holding_a_temp(const NodeTable *nt, int argc, const int *argv) {
  for (int j = argc - 1; j >= 0; j--) if (holds_a_temp_under(nt, argv[j])) return j;
  return -1;
}
/* Did an argument after the splat at argv[k] run before the splat's operand
   is read? What is held in a temp ran ahead of the statement, so any of a
   later argument did (`last_held` is the last such argument); the operand
   `op` did too, in its place, where the whole of it is held. */
static int later_arg_ran_ahead(int k, int op, const int *argv, int last_held) {
  for (int i = 0; i < g_n_argov; i++)
    if (g_argov_node[i] == op || g_argov_node[i] == argv[k]) return 0;
  return last_held > k;
}
/* Can the receiver change what a splat's operand reads after the list of
   indexes is built? It is evaluated inside the call, after the list, unless
   it is held in a temp, which ran ahead of it. Only a receiver that reads
   and no more (a global, or subtree_is_pure_read) is known to change
   nothing. */
static int recv_runs_after_list(Compiler *c, int recv) {
  if (nt_kind(c->nt, recv) == NK_GlobalVariableReadNode || subtree_is_pure_read(c, recv)) return 0;
  for (int i = 0; i < g_n_argov; i++) if (g_argov_node[i] == recv) return 0;
  return 1;
}

/* builtin methods on a poly receiver the runtime answers by the value it holds: inject / reduce(:op), the Array reductions and slices, values_at, Fiber's resume / transfer / raise, Queue's enq / deq */
int emit_call_poly_builtin_arms(Compiler *c, int id, Buf *b, const NodeTable *nt, const char *name, int recv, int argc, const int *argv, TyKind rt) {
  /* Array-reduction methods on a boxed array element of a poly array (e.g.
     `runs.map { |r| r.sum }` over chunk_while runs). The runtime helper switches
     on the element's cls_id. Skipped when a user class defines the same method
     (it falls through to the general poly dispatch below). */
  /* inject/reduce(:op) on a container-read poly iterable (#3234) */
  if (recv >= 0 && rt == TY_POLY && argc == 1 && nt_ref(nt, id, "block") < 0 &&
      (is_reduce_alias(name)) &&
      comp_ntype(c, argv[0]) == TY_SYMBOL) {
    if (!poly_name_user_claimed(c, name, argc)) {
      buf_puts(b, "sp_poly_inject_sym("); emit_expr(c, recv, b); buf_puts(b, ", ");
      emit_expr(c, argv[0], b); buf_puts(b, ")");
      return 1;
    }
  }
  /* sum(seed) on a container-read row: numeric-tower accumulation from the
     boxed seed (#3234) */
  if (recv >= 0 && rt == TY_POLY && argc == 1 && nt_ref(nt, id, "block") < 0 &&
      sp_streq(name, "sum")) {
    int ncand9 = 0;
    for (int k = 0; k < c->nclasses; k++)
      if (comp_poly_arm_defines_n(c, k, name, argc)) ncand9++;
    if (ncand9 == 0) {
      emit_poly_sum_seed(c, recv, argv[0], b);
      return 1;
    }
  }
  /* shuffle / sample given `random:` on a boxed Array (emit_array_random_kw):
     the count arm below read the keyword hash as the count */
  if (emit_array_random_kw(c, id, b, nt, name, recv, argc, argv, rt)) return 1;
  /* The count-taking Array reads on a poly receiver. An array read out of a
     nested Array or Hash answers Array to #class but had no arm for these, so
     they raised NoMethodError (#3464). rotate's count is optional. */
  if (recv >= 0 && rt == TY_POLY && nt_ref(nt, id, "block") < 0 &&
      (argc == 1 || (argc == 0 && (sp_streq(name, "rotate") || sp_streq(name, "shuffle"))))) {
    const char *pn9 = NULL;
    if (is_first_or_take(name)) pn9 = "sp_poly_arr_take";
    else if (sp_streq(name, "last")) pn9 = "sp_poly_arr_last_n";
    else if (sp_streq(name, "drop")) pn9 = "sp_poly_arr_drop";
    else if (sp_streq(name, "rotate")) pn9 = "sp_poly_arr_rotate";
    else if (sp_streq(name, "sample")) pn9 = "sp_poly_arr_sample_n";
    else if (sp_streq(name, "min")) pn9 = "sp_poly_arr_min_n";
    else if (sp_streq(name, "max")) pn9 = "sp_poly_arr_max_n";
    else if (sp_streq(name, "shuffle") && argc == 0) pn9 = "sp_poly_arr_shuffle";
    if (pn9) {
      if (!poly_name_user_claimed(c, name, argc)) {
        Buf cb9; memset(&cb9, 0, sizeof cb9);
        /* a value that is no collection is the call's NoMethodError
           (sp_poly_enum_chk): nil.take(1) and its siblings answered [] */
        buf_printf(&cb9, "%s(sp_poly_enum_chk(", pn9);
        { Buf rb9; memset(&rb9, 0, sizeof rb9); emit_expr(c, recv, &rb9);
          buf_puts(&cb9, rb9.p ? rb9.p : "sp_box_nil()"); free(rb9.p); }
        buf_printf(&cb9, ", \"%s\")", name);
        if (argc == 1) { Buf nb9; memset(&nb9, 0, sizeof nb9); emit_int_expr(c, argv[0], &nb9);
                         buf_puts(&cb9, ", "); buf_puts(&cb9, nb9.p ? nb9.p : "0"); free(nb9.p); }
        else if (!sp_streq(name, "shuffle")) buf_puts(&cb9, ", 1");   /* rotate's default count */
        buf_puts(&cb9, ")");
        /* the helpers answer a boxed poly array; a slot typed as the array
           itself takes the pointer out of the box */
        emit_unbox_text(c, repr_of(c, id).as_ty, cb9.p ? cb9.p : "sp_box_nil()", b);
        free(cb9.p);
        return 1;
      }
    }
  }
  /* values_at takes any number of indices; collect them into a poly array. */
  if (recv >= 0 && rt == TY_POLY && argc >= 1 && nt_ref(nt, id, "block") < 0 &&
      sp_streq(name, "values_at")) {
    if (!poly_name_user_claimed(c, name, argc)) {
      int ti9 = ++g_tmp, held9 = -1, heldn9 = -1;
      emit_indent(g_pre, g_indent);
      buf_printf(g_pre, "sp_PolyArray *_t%d = sp_PolyArray_new(); SP_GC_ROOT(_t%d);\n", ti9, ti9);
      for (int k = 0; k < argc; k++) {
        /* a splatted index list contributes each of its elements, not itself:
           pushed whole it became one index and the call answered from that
           one alone (#4164) */
        if (nt_type(nt, argv[k]) && sp_streq(nt_type(nt, argv[k]), "SplatNode")) {
          int sx9 = nt_ref(nt, argv[k], "expression");
          TyKind st9 = sx9 >= 0 ? comp_ntype(c, sx9) : TY_POLY;
          /* a splatted Range gives its members and a splatted scalar is the
             index itself, unless it is nil when the call runs: read as an
             Array below, either was empty and the call answered from its
             other indexes alone. Where a later argument ran before this
             operand is read, or the receiver runs after it, what the
             operand holds then is not what CRuby splats: such a splat is
             read as it was */
          if (heldn9 != g_n_argov) { held9 = last_arg_holding_a_temp(nt, argc, argv); heldn9 = g_n_argov; }
          int ahead9 = later_arg_ran_ahead(k, sx9, argv, held9) || recv_runs_after_list(c, recv);
          if (st9 == TY_RANGE && !ahead9 && splat_asks_builtin(c, 1)) {
            Buf rb9; memset(&rb9, 0, sizeof rb9); emit_expr(c, sx9, &rb9);
            emit_indent(g_pre, g_indent);
            buf_printf(g_pre, "sp_poly_values_at_range(_t%d, %s);\n", ti9, rb9.p ? rb9.p : "");
            free(rb9.p);
            continue;
          }
          if (splat_operand_is_scalar(st9) && st9 != TY_NIL && !ahead9 && splat_asks_builtin(c, 0)) {
            Buf vb9; memset(&vb9, 0, sizeof vb9);
            emit_boxed(c, sx9, &vb9);
            emit_indent(g_pre, g_indent);
            buf_printf(g_pre, "sp_poly_values_at_scalar(_t%d, %s);\n", ti9, vb9.p ? vb9.p : "sp_box_nil()");
            free(vb9.p);
            continue;
          }
          int ts9 = ++g_tmp, tj9 = ++g_tmp;
          /* the list first: what it hoists belongs ahead of the line that
             reads it, not inside that line's call */
          { Buf sb9; memset(&sb9, 0, sizeof sb9);
            if (sx9 >= 0) emit_boxed(c, sx9, &sb9);
            emit_indent(g_pre, g_indent);
            buf_printf(g_pre, "sp_PolyArray *_t%d = sp_poly_to_poly_array(%s); SP_GC_ROOT(_t%d);\n",
                       ts9, sb9.p ? sb9.p : "sp_box_nil()", ts9);
            free(sb9.p); }
          emit_indent(g_pre, g_indent);
          buf_printf(g_pre, "for (sp_int _t%d = 0; _t%d < sp_PolyArray_length(_t%d); _t%d++)"
                            " sp_PolyArray_push(_t%d, sp_PolyArray_get(_t%d, _t%d));\n",
                     tj9, tj9, ts9, tj9, ti9, ts9, tj9);
          continue;
        }
        /* the index first, for the same reason */
        Buf ab9; memset(&ab9, 0, sizeof ab9);
        emit_boxed(c, argv[k], &ab9);
        emit_indent(g_pre, g_indent);
        buf_printf(g_pre, "sp_PolyArray_push(_t%d, %s);\n", ti9, ab9.p ? ab9.p : "sp_box_nil()");
        free(ab9.p);
      }
      Buf cv9; memset(&cv9, 0, sizeof cv9);
      buf_puts(&cv9, "sp_poly_arr_values_at(");
      { Buf rv9; memset(&rv9, 0, sizeof rv9); emit_expr(c, recv, &rv9);
        buf_puts(&cv9, rv9.p ? rv9.p : "sp_box_nil()"); free(rv9.p); }
      buf_printf(&cv9, ", _t%d)", ti9);
      emit_unbox_text(c, repr_of(c, id).as_ty, cv9.p ? cv9.p : "sp_box_nil()", b);
      free(cv9.p);
      return 1;
    }
  }
  /* resume / transfer / raise on a boxed Fiber (one read out of an Array, or
     a local that was nil first). Anything else in the slot raises
     NoMethodError at run time -- but a boxed Thread answers #raise too (one
     read back out of a Hash's keys): raised in that thread, answering nil
     as Thread#raise does. */
  if (recv >= 0 && rt == TY_POLY && nt_ref(nt, id, "block") < 0 &&
      (sp_streq(name, "resume") || sp_streq(name, "transfer") ||
       (sp_streq(name, "raise") && argc <= 3))) {
    if (!poly_name_user_claimed(c, name, argc) && sp_streq(name, "raise")) {
      Buf fv; memset(&fv, 0, sizeof fv);
      int tv = ++g_tmp, tf = ++g_tmp, tr = ++g_tmp;
      buf_printf(&fv, "({ sp_RbVal _t%d = ", tv);
      emit_boxed(c, recv, &fv);
      buf_printf(&fv, "; SP_GC_ROOT_RBVAL(_t%d); sp_RbVal _t%d; "
                      "if (_t%d.tag == SP_TAG_OBJ && _t%d.cls_id == SP_BUILTIN_THREAD) { (void)(",
                 tv, tr, tv, tv);
      char tt[48]; snprintf(tt, sizeof tt, "((sp_thread *)_t%d.v.p)", tv);
      emit_concurrency_raise(c, tt, argc, argv, "sp_thread", 't', "sp_Thread_raise", &fv);
      buf_printf(&fv, "); _t%d = sp_box_nil(); } else { sp_Fiber *_t%d = sp_poly_as_fiber(_t%d, \"raise\"); "
                      "SP_GC_ROOT(_t%d); _t%d = ", tr, tf, tv, tf, tr);
      char ft[32]; snprintf(ft, sizeof ft, "_t%d", tf);
      emit_concurrency_raise(c, ft, argc, argv, "sp_Fiber", 'f', "sp_Fiber_raise", &fv);
      buf_printf(&fv, "; } _t%d; })", tr);
      emit_unbox_text(c, repr_of(c, id).as_ty, fv.p, b);
      free(fv.p);
      return 1;
    }
    if (!poly_name_user_claimed(c, name, argc)) {
      Buf fv; memset(&fv, 0, sizeof fv);
      int tf = ++g_tmp;
      buf_printf(&fv, "({ sp_Fiber *_t%d = sp_poly_as_fiber(", tf);
      emit_boxed(c, recv, &fv);
      buf_printf(&fv, ", \"%s\"); SP_GC_ROOT(_t%d); ", name, tf);
      char ft[32]; snprintf(ft, sizeof ft, "_t%d", tf);
      char fn[32]; snprintf(fn, sizeof fn, "sp_Fiber_%s_n", name);
      emit_fiber_pass_call(c, fn, ft, argc, argv, &fv);
      buf_puts(&fv, "; })");
      emit_unbox_text(c, repr_of(c, id).as_ty, fv.p, b);
      free(fv.p);
      return 1;
    }
  }
  if (recv >= 0 && rt == TY_POLY && argc == 0 && nt_ref(nt, id, "block") < 0) {
    const char *pm = NULL;
    if (sp_streq(name, "sum")) pm = "sp_poly_sum";
    else if (sp_streq(name, "min")) pm = "sp_poly_min";
    else if (sp_streq(name, "max")) pm = "sp_poly_max";
    else if (sp_streq(name, "first")) pm = "sp_poly_first";
    else if (sp_streq(name, "last")) pm = "sp_poly_last";
    else if (sp_streq(name, "sample")) pm = "sp_poly_sample";
    /* a Thread (Fiber-modelled) carried through a poly slot: #value/#resume/#join
       dispatch on the boxed Fiber when no user class defines the name (#1261). */
    else if (sp_streq(name, "value")) pm = "sp_poly_fiber_value";
    else if (sp_streq(name, "join")) pm = "sp_poly_fiber_join";
    /* and #alive? / #status, which a pool polls through its worker Array
       (#4463); these answer their own C types, not a boxed value */
    else if (sp_streq(name, "alive?")) pm = "sp_poly_fiber_alive";
    else if (sp_streq(name, "status")) pm = "sp_poly_thread_status";
    /* and #kill, which a shutdown path reaches through the handle it kept in
       an Array or an ivar rather than a traceable local (#4619) */
    else if (sp_streq(name, "kill")) pm = "sp_poly_thread_kill";
    else if (sp_streq(name, "blocking?")) pm = "sp_poly_fiber_blocking";
    if (pm) {
      /* Attr readers count as user definitions too: `attr_accessor :value`
         must shadow the builtin helper exactly like `def value` does, or the
         reader call is hijacked (e.g. sp_poly_fiber_value on a Node). The
         general poly dispatch below emits reader arms, so it handles them. */
      if (!poly_name_user_claimed(c, name, argc)) {
        Repr wr = repr_of(c, id);
        int is_bool = sp_streq(name, "alive?") || sp_streq(name, "blocking?");
        if (is_bool && wr.kind == RK_BOXED) buf_puts(b, "sp_box_bool(");
        buf_printf(b, "%s(", pm); emit_expr(c, recv, b); buf_puts(b, ")");
        if (is_bool && wr.kind == RK_BOXED) buf_puts(b, ")");
        return 1;
      }
    }
  }

  /* The Queue names no other builtin answers, on a boxed Queue (one taken
     out of an Array or an ivar): #enq, #deq and #num_waiting. Anything else
     in the slot raises NoMethodError at run time. */
  if (recv >= 0 && rt == TY_POLY && nt_ref(nt, id, "block") < 0 &&
      ((argc == 0 && (sp_streq(name, "deq") || sp_streq(name, "num_waiting"))) ||
       (argc == 1 && sp_streq(name, "enq")) ||
       (argc == 1 && sp_streq(name, "deq")) || (argc == 2 && sp_streq(name, "enq")))) {
    if (!poly_name_user_claimed(c, name, argc)) {
      Buf qv; memset(&qv, 0, sizeof qv);
      if (sp_streq(name, "deq") && argc == 1) {   /* deq(non_block) */
        buf_puts(&qv, "sp_poly_queue_pop_flag("); emit_boxed(c, recv, &qv);
        buf_puts(&qv, ", \"deq\", sp_poly_truthy("); emit_boxed(c, argv[0], &qv); buf_puts(&qv, "))");
      }
      else if (argc == 2) {   /* enq(obj, non_block) */
        buf_puts(&qv, "sp_poly_queue_push_flag("); emit_boxed(c, recv, &qv);
        buf_puts(&qv, ", \"enq\", "); emit_boxed(c, argv[0], &qv);
        buf_puts(&qv, ", sp_poly_truthy("); emit_boxed(c, argv[1], &qv); buf_puts(&qv, "))");
      }
      else {
        buf_printf(&qv, "sp_poly_queue_%s(", name);
        emit_boxed(c, recv, &qv);
        if (argc == 1) { buf_puts(&qv, ", "); emit_boxed(c, argv[0], &qv); }
        buf_puts(&qv, ")");
      }
      Repr wr = repr_of(c, id);
      TyKind want = wr.as_ty;
      if (wr.kind == RK_BOXED) buf_puts(b, qv.p);
      else emit_unbox_text(c, want, qv.p, b);
      free(qv.p);
      return 1;
    }
  }
  /* The same for a boxed Mutex (one read back out of a Hash of locks):
     #lock, #unlock, #try_lock and #locked?. #owned? is File::Stat's too
     and goes through the boxed stream arm. */
  if (recv >= 0 && rt == TY_POLY && argc == 0 && nt_ref(nt, id, "block") < 0 &&
      (sp_streq(name, "lock") || sp_streq(name, "unlock") ||
       sp_streq(name, "try_lock") || sp_streq(name, "locked?")) &&
      !poly_name_user_claimed(c, name, argc)) {
    int is_bool = sp_streq(name, "try_lock") || sp_streq(name, "locked?");
    Buf mv; memset(&mv, 0, sizeof mv);
    buf_printf(&mv, "sp_poly_mutex_%s(", sp_streq(name, "locked?") ? "locked" : name);
    emit_boxed(c, recv, &mv);
    buf_puts(&mv, ")");
    Repr wr = repr_of(c, id);
    if (is_bool && wr.kind == RK_BOXED) buf_printf(b, "sp_box_bool(%s)", mv.p);
    else if (is_bool || wr.kind == RK_BOXED) buf_puts(b, mv.p);
    else emit_unbox_text(c, wr.as_ty, mv.p, b);
    free(mv.p);
    return 1;
  }
  return 0;
}
