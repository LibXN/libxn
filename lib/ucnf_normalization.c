#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef WIN32
#include "config.win32.h"
#endif

#include <stdint.h>  /* uint8_t */
#include <string.h> /* memcpy, memmove */

#include "xn.h"
#include "ucnf_composition.h"
#include "ucnf_normalization.h"


#define nfqc_quickcheck_getvalue(value,nf) \
  ((ucnf_quickcheck_result)((value) >> (2*(nf))) & 3)

static bool_t
__normalization_equals
  (const ucd_record[], size_t, ucnf_form);

static ucnf_normalization_result
__decompose
  (ucd_record[], size_t *, size_t, ucnf_form);

static bool_t
__get_decomposition
  (const ucd_record *ucd, ucd_record **map, int nf_canonical);

static ucnf_normalization_result
__compose
  (ucd_record ucd[], size_t *ucd_l);

static bool_t
__compose_pairwise
  (const ucd_record *first, const ucd_record *second, codepoint_t *composite);

/*
  special case: Hangul
  Section 3.12, Combining Jamo Behavior,
  http://unicode.org/reports/tr15/#Hangul
  
  AC00;<Hangul Syllable, First>;Lo;0;L;;;;;N;;;;;
  D7A3;<Hangul Syllable, Last>;Lo;0;L;;;;;N;;;;;    */
static const codepoint_t hangul_SBase = 0xAC00;
static const codepoint_t hangul_LBase = 0x1100;
static const codepoint_t hangul_VBase = 0x1161;
static const codepoint_t hangul_TBase = 0x11A7;
static const uint16_t hangul_LCount = 19;
static const uint16_t hangul_VCount = 21;
static const uint16_t hangul_TCount = 28;
static const uint16_t hangul_NCount = 588; /* hangul_VCount * hangul_TCount */
static const uint16_t hangul_SCount = 11172; /* hangul_LCount * hangul_NCount */

/* hangul_SBase = AC00
   hangul_SBase + hangul_SCount = D7A4 */
#define is_hangul_syllable(cp) \
  ((hangul_SBase <= cp) && (cp < hangul_SBase + hangul_SCount))

#define is_hangul_L(cp) \
  ((hangul_LBase <= cp) && (cp < hangul_LBase + hangul_LCount))

#define is_hangul_T(cp) \
  ((hangul_TBase <= cp) && (cp < hangul_TBase + hangul_TCount))

#define is_hangul_V(cp) \
  ((hangul_VBase <= cp) && (cp < hangul_VBase + hangul_VCount))

static bool_t
__get_hangul_decomposition
  (const ucd_record *ucd, ucd_record **map);

static bool_t
__hangul_compose
  (codepoint_t starter,codepoint_t current,codepoint_t *composite);


bool_t
ucnf_is_normalized
  (const ucd_record ucd[], size_t ucd_l, ucnf_form nf)
{
  ucnf_quickcheck_result qc;

  qc = ucnf_quickcheck(ucd,ucd_l,nf);
  switch (qc)
  {
    /* nf_quick_check_Yes means the string is normalized */
    case nf_quick_check_Yes:
      return 1;
      
    case nf_quick_check_No:
      return 0;
      
    default: /* nf_quick_check_Maybe */
      return __normalization_equals(ucd,ucd_l,nf);
  }
}

/*
  Unicode normalization form quick check
  see: http://www.unicode.org/reports/tr15/#Detecting_Normalization_Forms */
ucnf_quickcheck_result
ucnf_quickcheck
  (const ucd_record ucd[], size_t ucd_l, ucnf_form nf)
{
  size_t i;
  uint8_t last_ccc = 0;
  ucnf_quickcheck_result result = nf_quick_check_Yes;
  
  for (i = 0; i < ucd_l; i++)
  {
    ucnf_quickcheck_result check;
    
    if (ucd[i].ccc != 0 && (last_ccc > ucd[i].ccc))
      return nf_quick_check_No;
      
    if (nf_quick_check_No == (
        check = nfqc_quickcheck_getvalue(ucd[i].nfqc,nf)))
      return nf_quick_check_No;

    if (check == nf_quick_check_Maybe)
      result = nf_quick_check_Maybe;
    last_ccc = ucd[i].ccc;
  }

  return result;
}

ucnf_normalization_result
ucnf_normalize
  (ucd_record ucd[], size_t *ucd_l, size_t maxl, ucnf_form nf)
{
  if (nf_quick_check_Yes != ucnf_quickcheck(ucd,*ucd_l,nf))
    return ucnf_apply_normalization (ucd, ucd_l, maxl, nf);
  return ucnf_OK;
}


/*
  Unicode Normalization
  cf.: http://unicode.org/reports/tr15/#Description_Norm */
ucnf_normalization_result
ucnf_apply_normalization
  (ucd_record ucd[], size_t *ucd_l, size_t maxl, ucnf_form nf)
{
  ucnf_normalization_result res;
  
  /* To transform a Unicode string into a given Unicode Normalization Form,
    the first step is to fully decompose the string. */
  if (ucnf_OK != (res = __decompose(ucd,ucd_l,maxl,nf)))
    return res;
    
  /* At this point, if one is transforming a Unicode string to NFD or NFKD,
    the process is complete. However, one additional step is needed to
    transform the string to NFC or NFKC: recomposition. */
  if (0 != (nf & nf_mask_composition))
  {
    if (ucnf_OK != (res = __compose(ucd,ucd_l)))
      return res;
  }

  return ucnf_OK;
}


/* ==== static ==== */

/* compare an input string with it's normalization */
bool_t __normalization_equals
  (const ucd_record ucd[], size_t ucd_l, ucnf_form nf)
{
  ucd_record tmp[XN_BUFSZ];
  size_t tmp_l = ucd_l,i;

  memcpy(tmp,ucd,ucd_l*sizeof(ucd_record));
  if (ucnf_OK != ucnf_apply_normalization(tmp,&tmp_l,XN_BUFSZ,nf))
  {  /* An error occured during normalization */
    return 0;
  }

  if (ucd_l != tmp_l)
    return 0;
  for (i = 0; i < ucd_l; i++)
    if (ucd[i].cp != tmp[i].cp)
      return 0;

  return 1;
}


/*
  Canonical or compatibility decomposition, applying Canonical Ordering Algorithm.
  Adapted from:
    http://www.unicode.org/reports/tr15/Normalizer.java */
ucnf_normalization_result
__decompose
  (ucd_record ucd[], size_t *ucd_l, size_t maxl, ucnf_form nf)
{
  size_t i = 0, total = *ucd_l;
  int nf_canonical = (0 == (nf & nf_mask_compatibility));
  ucd_record map[256];

  while (i < total)
  {
    size_t map_l, j;
    ucd_record *map_p = map;

    /* get decomposition characters */
    if (__get_decomposition(ucd+i,&map_p, nf_canonical))
      map_l = (size_t)(map_p - map), map_p = map;
    else
      map_l = 1, map_p = ucd + i;
    
    /* check length */
    if (total + map_l > maxl)
      return ucnf_Buffer_Exceeded;

    if (map_l > 1 && i < total - 1) 
    {  /* right-shift remaining part by map_l - 1 */
      memmove(ucd+(map_l+i),ucd+(i+1),(total-i-1)*sizeof(ucd_record));
    }

    /* insert decomposition characters */
    for (j = 0; j < map_l; j++, i++)
    {
      size_t k = i;
      ucd_record t, *m = map_p++;

      /* find insertion point with respect to canonical ordering */
      if (m->ccc > 0) /* non-starter */
      {
        for ( ; k > 0 && m->ccc < ucd[k-1].ccc; k--);
        if (k < i)
        {
          if (m == (ucd+i)) /* remember before overwrite */
            m = (ucd_record*)memcpy(&t,ucd+i,sizeof(ucd_record));

          /* right-shift above insertion point */
          memmove(ucd+(k+1),ucd+k,(i-k)*sizeof(ucd_record));
        }
      }

      if (m->cp != ucd[k].cp) /* insert */
      {
        memcpy(ucd+k, m, sizeof(ucd_record));
      }

      if (j > 0) /* increase total length */
        total++;
    }
  } /* while (i < total) */

  *ucd_l = total;
  return ucnf_OK;
}

/*
  Get decomposition mapping recursively.
  Adapted from:
    getRecursiveDecomposition,
    http://www.unicode.org/reports/tr15/NormalizerData.java */
bool_t
__get_decomposition
  (const ucd_record *ucd, ucd_record **map, int nf_canonical)
{
  /* returns:
   1 - when a decomposition mapping was found;
   0 - otherwise (map is unchanged) */

  /* special case: Hangul canonical decomposition */
  if (is_hangul_syllable(ucd->cp))
    return __get_hangul_decomposition(ucd,map);

  /* get decomposition mapping recursively */
  if (ucd->decomp[0] && !(nf_canonical && (ucd->dt != ucd_dt_Canonical)))
  {
    codepoint_t *u;
    ucd_record *p = *map;

    for (u = (codepoint_t*)ucd->decomp; *u; u++)
    {
      ucd_record r;
      if (!ucd_get_record(*u,&r))
        return -1; /* inconsistent data */

      if (!__get_decomposition(&r, &p, nf_canonical))
        memcpy(p++,&r,sizeof(ucd_record));
    }
    *map = p;
    return 1; /* mapping found */
  }

  return 0; /* no mapping */
}

/* Canonical Composition Algorithm. */
ucnf_normalization_result
__compose
  (ucd_record ucd[], size_t *ucd_l)
{
  ucd_record rec, *starter = (ucd_record *)ucd;
  uint8_t last_ccc = starter->ccc;
  size_t total = *ucd_l, oldl = *ucd_l, starter_pos = 0, comp_pos = 1, decomp_pos;

  if (last_ccc != 0)
    last_ccc = 255; /* fix for strings starting with a combining mark */

  for (decomp_pos = comp_pos; decomp_pos < total; decomp_pos++)
  {
    ucd_record *current = (ucd_record*)ucd + decomp_pos;
    uint8_t ccc = current->ccc;

    if (last_ccc == 0 || last_ccc < ccc)
    {
      codepoint_t composite;
      if (__compose_pairwise(starter,current,&composite))
      {
        if (!ucd_get_record(composite,&rec))
          return ucnf_Unexpeted;

        /* insert composition */
        memcpy(ucd+starter_pos,&rec,sizeof(ucd_record)),
          starter = &rec;
        continue;
      }
    }

    if (ccc == 0)
      starter_pos = comp_pos, starter = current;
    last_ccc = ccc;

    if (total != oldl)
      decomp_pos += (total - oldl), oldl = total;

    if (ucd[comp_pos].cp != current->cp)
    {
      memcpy(ucd+comp_pos,current,sizeof(ucd_record));
    }
    comp_pos++;
  }

  *ucd_l = comp_pos;
  return ucnf_OK;
}

bool_t
__compose_pairwise
  (const ucd_record *first, const ucd_record *second, codepoint_t *composite)
{

  /* for efficienty, we have marked all composing characters before
  (except Hangul) */
  if (0 != (ucd_prop_COMPOSING & (first->propflags & second->propflags)))
  {
    /* hash table look up */
    if (ucnf_canonical_composition(first->cp,second->cp,composite))
      return 1;
  }

  /* try to apply algorithmic specified Hangul composition */
  return __hangul_compose(first->cp,second->cp,composite);
}



/* -- Hangul algorithms -- */

/*
  Arithmetically specified Hangul Syllable canonical decomposition.
  Decompose precomposed Hangul syllable characters into two or
  three Hangul Jamo characters.

  applies to code points U+AC00 .. U+D7A4 only.

  All LVT syllables decompose into an LV syllable plus a T jamo.
  The LV syllables themselves decompose into an L jamo plus a V jamo.
  cf.: http://unicode.org/reports/tr15/#Hangul */
bool_t
__get_hangul_decomposition
  (const ucd_record *ucd, ucd_record **map)
{
  codepoint_t sindex,l,v,t;
  ucd_record *map_p = *map;

  sindex = ucd->cp - hangul_SBase;
  l = hangul_LBase + sindex / hangul_NCount;
  v = hangul_VBase + (sindex % hangul_NCount) / hangul_TCount;
  t = hangul_TBase + sindex % hangul_TCount;
  
  if (!ucd_get_record(l,map_p++))
    return -1;
  if (!ucd_get_record(v,map_p++))
    return -1;
  if (t != hangul_TBase)
  {
    if (!ucd_get_record(t,map_p++))
      return -1;
  }

  *map = map_p;
  return 1;
}

/* Hangul Composition
  cf.: http://unicode.org/reports/tr15/#Hangul */
bool_t
__hangul_compose
  (codepoint_t first,codepoint_t second,codepoint_t *composite)
{

  /* 1. check to see if two second characters are L and V */
  if (is_hangul_V(second) && is_hangul_L(first))
  {
    codepoint_t v = (second - hangul_VBase),
      l = (first - hangul_LBase);
      
    /* make syllable of form LV */
    *composite = hangul_SBase + (l * hangul_VCount + v) * hangul_TCount;
    return 1;
  }
  
  /* 2. check to see if two second characters are LV and T */
  if (is_hangul_syllable(first) &&
    0 == ((first - hangul_SBase) % hangul_TCount))
  {
    codepoint_t t = (second - hangul_TBase);
    if (0 < t && t < hangul_TCount)
    {
      /* make syllable of form LVT */
      *composite = first + t;
      return 1;
    }

  }

  return 0;
}


