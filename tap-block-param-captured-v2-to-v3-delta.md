diff --git a/src/analyze_pass.c b/src/analyze_pass.c
index 00f907f39..cd637af2f 100644
--- a/src/analyze_pass.c
+++ b/src/analyze_pass.c
@@ -11014,8 +11014,8 @@ static int subtree_has_proc_create(Compiler *c, int root, int depth) {
 }
 
 /* Whether the value of `node` is read where it stands: written to a
-   variable, passed, called on, returned, or the answer of a method body, of a
-   conditional that is itself read, or of a block whose answer is kept. */
+   variable, passed, called on, returned, or the answer of a method body or of
+   a conditional that is itself read. */
 static int tap_value_read(const NodeTable *nt, const int *par, int node, int depth) {
   int p = par[node];
   if (p < 0 || depth > 64) return 0;
@@ -11040,21 +11040,36 @@ static int tap_value_read(const NodeTable *nt, const int *par, int node, int dep
       if (owner < 0) return 0;
       NodeKind ok = nt_kind(nt, owner);
       if (ok == NK_DefNode) return 1;
-      if (ok == NK_BlockNode) return !an_value_dropped(nt, par, node) && tap_value_read(nt, par, owner, depth + 1);
       if (ok == NK_IfNode || ok == NK_UnlessNode || ok == NK_ElseNode || ok == NK_ParenthesesNode)
         return tap_value_read(nt, par, p, depth + 1);
       return 0;
     }
-    case NK_BlockNode: {
-      /* the block's answer is its call's: `x = xs.map { [].tap { ... } }` */
-      int bc = par[p];
-      return bc >= 0 && nt_kind(nt, bc) == NK_CallNode && nt_ref(nt, bc, "block") == p;
-    }
     default:
       return 0;
   }
 }
 
+/* Does a proc literal under `root` call a String position mutator (`[]=`,
+   insert, setbyte, slice!, clear) on the local `name`? */
+static int proc_position_mutates_local(Compiler *c, int root, const char *name, int in_proc, int depth) {
+  const NodeTable *nt = c->nt;
+  if (root < 0 || root >= nt->count || depth > 200) return 0;
+  if (is_proc_create(c, root) && !nt_int(nt, root, "cap_iife", 0)) in_proc = 1;
+  if (in_proc && nt_kind(nt, root) == NK_CallNode) {
+    const char *cn = nt_str(nt, root, "name");
+    int r = nt_ref(nt, root, "receiver");
+    const char *rn = r >= 0 && nt_kind(nt, r) == NK_LocalVariableReadNode ? nt_str(nt, r, "name") : NULL;
+    if (cn && rn && is_string_position_mutator(cn) && sp_streq(rn, name)) return 1;
+  }
+  const SpNode *nd = &nt->nodes[root];
+  for (int i = 0; i < nd->nr; i++)
+    if (proc_position_mutates_local(c, nd->r[i].ref, name, in_proc, depth + 1)) return 1;
+  for (int i = 0; i < nd->na; i++)
+    for (int j = 0; j < nd->a[i].n; j++)
+      if (proc_position_mutates_local(c, nd->a[i].ids[j], name, in_proc, depth + 1)) return 1;
+  return 0;
+}
+
 /* Whether `recv.tap { |x| ... }` (or then) is emitted in place, its block
    parameter the receiver itself, where a proc in the block captures the
    parameter: a receiver that is a local variable, a Hash literal, or an
@@ -11066,7 +11081,19 @@ static int tap_value_read(const NodeTable *nt, const int *par, int node, int dep
 static int tap_then_unwrapped(Compiler *c, const int *par, int id, int rcv) {
   const NodeTable *nt = c->nt;
   switch (nt_kind(nt, rcv)) {
-    case NK_LocalVariableReadNode: case NK_HashNode:
+    case NK_LocalVariableReadNode: {
+      /* A String parameter that a proc literal in the block changes by
+         position is, in place, a shared String a proc captures, and that
+         statement does not build over one (`def m(q); f = -> { q.insert(1,
+         "-") }; f.call; end` on its own does not): the wrapper stays unless
+         the receiver is known to be an Array or a Hash. */
+      TyKind rt = infer_type(c, rcv);
+      int blk = nt_ref(nt, id, "block");
+      const char *pn = blk >= 0 ? block_param_name(c, blk, 0) : NULL;
+      return ty_is_array(rt) || ty_is_hash(rt) || !pn ||
+             !proc_position_mutates_local(c, nt_ref(nt, blk, "body"), pn, 0, 0);
+    }
+    case NK_HashNode:
       return 1;
     case NK_ArrayNode: {
       int ne = -1;
diff --git a/test/tap_block_param_proc_position.rb b/test/tap_block_param_proc_position.rb
new file mode 100644
index 000000000..2d5c85c3f
--- /dev/null
+++ b/test/tap_block_param_proc_position.rb
@@ -0,0 +1,29 @@
+# A String parameter of a `tap`, `then` or `yield_self` block that a proc
+# literal written in the block changes by position: what the block sees of
+# it. (What the receiver keeps afterwards is not asked here.)
+u1 = "qrs".dup
+u1.tap { |q| f = -> { q[0, 2] = "Z" }; f.call; p q }
+u2 = "qrs".dup
+u2.then { |q| f = -> { q.insert(1, "-") }; f.call; p q }
+u3 = "qrs".dup
+u3.yield_self { |q| f = proc { q.setbyte(0, 65) }; f.call; p q }
+u4 = "qrs".dup
+u4.tap { |q| f = -> { q.slice!(0) }; f.call; p q }
+u5 = "qrs".dup
+u5.tap { |q| f = -> { q.clear; 1 }; f.call; p q }
+
+# the same over a method's parameter, and a closure kept past the block
+def change(x) = x.tap { |q| f = -> { q.insert(0, "+") }; f.call; p q }
+change("qrs".dup)
+kept = nil
+u6 = "qrs".dup
+u6.tap { |q| kept = -> { q.insert(1, "-"); q } }
+p kept.call
+
+# an Array and a Hash changed the same way are the receiver itself
+a = [1, 2, 3]
+a.tap { |q| f = -> { q.insert(1, 7); q[0] = 9 }; f.call }
+p a
+h = { 1 => 2 }
+h.tap { |q| f = -> { q[3] = 4 }; f.call }
+p h[3], h.size
diff --git a/test/tap_block_param_proc_position.rb.expected b/test/tap_block_param_proc_position.rb.expected
new file mode 100644
index 000000000..38f460771
--- /dev/null
+++ b/test/tap_block_param_proc_position.rb.expected
@@ -0,0 +1,10 @@
+"Zs"
+"q-rs"
+"Ars"
+"rs"
+""
+"+qrs"
+"q-rs"
+[9, 7, 2, 3]
+4
+2
