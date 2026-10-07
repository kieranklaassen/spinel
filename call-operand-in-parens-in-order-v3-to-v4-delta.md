diff --git a/src/codegen_call.c b/src/codegen_call.c
index a78a852e..825ec3fe 100644
--- a/src/codegen_call.c
+++ b/src/codegen_call.c
@@ -18607,6 +18607,24 @@ static int operand_hoists_effect(Compiler *c, int node) {
   return 0;
 }
 
+/* Is the operand a literal or a variable's read: nothing that runs or
+   raises, and no more read than the one variable? A global the runtime sets
+   (`$~`, `$?`) is none: a later operand's match changes it. */
+static int operand_is_plain(Compiler *c, int node) {
+  switch (nt_kind(c->nt, node)) {
+    case NK_StringNode: case NK_RegularExpressionNode:
+      return 1;
+    case NK_GlobalVariableReadNode: {
+      const char *nm = nt_str(c->nt, node, "name");
+      return nm && nm[0] == '$' && nm[1] >= 'a' && nm[1] <= 'z';
+    }
+    case NK_CallNode: case NK_ParenthesesNode: case NK_StatementsNode:
+      return 0;
+    default:
+      return subtree_is_pure_read(c, node);
+  }
+}
+
 /* Were the computed operands of call `id` bound once (emit_operands_in_order)
    and the rewrite declined? `set` records that it was. The call is emitted
    again without them, and is not asked a second time: asked on every
@@ -18690,7 +18708,7 @@ static int emit_operands_in_order(Compiler *c, int id, Buf *b) {
     TyKind t = comp_ntype(c, operand[i]);
     if (t == TY_STRING || t == TY_STRBUF || t == TY_POLY || t == TY_UNKNOWN) through = !prog_changes_string_in_place(c);
   }
-  int observable = 0, converts = 0;
+  int observable = 0, converts = 0, looked = 0;
   for (int i = 0; i < nop; i++) {
     /* an operand that may convert -- a user object, a boxed value -- is
        converted by the arm, in a hold that runs before the call: the
@@ -18723,7 +18741,10 @@ static int emit_operands_in_order(Compiler *c, int id, Buf *b) {
     NodeKind bk = through ? nt_kind(nt, unwrap_parens(c, operand[i])) : k;
     int bindable = (bk == NK_CallNode || bk == NK_SuperNode || bk == NK_IfNode || bk == NK_UnlessNode ||
                     bk == NK_ForwardingSuperNode || bk == NK_YieldNode || state_read || local_read);
-    if (!bindable) return emit_operands_before_unbound(c, id, operand, nop, recv >= 0, i, b);
+    if (!bindable) return looked ? 0 : emit_operands_before_unbound(c, id, operand, nop, recv >= 0, i, b);
+    /* the first one bound through its parentheses: where the call ran the
+       operands ahead of it first, it still does */
+    if (bk != k && !looked++ && emit_operands_before_unbound(c, id, operand, nop, recv >= 0, i, b)) return 1;
     int fr = operand[i] != recv && operand_fresh_str(c, operand[i]);
     TyKind t = fr ? TY_STRING : repr_of(c, operand[i]).as_ty;
     if (t == TY_UNKNOWN || t == TY_VOID || t == TY_NIL) return 0;
@@ -18777,6 +18798,17 @@ static int emit_operands_in_order(Compiler *c, int id, Buf *b) {
     node[p] = operand[i]; ty[p] = t; fresh[p] = 0; at[p] = i;
     nb++; nlate++;
   }
+  /* ...and one left in the call that the loop above does not bind: an
+     operand in parentheses, a Symbol's conditional, a division that raises.
+     `ma.values_at(($i + 5), (bump))` read the $i bump left, and `(7 / z)`
+     raised after bump had run; left to the arm, as before the parentheses
+     were looked through, both ran first. So they are looked through only
+     where each operand left ahead of the last bound one is a literal or a
+     variable's read, which a later operand that can change it has bound. */
+  for (int i = 0, p = 0; looked && i < obs_at; i++) {
+    if (p < nb && at[p] == i) p++;
+    else if (!operand_is_plain(c, operand[i])) return 0;
+  }
 
   size_t pre_mark = g_pre->len;
   int saved_tmp = g_tmp;
diff --git a/test/call_operand_in_parens_in_order.rb b/test/call_operand_in_parens_in_order.rb
index 3ebfb70e..7178a88e 100644
--- a/test/call_operand_in_parens_in_order.rb
+++ b/test/call_operand_in_parens_in_order.rb
@@ -43,3 +43,18 @@ $i = 1
 def bump = ($i += 10; 3)
 def nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
 p nums.slice($i + 1, (bump))
+
+# ...and so is one that stays in the call: in parentheses itself, a Symbol's
+# conditional, a division that raises. With the last operand bound around
+# them they ran after bump; those calls compile as they did
+$i = 1
+p nums.values_at(($i + 5), (bump))
+def syms = { a: 1, b: 2 }
+$i = 1
+p syms.fetch($i > 3 ? :b : :a, (bump))
+$i = 1
+begin
+  p nums.values_at((7 / z), (bump))
+rescue ZeroDivisionError
+  p $i
+end
diff --git a/test/call_operand_in_parens_in_order.rb.expected b/test/call_operand_in_parens_in_order.rb.expected
index d19afdd2..edc7866d 100644
--- a/test/call_operand_in_parens_in_order.rb.expected
+++ b/test/call_operand_in_parens_in_order.rb.expected
@@ -7,3 +7,6 @@
 "tt"
 ["mk", "late"]
 [3, 4, 5]
+[7, 4]
+1
+1
