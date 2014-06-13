##
## update UCD records with the joining type (Arabic and Syriac positional shaping)
##
## @read: "Joining_Type.txt"
## @read: "ArabicShaping.txt"
## @write: "ucd_joining.h"
## @update: @UCD_records
our ($UCD_H, %UCD_records, @UCD_records);
our ($RE_codepoint);
package main;
use strict;
{

  my $add_enum_value = sub {
    my $enum = shift;
    my ($name,$value,$help) = @_;
    $enum->push({
      c_name => "ucd_joining_$name",
      cpp_name => $name,
      help => [$help],
      value => $value });
  };

  #my $path = +GEN_PATH("ucd_joining.h");
  #my $fh = c_open_header($path, +BUILD_PATH("ucd_joining.h"));
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H <<HERE;
/**
 * Shaping classes for Arabic and Syriac positional shaping.
 * see: http://unicode.org/Public/UNIDATA/ArabicShaping.txt
 *
 */
HERE

  ## enum Joining_Type
  my $enum = Idna2::Code::enum->create(
    c_name => "UCD_JOINING_TYPE", cpp_name => "JoiningType",
    help => "Shaping classes for Arabic and Syriac positional shaping."
    );

  # null type
  &$add_enum_value($enum, q/Undefined/, 0);

  my %joining_type;

  my $re_value = qr/[A-Z]/;

  ## read Joining_Type.txt
  read_table(q[Joining_Type],sub {
    # R;right-joining
    my ($value,$desc) = @_;
    $value =~ /^$value$/ or return undef;
    my $n = 1 + scalar keys %joining_type;
    $joining_type{$value} = $n;
    &$add_enum_value($enum, to_variable($value), $n, $desc);
    #LOG __FILE__, "joining type: $value = $n";
    1;
  });

  # finish "ucd_joining.h"
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H $enum->c_decl, "\n\n";

  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H $enum->cpp_decl, "\n\n";
  #c_close_header($fh,$path);

  ## read values from ArabicShaping.txt
  # 0600; ARABIC NUMBER SIGN; U; <no shaping>
  my $re_joining_def = qr/^
    ($RE_codepoint)
    \s*;[^;]+;\s*
    ($re_value)
  /x;

  my %applied;

  my $src = require_source(q/ArabicShaping/);
  open my $src_h, '<', $src or die $!;
  my ($lno);
  for ($lno = 1; <$src_h>; $lno++) {
    chomp;
    
    /$re_joining_def/ or next;
    my ($cp,$value) = (hex($1),$2);
    
    exists $joining_type{$value} or
      die "unexpected joining type value '$value' within $src on line $lno";
      
    $cp > 0 && defined $UCD_records[$cp] or
      die "unassagned code point: '$value'";
    
    $UCD_records[$cp]{joining_type} = $joining_type{$value};
    exists $applied{$value} or $applied{$value} = 0;
    $applied{$value}++;
  }
  
  # unlisted joining types
  #
  # Note: Code points that are not explicitly listed in this file are
  # either of type T or U:
  #
  # - Those that not explicitly listed that are of General Category Mn or Cf
  #   have joining type T.
  # - All others not explicitly listed have type U.
  #
  foreach ( keys %UCD_records ) {
    my $r = $UCD_records{$_};
    next if defined $r->{joining_type};
    my $value = ($r->{gc} eq q/Mn/ || $r->{gc} eq q/Cf/) ? q|T| : q|U|;
    $r->{joining_type} = $joining_type{$value};
    exists $applied{$value} or $applied{$value} = 0;
    $applied{$value}++;
  }
  

  # stats
  foreach (keys %applied) {
    LOG __FILE__, "applied joining type $_: $applied{$_} times.";
  }

}

1;
