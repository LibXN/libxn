


enum UCD_PROP_FLAG
{

  /* code points appearing as part of a canonical combining pair */
  ucd_prop_COMPOSING = 1,

  /* bidi mirrored property */
  ucd_prop_BIDI_MIRRORED = 2

};


/* UCD code point property record */
typedef struct UCD_RECORD
{

  /* The actual code point value */
  uint32_t cp;

  /* boolean properties */
  enum UCD_PROP_FLAG propflags;

  /* The Unicode character name */
  char name[100];

  /* General_Category
  cf.: http://www.unicode.org/reports/tr44/#General_Category_Values */
  enum UCD_GENERAL_CATEGORY general_category;

  enum UCD_SCRIPT script;

  enum UCD_BIDI_CLASS bidi_class;
  char bidi_mirrored;

  /* Canonical Combining Class Values */
  uint8_t ccc;

  /* Compatibility Formatting Tag
  cf.: http://www.unicode.org/reports/tr44/#Character_Decomposition_Mappings */
  enum UCD_DECOMPOSITION_TYPE dt;

  /* decomposition mapping sequence */
  uint32_t decomp[UCD_DECOMPMAP_MAXL];

  enum UCD_JOINING_TYPE joining_type;

  /* normalization form Quick_Check Value:
  data from Derived Normalization Properties file [NormProps] */
  enum UCNF_Quick_Check_value nfqc;

  /* Derived properties according to RFC5892 */
  enum RFC5892_Property rfc5892;

  enum UTS46_STATUS uts46_status;

  codepoint_t uts46_mapping[1+UTS46_mapping_maxlength];

  /* uppercase is 0 unless upper case mapping is defined */
  uint32_t uppercase;

  /* lowercase is 0 unless lower case mapping is defined */
  uint32_t lowercase;

}
ucd_record;


/* == "ucd.c" == */

#ifdef __cplusplus
extern "C" {
#endif

extern int ucd_get_record (uint32_t,ucd_record*);

extern int ucd_get_record_string(size_t, const codepoint_t[], ucd_record[]);

extern const char *ucd_version(void);

#ifdef __cplusplus
}
#endif

