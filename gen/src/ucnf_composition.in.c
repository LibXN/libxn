
/*
static const uint16_t comp_map [2350];
static const uint16_t comp_hash [8941];
*/

#define comp_hash_length (sizeof(comp_hash)/sizeof(uint16_t))

bool_t
ucnf_canonical_composition
  (codepoint_t first, codepoint_t second, codepoint_t *composite)
{
  size_t pos;
  codepoint_t h = first ^ second; /* hash value */
  
  if (h < comp_hash_length && (0 != (pos = (size_t)comp_hash[h])))
  {
    /* comp_map contains a 0-terminated sequence of pairs: (first,result)
    (Another composing pair having first cannot have the same hash value,
    so the second part is omitted.) */
    const uint16_t *p;
    for (p = (uint16_t *)comp_map + (pos-1); *p; p++)
    {
      codepoint_t f,r;
      utf16_decode(&p,&f), p++;
      utf16_decode(&p,&r);
      if (f == first)
      {
        *composite = r;
        return 1;
      }
    }
  }

  return 0;
}

