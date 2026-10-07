/* lib/sp_poly_cold2.c -- the cold half of the boxed-value runtime, second unit.

   lib/sp_poly_cold.c is at gcc's inline unit limit (--param
   inline-unit-growth): a statement more or less in one of its functions
   changes the order gcc inlines calls in, and with it the code of functions
   nobody touched. A function of the cold half that has to change is compiled
   here instead, under that file's rules (see its head comment): the header is
   included as a host, the state the generated unit owns stays extern, and
   nothing here may keep mutable state of its own. `make poly-cold-test`
   checks this file as it checks that one. The three renamed functions are
   defined there. */
#define SPINEL_EXT_HOST 1
#include "sp_compat.h"
#undef SP_CONSTRUCTOR
#define SP_CONSTRUCTOR SP_UNUSED
#define sp_sym_to_s sp_poly_cold_sym_to_s
#define sp_class_to_s sp_poly_cold_class_to_s
#define sp_sym_intern sp_poly_cold_sym_intern
#include "spinel_rt.h"

/* String#clear on a plain string box: a fresh empty string the receiver
   takes back, as the typed clear builds; a frozen one raises. Out of line:
   the allocation inlined here needs more saved registers than any arm of
   sp_poly_clear, and every receiver would pay for them. */
static SP_NOINLINE sp_RbVal sp_poly_clear_str(const char *s)
{
  sp_str_check_mutable(s);
  return sp_box_str(sp_str_from_bytes("", 0));
}

/* `#clear` on a poly value (a mixed Array/Hash collection element reached via
   `&:clear`, a value read back from a Hash, a parameter that takes more than
   one kind): empty the container in place, dispatching on its runtime kind,
   and return the receiver.
   A frozen Array or Hash is not emptied: CRuby raises before it removes
   anything, for an empty one too. An Array's flag is in its struct, a Hash's
   in its collector header, and each arm reads its own: the box may hold a
   pointer with no such header in front of it (a Regexp's pattern is from
   calloc), so no flag is read before the class is known. */
sp_RbVal sp_poly_clear(sp_RbVal v)
{
  if (v.tag == SP_TAG_OBJ && v.cls_id == SP_BUILTIN_QUEUE && v.v.p) { sp_Queue_clear((sp_queue *)v.v.p); return v; }
  if (v.tag == SP_TAG_STR) return sp_poly_clear_str(v.v.s);
  /* nil, a number or a boolean has no clear; an object never fails this
     check, so only a receiver that is not one pays for it */
  if (v.tag != SP_TAG_OBJ || !v.v.p) { sp_poly_coll_chk(v, "clear"); return v; }
  switch (v.cls_id) {
    case SP_BUILTIN_INT_ARRAY:      if (((sp_IntArray *)v.v.p)->frozen) goto frozen_array; ((sp_IntArray *)v.v.p)->len = 0; break;
    case SP_BUILTIN_FLT_ARRAY:      if (((sp_FloatArray *)v.v.p)->frozen) goto frozen_array; ((sp_FloatArray *)v.v.p)->len = 0; break;
    case SP_BUILTIN_STR_ARRAY:      if (((sp_StrArray *)v.v.p)->frozen) goto frozen_array; ((sp_StrArray *)v.v.p)->len = 0; break;
    case SP_BUILTIN_POLY_ARRAY:     if (((sp_PolyArray *)v.v.p)->frozen) goto frozen_array; ((sp_PolyArray *)v.v.p)->len = 0; break;
    case SP_BUILTIN_PTR_ARRAY:      if (((sp_PtrArray *)v.v.p)->frozen) goto frozen_array; ((sp_PtrArray *)v.v.p)->len = 0; break;
    case SP_BUILTIN_STRBUF: {
      sp_String *_m = (sp_String *)v.v.p;
      if (sp_String_is_frozen(_m)) { sp_raise_frozen_str(_m->data); break; }
      _m->len = 0; _m->data[0] = 0; sp_fd_publish(_m);
      break;
    }
    case SP_BUILTIN_STR_INT_HASH:   if (sp_gc_is_frozen(v.v.p)) goto frozen_hash; sp_StrIntHash_clear((sp_StrIntHash *)v.v.p); break;
    case SP_BUILTIN_STR_STR_HASH:   if (sp_gc_is_frozen(v.v.p)) goto frozen_hash; sp_StrStrHash_clear((sp_StrStrHash *)v.v.p); break;
    case SP_BUILTIN_INT_STR_HASH:   if (sp_gc_is_frozen(v.v.p)) goto frozen_hash; sp_IntStrHash_clear((sp_IntStrHash *)v.v.p); break;
    case SP_BUILTIN_INT_INT_HASH:   if (sp_gc_is_frozen(v.v.p)) goto frozen_hash; sp_IntIntHash_clear((sp_IntIntHash *)v.v.p); break;
    case SP_BUILTIN_STR_POLY_HASH:  if (sp_gc_is_frozen(v.v.p)) goto frozen_hash; sp_StrPolyHash_clear((sp_StrPolyHash *)v.v.p); break;
    /* the two below are sp_SymPolyHash_clear and sp_PolyPolyHash_clear
       (lib/sp_poly_cold.c) written out: that unit inlines them into its own
       callers, and from here each would be a call the receiver pays for */
    case SP_BUILTIN_SYM_POLY_HASH: {
      sp_SymPolyHash *h = (sp_SymPolyHash *)v.v.p;
      if (sp_gc_is_frozen(h)) goto frozen_hash;
      for (sp_int i = 0; i < h->cap; i++) h->keys[i] = -1;
      h->len = 0;
      break;
    }
    case SP_BUILTIN_POLY_POLY_HASH: {
      sp_PolyPolyHash *h = (sp_PolyPolyHash *)v.v.p;
      if (sp_gc_is_frozen(h)) goto frozen_hash;
      for (sp_int i = 0; i < h->cap; i++) h->occ[i] = 0;
      h->len = 0;
      break;
    }
    default: sp_raise_nomethod(sp_nomethod_msg("clear", v)); break;
  }
  return v;
  /* the raise takes the box as it came, so an arm carries the test alone */
frozen_array:
  sp_raise_frozen_array_v(v);
  return v;
frozen_hash:
  sp_raise_frozen_obj(v, SPL("can't modify frozen Hash"));
  return v;
}
