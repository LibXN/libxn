our (
  $UCD_intervals,
  %UCD_records, @UCD_records,

  %UCD_GC,
  %UCD_BC,
  %UCD_DT, %UCD_DT_tags,

  
);
our (
	$RE_codepoint, $RE_cpname,
	%UCD_record_flags,
);
package main;
use strict;
{

## read UnicodeData.txt
## see "UnicodeData File Format, Version 3.0.1",
## http://www.unicode.org/reports/tr44/#UnicodeData.txt
LOG __FILE__, "processing UnicodeData.txt ...";
$UCD_intervals = idna2::codegen::interval->create;
my $d = 0;
{

  ## http://www.unicode.org/reports/tr44/#Character_Decomposition_Mappings
  my $re_decomposition = qr/^
      (?:(<[a-zA-Z]+>)\s+)?
      ((?:$RE_codepoint\s*)+)
    $/x;

  my $path = require_source(q/UnicodeData/);
  open my $fh, '<', $path or die $!;
  my ($lno,$range);
  for ($lno = 1; <$fh>; $lno++) {
    chomp;
    my (
      $value,      ## Code value
      $name,       ## Character name
      $gc,         ## General Category
      $ccc,        ## Canonical Combining Class
      $bidi,       ## Bidirectional Category
      $decomp,     ## Character Decomposition Mapping
      $decdigv,    ## Decimal digit value
      $digv,       ## Digit value
      $numv,       ## Numeric value
      $bidi_m,     ## Bidi_Mirrored
      $name2,      ## Unicode 1.0 Name
      undef,       ## 10646 comment field
      $uc_map,     ## Uppercase Mapping
      $lc_map,     ##	Lowercase Mapping
      $tc_map      ## Titlecase Mapping
      ) = split /;/;

    my $cp = hex($value);

    # check for character range
    if ( $name =~ /^<(.+),\s*First>$/ ) { # range begins
      $range = [$cp => $1];
      next;
    }
    my ($cp_lo,$cp_up);
    if ( defined $range ) { # range completed
      my ($cp1,$n) = @$range;
      ( $name =~ /^<(.+),\s*Last>$/ && ($1 eq $n) ) or
        die "end of range missing for '$n'";;
      ($name,$cp_lo,$cp_up) = ($1,$cp1,$cp);
      undef $range;
    } else {
      $cp_lo = $cp_up = $cp;
    }
    #$UCD_intervals->push([$cp_lo,$cp_up]);

    my $flags = 0;

    # (1) Name
    $name =~ /$RE_cpname/ or
      die "unexpected name '$name'";
    # to save storage, cut off code point suffix
    $flags |= $UCD_record_flags{NAME_HEX_SUFFIX}
      if $name =~ s/-$value$//;

    # (2) General_Category (gc)
    exists $UCD_GC{$gc} or
      die "unknown General_Category '$gc' (field 2)";

    # (3) Canonical_Combining_Class (ccc)
    if ($ccc =~ /\S/) {
      ($ccc =~ /^\d+$/ && (0 <= $ccc && $ccc < 0x100)) or
        die "Canonical_Combining_Class '$ccc' not understood (field 3)";
    }

    ## (4) Bidi_Class
    exists $UCD_BC{$bidi} or
      die "unexpected Bidi_Class '$bidi' (field 4)";

    ## (5) Decomposition_Type, Decomposition_Mapping
    my ($dm,$dt);
    if ( $decomp =~ /\S/ ) {
      if ( $decomp =~ /$re_decomposition/ ) {
        my ($tag,$seq) = ($1,$2);
        my @seq = map(hex, split /\s+/, $seq);
        $dm = \@seq;
        if ($tag) {
          # get decomposition type from compatibility formatting tag
          exists $UCD_DT_tags{$tag} or
            die "unexpected compatibility decomposition tag '$tag' (field 5)";
          $dt = $UCD_DT_tags{$tag};
        } else {
          # canonical mapping
          die "canonical decompositions must be singles or pairs"
            if ($#seq > 1);
          exists $UCD_DT{Can} or
            die "missing required decomposition type (Canonical)";
          $dt = q/Can/;
        }
      } else {
        die "Character Decomposition Mapping (field 5) not understood";
      }
    }
    else {
      exists $UCD_DT{None} or
        die "missing required decomposition type (None)";
      $dt = q/None/; # default
    }

    # (12) Simple_Uppercase_Mapping
    my ($ucase);
#     if ( $uc_map =~ /\S/ ) {
#       $flags |= $UCD_record_flags{HAVE_UPPERCASE};
#       $ucase = hex($uc_map);
#     }

    # (13) Simple_Lowercase_Mapping
    my ($locase);
#     if ( $lc_map =~ /\S/ ) {
#       $flags |= $UCD_record_flags{HAVE_LOWERCASE};
#       $locase = hex($lc_map);
#     }

    # (9) Bidi_Mirrored
    $flags |= $UCD_record_flags{BIDI_MIRRORED}
      if q|Y| eq $bidi_m; # Y/N

    # (10) Unicode_1_Name
    # Unicode 1.0 name for <control> (0000..001F, 007F..009F)
    if ( $name eq q|<control>| && $name2 =~ /\S/ ) {
      $name .= " ($name2)";
    }

    my $rkey = iv_key([$cp_lo,$cp_up]);
    my $r = {
      lower => $cp_lo,
      upper => $cp_up,
      info => cp_range($cp_lo,$cp_up),
      name => $name,
      flags => $flags,
      gc => $gc,
      ccc => $ccc,
      bc => $bidi,
      bm => (q|Y| eq $bidi_m ? 1 : 0),
      dt => $dt,
      dm => $dm,
      upper_case => $ucase,
      lower_case => $locase,
      block => 0,
      script => q/Unknown/,
      nfqc => 0,
    };

#    $UCD_records{$rkey} = $r;
    foreach ( $cp_lo .. $cp_up ) {
       my $rk = iv_key([$_,$_]);
       my %r = %$r;
       $r{lower} = $r{upper} = $_;
       my $rr = \%r;
       $UCD_records{$rk} = $rr;
       $UCD_records[$_] = $rr;
       $UCD_intervals->push([$_,$_]);

      #$UCD_records[$_] = $r;


    }
  }
  close $fh;
  LOG __FILE__, "$lno lines read.";
}


LOG __FILE__, "intervals found:", (scalar @{$UCD_intervals});
LOG __FILE__, "code points assigned:", $UCD_intervals->assigned;
LOG __FILE__, "highest code point:", (sprintf 'U+%04X', $UCD_intervals->upper_bound);
LOG __FILE__, "records:", (scalar keys %UCD_records);
LOG __FILE__, "done: UnicodeData.txt";
LOG __FILE__,;

{
  # stats
  my $total = (scalar keys %UCD_records);
  my $ccc_c = 0;
  my $bidi_c = 0;
  my $dt_c = 0;
  my $can_c = 0;
  foreach ( keys %UCD_records ) {
    my $r = $UCD_records{$_};
    $ccc_c++ if $r->{ccc} == 0;
    $bidi_c++ if $r->{bc} eq 'L';
    $dt_c++ if $r->{dt} eq 'None';
    $can_c++ if $r->{dt} eq 'Can';

  }
  LOG __FILE__, int($ccc_c/$total * 100)."% ($ccc_c records) have ccc = 0";
  LOG __FILE__, int($dt_c/$total * 100)."% ($dt_c records) have dt = None";
  LOG __FILE__, int($can_c/$total * 100)."% ($can_c records) have dt = Can";
  LOG __FILE__, int($bidi_c/$total * 100)."% ($bidi_c records) have bc = L";
}



}
1;