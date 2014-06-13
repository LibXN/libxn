## Unicode Character Database Version
##
## @read: "Readme.txt"
## @write: "ucd.c"
our ($UCD_C);
package main;
use strict;
{

  # parse Unicode Version from Readme.txt
  my ($version, $date);
  
  my $re_version = qr/Unicode\s+(\d+\.\d+\.\d+)/;

  my $src = require_source(q/Readme/);
  open my $src_h, '<', $src or die $!;
  my ($lno);
  for ($lno = 1; <$src_h>; $lno++) {
    chomp;
    m/$re_version/ or next;
    $version = $1;
  }
  
  $version or die "Unicode Version was not found";

  LOG __FILE__, "Unicode Version: $version";

  print $UCD_C '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_C <<HERE;
/* Unicode Version
  The version string is taken from
    http://www.unicode.org/Public/UNIDATA/ReadMe.txt
  while generating the compiled database. */
const char *ucd_version(void)
{
  return "$version";
}

HERE
  
  

}

1;
