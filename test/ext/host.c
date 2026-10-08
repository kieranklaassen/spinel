/* A pure-C host over the Layer-1 emission: init, entries through the header
   contract, a raise caught through the try helper. No Ruby involved. */
#include <stdio.h>
#include <string.h>
#include "k.h"

typedef struct { sp_int n; sp_int ret; } call_t;
static void call_must_pos(void *p) {
  call_t *c = (call_t *)p;
  c->ret = sp_ExtKernel_s_must_pos(c->n);
}

typedef struct { const char *s; const char *ret; } scall_t;
static void call_refuse(void *p) {
  scall_t *c = (scall_t *)p;
  c->ret = sp_ExtKernel_s_refuse(c->s);
}
static void call_refuse_object(void *p) {
  scall_t *c = (scall_t *)p;
  c->ret = sp_ExtKernel_s_refuse_object(c->s);
}
static void call_refuse_again(void *p) {
  scall_t *c = (scall_t *)p;
  c->ret = sp_ExtKernel_s_refuse_again(c->s);
}

int main(void) {
  Init_ext_kernel();
  printf("%lld\n", (long long)sp_ExtKernel_s_triple(14LL));
  printf("%s\n", sp_ExtKernel_s_shout(sp_str_from_bytes("hey", 3)));
  sp_IntArray *a = sp_IntArray_new();
  SP_GC_ROOT(a);
  sp_IntArray_push(a, 10); sp_IntArray_push(a, 20); sp_IntArray_push(a, 12);
  printf("%lld\n", (long long)sp_ExtKernel_s_total(a));
  call_t c = { -3, 0 };
  const char *cls = 0, *msg = 0;
  if (Init_ext_kernel_try(call_must_pos, &c, &cls, &msg))
    printf("raised %s: %s\n", cls, msg);
  c.n = 7;
  if (!Init_ext_kernel_try(call_must_pos, &c, &cls, &msg))
    printf("ok %lld\n", (long long)c.ret);
  /* The message is a C string: one with a NUL in it reads to the NUL, and one
     that begins with the six bytes the runtime marks such a message with, and
     has no NUL, reads whole. */
  scall_t s = { sp_str_from_bytes("left\0right", 10), 0 };
  if (Init_ext_kernel_try(call_refuse, &s, &cls, &msg))
    printf("raised %s: %s (%d bytes)\n", cls, msg, (int)strlen(msg));
  s.s = sp_str_from_bytes("\xff\xfe" "CM" "\xfd\x01" "AAAA rest", 15);
  if (Init_ext_kernel_try(call_refuse, &s, &cls, &msg))
    printf("raised %s: %d bytes, the last four \"%s\"\n", cls, (int)strlen(msg), msg + strlen(msg) - 4);
  /* A message that is such a marked message byte for byte, a NUL in its text,
     is a message like any other: it reads to its first NUL, the seventh byte.
     So does the message of an exception object, and of an exception that was
     rescued and raised again. */
  s.s = sp_str_from_bytes("\xff\xfe" "CM" "\xfd\x01\x05\0\0\0he\0lo", 15);
  if (Init_ext_kernel_try(call_refuse, &s, &cls, &msg))
    printf("raised %s: %d bytes\n", cls, (int)strlen(msg));
  if (Init_ext_kernel_try(call_refuse_object, &s, &cls, &msg))
    printf("raised %s as an object: %d bytes\n", cls, (int)strlen(msg));
  s.s = sp_str_from_bytes("left\0right", 10);
  if (Init_ext_kernel_try(call_refuse_object, &s, &cls, &msg))
    printf("raised %s as an object: %s (%d bytes)\n", cls, msg, (int)strlen(msg));
  if (Init_ext_kernel_try(call_refuse_again, &s, &cls, &msg))
    printf("raised %s again: %s (%d bytes)\n", cls, msg, (int)strlen(msg));
  return 0;
}
