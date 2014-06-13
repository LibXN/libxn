
static uint32_t
  get_record_offset (uint32_t cp);
  
int ucd_get_record_string(
  size_t len,
  const codepoint_t cps[],
  ucd_record ucd[])
{
  size_t i;
  
  for (i = 0; i < len; i++)
    if (!ucd_get_record(cps[i],&ucd[i]))
      return 0;
  return 1;
}

/* load UCD record data from the compiled Unicode Database. */
int
  ucd_get_record
  (uint32_t cp, ucd_record *r)
{
  uint32_t rec_offset;
  uint16_t record;
  const uint16_t *rec_ptr;
  uint8_t flags, name_l, decomp_l, uts46_mapping_l, i;
  char *np;
  
  r->cp = cp;
  if (!(rec_offset = get_record_offset(cp)))
    return(0);

  /* offset starts with 1 */
  rec_ptr = &records[--rec_offset];

  record = records[rec_offset++];
  record = *rec_ptr++;

  /* flags + gc */
  flags = (uint8_t)(record & 0xFF);
  r->general_category = (enum UCD_GENERAL_CATEGORY)((record >> 8) & 0xFF);
  
  r->propflags = (enum UCD_PROP_FLAG)flags;
  r->bidi_mirrored = (flags & (/*=== FLAG_BIDI_MIRRORED ===*/)) ? 1 : 0;

  /* script + bidi_class */
  record = *rec_ptr++;
  r->script = (enum UCD_SCRIPT)(record & 0xFF);
  r->bidi_class = (enum UCD_BIDI_CLASS)((record >> 8) & 0xFF);

  /* ccc + dt  */
  record = *rec_ptr++;
  r->ccc = (uint8_t)(record & 0xFF);
  r->dt = (enum UCD_DECOMPOSITION_TYPE)((record >> 8) & 0xFF);

  /* nfqc + (decomposition length) */
  record = *rec_ptr++;
  r->nfqc = (enum UCNF_Quick_Check_value)(record & 0xFF);
  decomp_l = (uint8_t)((record >> 8) & 0xFF);

  /* decomposition mapping sequence */
  for (i = 0; i < decomp_l; i++, rec_ptr++)
    utf16_decode(&rec_ptr, &r->decomp[i]);
  r->decomp[decomp_l] = 0;

  /* (joining_type) + (rfc5892 prop.) */
  record = *rec_ptr++;
  r->joining_type = (enum UCD_JOINING_TYPE)(record & 0xFF);
  r->rfc5892 = (enum RFC5892_Property)((record >> 8) & 0xFF);

  /* (uts46_status) + (uts46_mapping length) */
  record = *rec_ptr++;
  r->uts46_status = (enum UTS46_STATUS)(record & 0xFF);
  uts46_mapping_l = (uint8_t)((record >> 8) & 0xFF);

  /* uts46_mapping */
  if (flags & /*=== UTS46MAP_EQUALS_DECOMPMAP ===*/)
  {  /* uts46_mapping equals decomposition mapping */
    memcpy(&r->uts46_mapping,&r->decomp,(1+decomp_l)*sizeof(codepoint_t));
//     for (i = 0; i < decomp_l; i++)
//       r->uts46_mapping[i] = r->decomp[i];
//     r->uts46_mapping[decomp_l] = 0;
  }
  else
  {
    for (i = 0; i < uts46_mapping_l; i++, rec_ptr++)
      utf16_decode(&rec_ptr, &r->uts46_mapping[i]);
    r->uts46_mapping[uts46_mapping_l] = 0;
  }

  /* (name word count) + (rfc5892 prop.) */
  record = *rec_ptr++;
  name_l = (uint8_t)(record & 0xFF);
  //r->rfc5892 = (enum RFC5892_Property)((record >> 8) & 0xFF);

  /* words of name */
  for (i=0, np = r->name; i < name_l; i++)
  {
    const char *wp;
    record = *rec_ptr++;
    for (wp = words[record]; *wp; *np++ = *wp++ );
    if (i < name_l-1)
      *np++ = ' ';
  }
  *np = '\0';

//
//   /* uppercase */
//   if (flags & (/*=== HAVE_UPPERCASE ===*/))
//   {
//     utf16_decode(&rec_ptr, &r->uppercase);
//     rec_ptr++;
//   }
//   else
//     r->uppercase = 0;
//
//   /* lowercase */
//   if (flags & (/*=== HAVE_LOWERCASE ===*/))
//   {
//     utf16_decode(&rec_ptr, &r->lowercase);
//     rec_ptr++;
//   }
//   else
//     r->lowercase = 0;
//
  r->uppercase = 0;   // to be removed
  r->lowercase = 0;

  return(1);
}



uint32_t
  get_record_offset (uint32_t cp)
{

/* record accessor */
/*=== RECORD_ACCESSOR ===*/

  return(0);
}

