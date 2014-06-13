## General_Category
##
## @read: "General_Category.txt"
## @write: "ucd_gc.h"
## @write: %UCD_GC
our ($UCD_H, %UCD_GC);
package main;
use strict;
{

  my $re_gc = qr/^[A-Z][a-z]$/;
  my $re_long = qr/^[A-Za-z_]+$/;

  my $add_enum_value = sub {
    my $enum = shift;
    my ($name,$value,$help) = @_;
    $enum->push({
      c_name => "ucd_gc_$name",
      cpp_name => $name,
      help => [$help],
      value => $value });
  };

  #my $path = +GEN_PATH("ucd_gc.h");
  #my $fh = c_open_header($path, +BUILD_PATH("ucd_gc.h"));
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H <<HERE;
/*
  General_Category (gc)

  see "Table 12. General_Category Values";
    http://www.unicode.org/reports/tr44/#General_Category_Values
  
*/
HERE

  ## enum GeneralCategory
  my $enum = Idna2::Code::enum->create(
    c_name => "UCD_GENERAL_CATEGORY", cpp_name => "GeneralCategory",
    help => "General Category Values"
    );
    
  $UCD_GC{Undefined} = 0;
  &$add_enum_value($enum, q/Undefined/, 0,
    "Outside the Unicode code point range");


  ## read General_Category.txt
  read_table(q[General_Category],sub {
    ## Lu;Uppercase_Letter;an uppercase letter
    my ($gc,$long,$desc) = @_;
    $gc =~ /$re_gc/ or return undef;
    $long =~ /$re_long/ or return undef;
    my $n = scalar keys %UCD_GC;
    $UCD_GC{$gc} = $n;
    &$add_enum_value($enum, to_variable($gc), $n, "($long) $desc");
    #LOG __FILE__, "general category: $gc = $n";
    1;
  });

  # finish "ucd_gc.h"
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H $enum->c_decl, "\n\n";
  
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H $enum->cpp_decl, "\n\n";

#   print $fh c_enum_end, "\n";
  #c_close_header($fh,$path);
  
  LOG __FILE__, "General_Category values found:", (scalar keys %UCD_GC);
}

1;
