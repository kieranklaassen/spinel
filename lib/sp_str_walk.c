/* sp_str_walk.c -- a String Range walked a member at a time.
 *
 * An object of its own in libspinel_rt.a. lib/sp_array.c, where
 * sp_str_upto_narrow is, and lib/sp_cold.c, where the other String Range
 * functions are, each sit at gcc's inline limit for a unit: a function
 * added to either, or a line to one of theirs, changes what gcc inlines
 * into functions that have nothing to do with a Range. Here no other
 * object changes. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sp_alloc.h"
#include "sp_str.h"
#include "sp_array.h"
#include "sp_range.h"

/* The walk a sp_StrWalk is on. */
enum { SP_STR_WALK_OVER, SP_STR_WALK_BYTES, SP_STR_WALK_DIGITS, SP_STR_WALK_SUCC, SP_STR_WALK_WIDE };

/* Two all-digit ends of unequal width, one of them past the 18 digits a
   long long holds. At one width the succ walk is right at any width: the
   bytes order the ends as the numbers do, and succ reaches the end. */
static SP_NOINLINE int sp_str_wide_digits(const char *s, const char *e) {
  size_t i = 0, j = 0;
  while (s[i] >= '0' && s[i] <= '9') i++;
  while (e[j] >= '0' && e[j] <= '9') j++;
  if (i == j || i == 0 || j == 0 || (i <= 18 && j <= 18)) return 0;
  return i == sp_str_byte_len(s) && j == sp_str_byte_len(e);
}
/* Two all-digit Strings as numbers: leading zeros aside, the longer is the
   greater, and at one width the bytes say it. */
static int sp_str_digits_cmp(const char *a, const char *b) {
  size_t la = sp_str_byte_len(a), lb = sp_str_byte_len(b);
  while (la > 1 && *a == '0') { a++; la--; }
  while (lb > 1 && *b == '0') { b++; lb--; }
  if (la != lb) return la < lb ? -1 : 1;
  int r = memcmp(a, b, la);
  return r < 0 ? -1 : r > 0;
}

/* Past 18 digits the same numbers, as CRuby walks them on Bignums: each
   member is the one before by String#succ, which carries through the
   digits and keeps the begin's zeros, compared with the end as a number.
   Out of line, so the other walks keep their code. */
static SP_NOINLINE const char *sp_str_wide_first(sp_StrWalk *w, const char *s, const char *e, sp_int excl) {
  int c = sp_str_digits_cmp(s, e);
  if (c > 0 || (excl && c == 0)) return NULL;
  w->cur = s; w->end = e; w->excl = excl;
  w->kind = SP_STR_WALK_WIDE;
  return sp_str_from_bytes(s, sp_str_byte_len(s));
}
static SP_NOINLINE const char *sp_str_wide_next(sp_StrWalk *w) {
  w->cur = sp_str_succ(w->cur);
  int c = sp_str_digits_cmp(w->cur, w->end);
  if (c > 0 || (w->excl && c == 0)) { w->kind = SP_STR_WALK_OVER; return NULL; }
  return sp_str_from_bytes(w->cur, sp_str_byte_len(w->cur));
}

/* sp_str_upto_each's walk a member at a time, for a caller whose loop body
   cannot be a callback: sp_str_walk_first answers the first member or NULL,
   sp_str_walk_next the one after. The cases and their order are
   sp_str_upto_narrow's (lib/sp_array.c), with the wide digits ahead of its
   succ walk, and each member is a fresh copy. The caller roots w->cur,
   w->end and w->stop before the first call. */
static const char *sp_str_walk_member(sp_StrWalk *w) {
  if (w->kind == SP_STR_WALK_BYTES) {
    char one = (char)w->at;
    return sp_str_from_bytes(&one, 1);
  }
  if (w->kind == SP_STR_WALK_DIGITS) {
    char buf[32];
    int n = snprintf(buf, sizeof buf, "%.*lld", w->width, w->at);
    return sp_str_from_bytes(buf, (size_t)n);
  }
  return sp_str_from_bytes(w->cur, sp_str_byte_len(w->cur));
}
const char *sp_str_walk_first(sp_StrWalk *w, const char *s, const char *e, sp_int excl) {SP_GC_ROOT_STR(s);SP_GC_ROOT_STR(e);
  w->kind = SP_STR_WALK_OVER;
  if (!s || !e) return NULL;
  size_t sl = sp_str_byte_len(s), el = sp_str_byte_len(e);
  int ascii = 1;
  for (size_t i = 0; i < sl; i++) if ((unsigned char)s[i] >= 0x80) ascii = 0;
  for (size_t i = 0; i < el; i++) if ((unsigned char)e[i] >= 0x80) ascii = 0;
  /* one ASCII character at each end: every byte between, so ("A".."c")
     holds the punctuation between "Z" and "a" */
  if (ascii && sl == 1 && el == 1) {
    w->at = (unsigned char)s[0];
    w->lim = (unsigned char)e[0] + (excl ? 0 : 1);
    if (w->at >= w->lim) return NULL;
    w->kind = SP_STR_WALK_BYTES;
    return sp_str_walk_member(w);
  }
  /* two all-digit ends: the numbers between, zero-padded to the begin's
     width, so ("9".."11") holds "9", "10", "11" (#3549) and ("1".."010")
     stops at "10" */
  int digits = ascii && sl > 0 && el > 0 && sl <= 18 && el <= 18;
  for (size_t i = 0; digits && i < sl; i++) if (s[i] < '0' || s[i] > '9') digits = 0;
  for (size_t i = 0; digits && i < el; i++) if (e[i] < '0' || e[i] > '9') digits = 0;
  if (digits) {
    w->at = strtoll(s, NULL, 10);
    w->lim = strtoll(e, NULL, 10) + (excl ? 0 : 1);
    w->width = (int)sl;
    if (w->at >= w->lim) return NULL;
    w->kind = SP_STR_WALK_DIGITS;
    return sp_str_walk_member(w);
  }
  if (sl != el && sp_str_wide_digits(s, e)) return sp_str_wide_first(w, s, e, excl);
  /* otherwise String#succ from the begin up to the end, never past the
     end's length, so ("a".."bb") runs through "z" and on to "bb", and
     ("aa".."z") -- whose begin is the end's successor -- is empty */
  int cmp = sp_str_cmp_bytes(s, e);
  if (cmp > 0 || (excl && cmp == 0)) return NULL;
  /* `cur` walks the range via String#succ, allocating a fresh heap string each
     step; the next sp_str_alloc can trigger a GC that would sweep the current
     succ string, so the copy read freed memory (#3152). The caller's root on
     the slot tracks each succ reassignment. */
  w->cur = s; w->end = e; w->excl = excl;
  w->stop = sp_str_succ(e);
  if (sp_str_eq(w->cur, w->stop)) return NULL;
  w->kind = SP_STR_WALK_SUCC;
  return sp_str_walk_member(w);
}
const char *sp_str_walk_next(sp_StrWalk *w) {
  if (w->kind == SP_STR_WALK_BYTES || w->kind == SP_STR_WALK_DIGITS) {
    if (++w->at >= w->lim) { w->kind = SP_STR_WALK_OVER; return NULL; }
    return sp_str_walk_member(w);
  }
  if (w->kind == SP_STR_WALK_WIDE) return sp_str_wide_next(w);
  if (w->kind != SP_STR_WALK_SUCC) return NULL;
  w->kind = SP_STR_WALK_OVER;
  if (!w->excl && sp_str_eq(w->cur, w->end)) return NULL;
  w->cur = sp_str_succ(w->cur);
  if (w->excl && sp_str_eq(w->cur, w->end)) return NULL;
  size_t cl = sp_str_byte_len(w->cur);
  if (cl > sp_str_byte_len(w->end) || cl == 0) return NULL;
  if (sp_str_eq(w->cur, w->stop)) return NULL;
  w->kind = SP_STR_WALK_SUCC;
  return sp_str_walk_member(w);
}

/* The members String#upto yields, each passed to fn until it answers
   nonzero. Two all-digit ends of unequal width past 18 digits walk on the
   pair above; every other range is sp_str_upto_narrow's, which stays in
   lib/sp_array.c under that name so that object keeps its code. */
static SP_NOINLINE void sp_str_upto_wide(const char *s, const char *e, sp_int excl, int (*fn)(const char *, void *), void *arg) {
  sp_StrWalk w = {0};
  SP_GC_ROOT_STR(w.cur); SP_GC_ROOT_STR(w.end); SP_GC_ROOT_STR(w.stop);
  for (const char *m = sp_str_walk_first(&w, s, e, excl); m; m = sp_str_walk_next(&w))
    if (fn(m, arg)) return;
}
void sp_str_upto_each(const char *s, const char *e, sp_int excl, int (*fn)(const char *, void *), void *arg) {
  if (s && e && *s >= '0' && *s <= '9' && sp_str_wide_digits(s, e)) sp_str_upto_wide(s, e, excl, fn, arg);
  else sp_str_upto_narrow(s, e, excl, fn, arg);
}

/* #first(n), #take(n) and #min(n): the first n members, with the walk left
   there as CRuby leaves its each, so the first three of ("a".."zzzzzzzz") are
   three Strings and not the range built whole. */
typedef struct { sp_StrArray *a; sp_int n; } sp_srange_first_t;
static int sp_srange_first_i(const char *m, void *arg) {
  sp_srange_first_t *t = (sp_srange_first_t *)arg;
  sp_StrArray_push(t->a, m);
  return sp_StrArray_length(t->a) >= t->n;
}
sp_StrArray *sp_srange_first_n(sp_StrRange r, sp_int n) {
  if (!r.first) sp_raise_cls("TypeError", "can't iterate from NilClass");
  if (!r.last) sp_raise_cls("RangeError", "cannot convert endless range to an array");
  sp_StrArray *a = sp_StrArray_new(); SP_GC_ROOT(a);
  sp_srange_first_t t = { a, n };
  if (n > 0) sp_str_upto_each(r.first, r.last, r.excl, sp_srange_first_i, &t);
  return a;
}
