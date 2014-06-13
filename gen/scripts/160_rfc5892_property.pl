##
## Derived property values according to rfc5892
##
## @read: "RFC5892_Property.txt", "rfc5892.txt"
## @write: %RFC5892_prop, @UCD_records
## @write: "rfc5892.h"
our ($UCD_H,%RFC5892_prop, @UCD_records, $RE_codepoint_interval);
package main;
use strict;
{

  my $add_enum_value = sub {
    my $enum = shift;
    my ($name,$value,$help) = @_;
    $enum->push({
      c_name => "rfc5892_$name",
      cpp_name => $name,
      help => [$help],
      value => $value });
  };


  #my $path = +GEN_PATH("rfc5892.h");
  #my $fh = c_open_header($path, +BUILD_PATH("rfc5892.h"));
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H <<HERE;
/**
 * Derived property values according to rfc5892
 *
 */
HERE
  
  ## enum RFC5892_Property
  my $enum = Idna2::Code::enum->create(
    c_name => "RFC5892_Property", cpp_name => "RFC5892Property",
    help => "Derived property values according to rfc5892"
    );


  my $re_value = qr/[A-Z]+/;

  ## read Decomposition_Type.txt
  read_table(q[RFC5892_Property],sub {
    # Nb;<noBreak>;Nobreak;No-break version of a space or hyphen
    my ($value,$desc) = @_;
    $value =~ /^$value$/ or return undef;
    my $n = scalar keys %RFC5892_prop;
    $RFC5892_prop{$value} = $n;
    &$add_enum_value($enum, to_variable($value), $n, $desc);
    1;
  });

  # finish "rfc5892.h"
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H $enum->c_decl, "\n\n";
  
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H $enum->cpp_decl, "\n\n";
  #c_close_header($fh,$path);
  
  ## read values from RFC5892
  my $re_property_interval = qr/^
    $RE_codepoint_interval
    \s*;\s*
    ($re_value)
  /x;

  my $re_start = qr/^Appendix B\.1\.\s+Code Points in Unicode Character Database/;
  my $re_end = qr/^8\.\s+References/;
  
  my $started = 0;
  my $src = require_source(q/RFC5892/);
  open my $src_h, '<', $src or die $!;
  my ($lno);
  for ($lno = 1; <$src_h>; $lno++) {
    chomp;
    unless ( $started )
    {
      /$re_start/ or next;
      $started = 1;
    }
    last if /$re_end/;
    
    /$re_property_interval/ or next;
    my ($lo,$up,$value) = (hex($1),(defined $2 ? hex($2) : 0), $3);
    $up = $lo unless $up > 0;
    exists $RFC5892_prop{$value} or
      die "unexpected property value '$value' within $src on line $lno";
    
    # apply to records
    foreach ( $lo .. $up ) {
      exists $UCD_records[$_] or next;
      $UCD_records[$_]{rfc5892} = $value;
    }

  }
  close $src_h;

	LOG __FILE__, "RFC5892_Property values found:", (scalar keys %RFC5892_prop);
}
1;
