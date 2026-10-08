/* sp_string.c -- the cold sp_String in-place mutators (see sp_string.h).
   prepend / insert / replace / dup are off the hot string-building path, so they
   are compiled once here instead of inline in every generated TU. */
#include "sp_string.h"
#include "sp_str.h"
#include <string.h>

void sp_String_prepend(sp_String*s,const char*t){SP_GC_ROOT(s);SP_GC_ROOT_STR(t);if(!s||!t)return;if(sp_String_is_frozen(s)){sp_raise_frozen_str(s->data);return;}int64_t tl=(int64_t)strlen(t);if(!sp_fd_grow(s,s->len+tl))return;memmove(s->data+tl,s->data,s->len+1);memcpy(s->data,t,tl);s->len+=tl;sp_fd_publish(s);}
/* String#insert(idx, str): insert at idx; negative idx is relative to len+1. */
void sp_String_insert(sp_String*s,int64_t idx,const char*t){SP_GC_ROOT(s);SP_GC_ROOT_STR(t);if(!s||!t)return;if(sp_String_is_frozen(s)){sp_raise_frozen_str(s->data);return;}int64_t tl=(int64_t)strlen(t);if(tl==0)return;if(idx<0)idx+=s->len+1;if(idx<0)idx=0;if(idx>s->len)idx=s->len;if(!sp_fd_grow(s,s->len+tl))return;memmove(s->data+idx+tl,s->data+idx,s->len-idx+1);memcpy(s->data+idx,t,tl);s->len+=tl;sp_fd_publish(s);}
/* String#replace(s): replace entire content. */
void sp_String_replace(sp_String*s,const char*t){SP_GC_ROOT(s);SP_GC_ROOT_STR(t);if(!s||!t)return;if(sp_String_is_frozen(s)){sp_raise_frozen_str(s->data);return;}int64_t tl=(int64_t)strlen(t);if(!sp_fd_grow(s,tl))return;memcpy(s->data,t,tl);s->data[tl]='\0';s->len=tl;sp_fd_publish(s);}
sp_String*sp_String_dup(sp_String*s){SP_GC_ROOT(s);return sp_String_new(s->data);}
/* The first growth past an inline payload (sp_String_new_inline_len) moves
   it to a malloc'd block, which the object now owns: its bytes are counted
   and the finalizer that frees them installed, as sp_String_new_len does
   from the start. The inline room stays part of the object. Rare, and kept
   out of sp_fd_grow so that one still inlines into every append. */
int sp_fd_grow_inline(sp_String *s, int64_t need){
  sp_gc_hdr *h = (sp_gc_hdr *)((char *)s - sizeof(sp_gc_hdr));
  int64_t new_cap = (need * 2) + 16;
  sp_str_lcache_drop(s->data);
  char *raw = (char *)malloc(SP_FD_OVH + new_cap);
  if (!raw) return 0;
  char *data = sp_fd_setup(raw);
  memcpy(data, s->data, (size_t)s->len + 1);
  s->cap = new_cap; s->data = data; sp_fd_own(s);
  h->size += s->cap + SP_FD_OVH; sp_gc_bytes_add(s->cap + SP_FD_OVH);
  if (!h->finalize) { h->finalize = sp_String_fin; sp_slab_set_fin(h); }
  return 1;
}

/* A handle made from a chilled String records the symbol whose to_s it holds
   (sp_String.chilled is its id + 1). */
void sp_String_chill(sp_String*r,const char*s){
  if(sp_str_is_chilled(s))r->chilled=(unsigned)(sp_str_chilled_sym(s)+1);
}
/* Such a handle is chilled until its first mutation, which makes it plain
   for good (CRuby's str_modify): sp_fd_publish clears the flag. A path that
   changes the bytes without publishing is caught here, at +@, by the bytes
   no longer being the symbol's name. */
int sp_String_chilled_now(sp_String*h){
  const char*nm=sp_sym_name_fn?sp_sym_name_fn((sp_sym)(h->chilled-1)):NULL;
  size_t n=nm?sp_str_byte_len(nm):0;
  if(nm&&(size_t)h->len==n&&memcmp(h->data,nm,n)==0)return 1;
  h->chilled=0;
  return 0;
}
/* Symbol#to_s and #id2name: CRuby answers a new chilled String each time
   (sp_str_is_chilled), so `s = sym.to_s; t = +s` copies and `t << x` leaves
   s alone. The symbol table's own name is a plain static that a handle would
   take as an ordinary String, so each symbol gets one chilled copy, built at
   its first to_s and kept as long as the symbol is: static storage with a
   header, which the collector neither marks nor sweeps, and the symbol ahead
   of it (sp_str_chilled_obj). The table is guarded by the heap lock, as the
   dedup table is. */
static const char**sp_sym_chilled_tab=NULL;
static sp_int sp_sym_chilled_cap=0;
const char*sp_sym_to_s_chilled(sp_sym id){
  const char*nm=sp_sym_name_fn?sp_sym_name_fn(id):sp_str_empty;
  if(id<0||!sp_sym_name_fn)return nm;
  SP_HEAP_LOCK();
  const char*hit=id<sp_sym_chilled_cap?sp_sym_chilled_tab[id]:NULL;
  SP_HEAP_UNLOCK();
  if(hit)return hit;
  size_t n=sp_str_byte_len(nm);
  sp_str_chilled_obj*o=(sp_str_chilled_obj*)malloc(sizeof(sp_str_chilled_obj)+n+1);
  if(!o)return nm;
  int ascii7=1;
  for(size_t i=0;i<n;i++)if((unsigned char)nm[i]>=0x80)ascii7=0;
  o->sym=id;
  o->h.next=(sp_str_hdr*)&sp_str_chilled_tag;
  o->h.size=(uint32_t)(n+1)|(ascii7?SP_STR_SIZE_ASCII7:0u)|(sp_str_is_binary(nm)?SP_STR_SIZE_BINARY:0u);
  o->h.len=(uint32_t)n;o->h.hash=0;
  o->m=0xfb;memcpy(o->d,nm,n);o->d[n]=0;
  SP_HEAP_LOCK();
  if(id>=sp_sym_chilled_cap){
    sp_int nc=sp_sym_chilled_cap?sp_sym_chilled_cap:64;
    while(nc<=id)nc*=2;
    const char**nt=(const char**)realloc((void*)sp_sym_chilled_tab,(size_t)nc*sizeof(const char*));
    if(nt){
      memset((void*)(nt+sp_sym_chilled_cap),0,(size_t)(nc-sp_sym_chilled_cap)*sizeof(const char*));
      sp_sym_chilled_tab=nt;sp_sym_chilled_cap=nc;
    }
  }
  const char*r=o->d;
  if(id<sp_sym_chilled_cap){
    if(sp_sym_chilled_tab[id]){free(o);r=sp_sym_chilled_tab[id];}   /* another thread won */
    else sp_sym_chilled_tab[id]=r;
  }
  SP_HEAP_UNLOCK();
  return r;
}

/* String#tr / #tr_s with a source set that may name a character twice. CRuby
   fills its table left to right, so such a character takes its LAST position
   (`"hello".tr("ll", "xy")` is "heyyo"); sp_str_tr stops at the first.
   Codegen calls sp_str_tr itself for a literal set, which it reads at
   compile time (str_tr_sets), and these for a set the program computes. They
   are here and not in sp_str.c, which sits at gcc's inline limit. */
typedef struct{uint32_t lo,hi;}sp_str_tr_run;
/* mark a member in a bitmap; was it marked already? */
static int sp_str_tr_mark(unsigned char*bits,uint32_t ch){int was=bits[ch>>3]>>(ch&7)&1;bits[ch>>3]|=(unsigned char)(1<<(ch&7));return was;}
/* Do two of the runs share a member? Pair by pair up to 16 of them, in a
   bitmap over their span past that. */
static int sp_str_tr_runs_overlap(const sp_str_tr_run*run,size_t k){
  size_t i,j;int rep=0;
  if(k<=16){for(i=0;i<k;i++)for(j=i+1;j<k;j++)if(run[i].lo<=run[j].hi&&run[j].lo<=run[i].hi)return 1;return 0;}
  uint32_t lo=run[0].lo,hi=run[0].hi;
  for(i=1;i<k;i++){if(run[i].lo<lo)lo=run[i].lo;if(run[i].hi>hi)hi=run[i].hi;}
  unsigned char*bits=(unsigned char*)calloc((hi-lo)/8+1,1);
  for(i=0;i<k&&!rep;i++)for(uint32_t ch=run[i].lo;ch<=run[i].hi;ch++)if(sp_str_tr_mark(bits,ch-lo)){rep=1;break;}
  free(bits);
  return rep;
}
/* Does the set name a character twice? It is read once, in place, as
   sp_utf8_decode_charset_n reads it (a backslash escapes, `a-c` is a range):
   no when its runs ascend, and told by a table when its members are all
   ASCII. When neither, the runs kept on the way are compared, so a set with
   no repeat is never searched member against member. A negated set is a
   membership test, where a repeat changes nothing. A descending range is a
   yes: sp_str_tr raises on it. */
static int sp_str_tr_set_repeats(const char*f){
  if(!f||(f[0]=='^'&&f[1]))return 0;
  const char*p=f,*end=f+sp_str_byte_len(f);
  char seen[128]={0};int asc=1,ascii=1,has_prev=0,rep=0;uint32_t prev=0;int64_t last=-1;
  sp_str_tr_run few[16],*run=few;size_t k=0;
  while(p<end){
    uint32_t lo,hi;int range=0;
    p+=sp_utf8_decode(p,&lo);
    if(lo=='\\'&&p<end)p+=sp_utf8_decode(p,&lo);
    else if(lo=='-'&&has_prev&&p<end)range=1;
    hi=lo;
    if(range){p+=sp_utf8_decode(p,&hi);lo=prev+1;if(hi<prev){rep=1;break;}}
    if(lo<=hi){
      if((int64_t)lo<=last)asc=0;
      last=hi;
      if(hi>=0x80)ascii=0;
      else for(uint32_t ch=lo;ch<=hi;ch++){if(seen[ch]){rep=1;goto told;}seen[ch]=1;}
      if(k==16&&run==few){run=(sp_str_tr_run*)malloc(sizeof(sp_str_tr_run)*(size_t)(end-f));memcpy(run,few,sizeof few);}
      run[k].lo=lo;run[k].hi=hi;k++;
    }
    prev=hi;has_prev=!range;
  }
  if(!asc&&!ascii)rep=sp_str_tr_runs_overlap(run,k);
told:
  if(run!=few)free(run);
  return rep;
}
/* Rewrite the two sets with the earlier positions of a repeated character
   dropped, each member escaped and beside its own replacement: what
   sp_str_tr reads from those is CRuby's table. The earlier positions are
   the members a walk from the end finds marked. */
static void sp_str_tr_last_wins(const char**from,const char**to){
  size_t fn,tn,a=0,b=0,j;
  uint32_t*fc=sp_utf8_decode_charset_n(*from,sp_str_byte_len(*from),&fn);
  uint32_t*tc=sp_utf8_decode_charset_n(*to,sp_str_byte_len(*to),&tn);
  uint32_t lo=UINT32_MAX,hi=0;
  for(j=0;j<fn;j++){if(fc[j]<lo)lo=fc[j];if(fc[j]>hi)hi=fc[j];}
  unsigned char*bits=(unsigned char*)calloc(fn?(hi-lo)/8+1:1,1);
  char*nf=(char*)malloc(fn*5+1),*nt=(char*)malloc(fn*5+1);
  for(j=fn;j-->0;)if(sp_str_tr_mark(bits,fc[j]-lo))fc[j]=UINT32_MAX;
  for(j=0;j<fn;j++){
    if(fc[j]==UINT32_MAX)continue;
    nf[a++]='\\';a+=sp_utf8_encode(fc[j],nf+a);
    if(tn){nt[b++]='\\';b+=sp_utf8_encode(tc[j<tn?j:tn-1],nt+b);}
  }
  nf[a]=0;nt[b]=0;
  char*r=sp_str_alloc(a);memcpy(r,nf,a+1);*from=r;
  r=sp_str_alloc(b);memcpy(r,nt,b+1);*to=r;
  free(nf);free(nt);free(bits);free(fc);free(tc);
}
/* tr! / tr_s! answer the receiver once one of its characters is in the set,
   also when the text comes out the same (`"hello".tr!("hh", "Hh")`, where
   sp_str_tr's first match changed it): the rewritten call says so here. */
SP_TLS int sp_str_tr_matched=0;
static const char*sp_str_tr_rewritten(const char*s,const char*from,const char*to,int squeeze){
  const char*set=from,*r=NULL;
  SP_GC_ROOT_STR(s);SP_GC_ROOT_STR(from);SP_GC_ROOT_STR(to);SP_GC_ROOT_STR(set);SP_GC_ROOT_STR(r);
  sp_str_tr_last_wins(&from,&to);
  r=squeeze?sp_str_tr_s(s,from,to):sp_str_tr(s,from,to);
  sp_str_tr_matched=sp_str_eq(r,s)&&sp_str_count(s,set)>0;
  return r;
}
const char*sp_str_tr_any(const char*s,const char*from,const char*to){sp_str_tr_matched=0;if(!s||!to||!sp_str_tr_set_repeats(from))return sp_str_tr(s,from,to);return sp_str_tr_rewritten(s,from,to,0);}
const char*sp_str_tr_s_any(const char*s,const char*from,const char*to){sp_str_tr_matched=0;if(!s||!to||!sp_str_tr_set_repeats(from))return sp_str_tr_s(s,from,to);return sp_str_tr_rewritten(s,from,to,1);}
