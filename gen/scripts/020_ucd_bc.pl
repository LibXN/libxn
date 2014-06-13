## Bidi_Class
##
## @read: "Bidi_Class.txt"
## @write: "ucd_bc.h"
## @write: %UCD_BC
our ($UCD_H, %UCD_BC);
package main;
use strict;
{

  my $add_enum_value = sub {
    my $enum = shift;
    my ($name,$value,$help) = @_;
    $enum->push({
      c_name => "ucd_bidi_$name",
      cpp_name => $name,
      help => [$help],
      value => $value });
  };

  #my $path = +GEN_PATH("ucd_bc.h");
  #my $fh = c_open_header($path, +BUILD_PATH("ucd_bc.h"));
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H <<HERE;
/*
  Bidi_Class (bc)

  see: "Table 13. Bidi_Class Values";
    http://www.unicode.org/reports/tr44/#Bidi_Class_Values
*/

HERE
  
  ## enum Bidi
  my $enum = Idna2::Code::enum->create(
    c_name => "UCD_BIDI_CLASS", cpp_name => "BidiClass",
    help => "Bidi Class Values");


  my $re_bidi = qr/^[A-Z]{1,3}$/;
  my $re_long = qr/^[A-Za-z_]+$/;

  ## read Bidi_Class.txt
  read_table(q[Bidi_Class],sub {
    # L;Left_To_Right;any strong left-to-right character
    my ($bidi,$long,$desc) = @_;
    $bidi =~ /$re_bidi/ or return undef;
    $long =~ /$re_long/ or return undef;
    my $n = 1 + scalar keys %UCD_BC;
    $UCD_BC{$bidi} = $n;
    &$add_enum_value($enum, to_variable($bidi), $n, "($long) $desc");
    1;
  });

  # finish "ucd_bc.h"
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H $enum->c_decl, "\n\n";
  
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H $enum->cpp_decl, "\n\n";
  #c_close_header($fh,$path);

	LOG __FILE__, "Bidi_Class values found:", (scalar keys %UCD_BC);
}

1;
