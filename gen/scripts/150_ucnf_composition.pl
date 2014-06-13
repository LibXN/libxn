##
## apply the Full_Composition_Exclusion property
##
## @read: "DerivedNormalizationProps.txt"
## @read: %UCD_records
## @write: "ucnf_composition.c"
our (
  %UCD_records, @UCD_records, %UCD_record_flags);
our (%UCD_canonical_comp);
our ($RE_codepoint_interval);
package main;
use strict;
{

  # Full_Composition_Exclusion

  ## e.g:
  ## 0958..095F    ; Full_Composition_Exclusion # Lo   [8] DEVANAGARI LETTER QA..DEVANAGARI LETTER YYA
  my $re_exclusion_interval = qr/^
    $RE_codepoint_interval
    \s+
    ;\s+Full_Composition_Exclusion
  /x;
  
  ## read Full_Composition_Exclusion property
  ## cf.: http://www.unicode.org/reports/tr15/#Primary_Exclusion_List_Table
  my $src = require_source(q/DerivedNormalizationProps/);
  my $ex = 0;
  open my $src_h, '<', $src or die $!;
  my ($lno);
  for ($lno = 1; <$src_h>; $lno++) {
    chomp;
    s/#.*//;
    /\S/ or next;
    /$re_exclusion_interval/ or next;
    my ($lo,$up) = (hex($1),(defined $2 ? hex($2) : 0));
    $up = $lo unless $up > 0;
    
    foreach ( $lo .. $up ) {
      exists $UCD_records[$_] or
        die sprintf	"cannot not apply Full_Composition_Exclusion property ".
					"to non existing code point %04X", $_;
      $UCD_records[$_]{Full_Composition_Exclusion} = 1;
      $ex++;
    }
    
  }
  close $src_h;
  LOG __FILE__, "$ex code points excluded from composition.";

  ## get decompositions
  my %composing;
  my %comp_hash;
  my $comp_map_array = idna2::codegen::array->create(
    name => q/comp_map/, type => 'uint16_t');
  my $comp_hash_array = idna2::codegen::array->create(
    name => q/comp_hash/, type => 'uint16_t');

  foreach ( keys %UCD_records ) {
    my $r = $UCD_records{$_};
    my ($lo,$up) = split /:/;
    
    $r->{dt} eq q/Can/ or next;
    0 < scalar @{$r->{dm}} or next;
    next if $r->{Full_Composition_Exclusion};
    
    # canonical decomposition
    foreach ( $lo .. $up ) {
      2 == scalar @{$r->{dm}} or
        die "canonical decomposition is not a pair";

      # canonical composition pair
      my ($fst,$snd) = @{$r->{dm}};

      my $h = $fst ^ $snd;
      die "hash value exceeds 16bit: $h" if $h > 0xFFFF;
      
      $comp_hash{$h} = [] unless exists $comp_hash{$h};
      push @{$comp_hash{$h}}, ($fst, $_);

      defined $UCD_records[$fst] or
        die "unassigned codepoint in composition: $fst";
      #$UCD_records[$fst]{flags} |= $UCD_record_flags{COMPOSING};
      $composing{$fst} = 1;

      defined $UCD_records[$snd] or
        die "unassigned codepoint in composition: $snd";
      #$UCD_records[$snd]{flags} |= $UCD_record_flags{COMPOSING};
      $composing{$snd} = 1;
      
    }
  }

  foreach ( keys %composing ) {
    defined $UCD_records[$_] or
			die sprintf "cannot set uninitialized value %04X as composing";
    $UCD_records[$_]{flags} |= $UCD_record_flags{COMPOSING};
  }

  my $composing_c = scalar keys %composing;
  LOG __FILE__, sprintf "code points marked as composing: %d.",
		$composing_c;
  
  #die if ($UCD_records[0x1E0C]{flags} & $UCD_record_flags{COMPOSING});

  ## create c arrays
  foreach my $h ( keys %comp_hash ) {
    my $p = 1 + $comp_map_array->length;
    $comp_map_array->push((map { encode_utf16($_) } @{$comp_hash{$h}}), 0);
    $comp_hash_array->set($h, $p);
  }
  
  my $fh = c_open_source(__FILE__, +GEN_PATH("ucnf_composition.c"));
  print $fh
    '#include "encoding.h"', "\n",
    '#include "ucnf_composition.h"', "\n\n";

  ## c decl
  print $fh '#line ', __LINE__,
    ' "', build_rel_path(__FILE__), '"', "\n";
  print $fh
    $comp_map_array->decl, "\n",
    $comp_hash_array->decl, "\n\n";

  ## c proc
  #my $inc = +SCRIPT_SRC_PATH ("ucnf_composition.in.c");
  c_include(__FILE__, +SCRIPT_SRC_PATH ("ucnf_composition.in.c") => $fh,
    COMP_HASH_ARRAY_LENGTH => $comp_hash_array->length);

  ## c data
  print $fh '#line ', __LINE__,
    ' "', build_rel_path(__FILE__), '"', "\n";
  print $fh $comp_hash_array->def(sub { int shift }), "\n\n";
  print $fh $comp_map_array->def, "\n\n";

  ## done with "$ucnf_composition.c"
  c_close_source($fh);
  
}

1;
