## read quick check values for Unicode Normalization Forms
##
## @read: %UCD_nfqc_flags
## @read: "DerivedNormalizationProps.txt"
## @write: @UCD_records
our (%UCD_records, @UCD_records);
our ($RE_codepoint_interval);
package main;
use strict;
{

  my %nfqc_flags = (
    NFD_N => 0x01,
    NFD_M => 0x02,
    NFC_N => 0x10,
    NFC_M => 0x20,
    NFKD_N => 0x04,
    NFKD_M => 0x08,
    NFKC_N => 0x40,
    NFKC_M => 0x80,
  );

  # http://www.unicode.org/reports/tr15/#Detecting_Normalization_Forms

  # "DerivedNormalizationProps.txt"

	# Property:	NFC_Quick_Check

	#  All code points not explicitly listed for NFC_Quick_Check
	#  have the value Yes (Y).

  # NFC_Quick_Check=No
  # ... NFC_QC; N ...
  # Total code points: 1118

  # NFC_Quick_Check=Maybe
  # ... NFC_QC; M ...
  # Total code points: 103
  
  # NFKD_Quick_Check=No
  # ... NFKD_QC; N ...
  # Total code points: 16731

  # NFKC_Quick_Check=No
  # ... NFKC_QC; N ...
  # Total code points: 4640

  # NFKC_Quick_Check=Maybe
  # ... NFKC_QC; M ...
  # Total code points: 103

  # 0EDC..0EDD    ; NFKC_QC; N # Lo   [2] LAO HO NO..LAO HO MO
  my $re_nfqc_interval = qr/^
    $RE_codepoint_interval
    \s+;\s*
    (NFK?[CD])_QC
    \s*;\s*
    ([YNM])
  /x;

  my $re_quick_check = qr/NFK?[CD]/;
  
  my $src = require_source(q/DerivedNormalizationProps/);
  open my $src_h, '<', $src or die $!;
  my ($lno);
  for ($lno = 1; <$src_h>; $lno++) {
    chomp;
    s/#.*//;
    /\S/ or next;
    /$re_nfqc_interval/ or next;

    my ($lo,$up,$nfqc,$value) = (hex($1),(defined $2 ? hex($2) : 0),$3,$4);
    $up = $lo unless $up > 0;
    
    my $key = $nfqc.'_'.$value;
    exists $nfqc_flags{$key} or
      die "unexpected nfqc definition in $src on line $lno";
    my $flag = $nfqc_flags{$key};

    # apply to records
    foreach ( $lo .. $up ) {
      exists $UCD_records[$_] or
        die "could not apply nfqc property to non existing code point ".
        sprintf('%04X', $_);
      exists $UCD_records[$_]{nfqc} or $UCD_records[$_]{nfqc} = 0;
      $UCD_records[$_]{nfqc} |= $flag;
    }

  }
  close $src_h;
  

  ## stats
  my %c = map { $_ => 0 } keys %nfqc_flags;
  foreach ( keys %UCD_records ) {
    my $r = $UCD_records{$_};
    my ($lo,$up) = split /:/;
    foreach my $f ( keys %nfqc_flags ) {
      $c{$f} += ($up - $lo + 1) if defined $r->{nfqc} &&
				($nfqc_flags{$f} & $r->{nfqc});
    }
  }
  foreach ( keys %c ) {
    LOG __FILE__, "nfqc applied: $_ ($c{$_})";
  }

#   # finish "ucd_nfqc.h"
#   print $fh $enum->c_decl, "\n\n";
#   print $fh $enum->cpp_decl, "\n\n";
#   c_close_header($fh,$path);
#

}

1;
