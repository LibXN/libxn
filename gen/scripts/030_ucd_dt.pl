##
## Decomposition_Type
##
## @read: "Decomposition_Type.txt"
## @write: %UCD_DT, %UCD_DT_tags
## @write: "ucd_dt.h"
our ($UCD_H, %UCD_DT,%UCD_DT_tags);
package main;
use strict;
{

  my $add_enum_value = sub {
    my $enum = shift;
    my ($name,$value,$help) = @_;
    $enum->push({
      c_name => "ucd_dt_$name",
      cpp_name => $name,
      help => [$help],
      value => $value });
  };


  #my $path = +GEN_PATH("ucd_dt.h");
  #my $fh = c_open_header($path, +BUILD_PATH("ucd_dt.h"));
	print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H <<HERE;
/*
  Decomposition_Type (dt)

  see "Table 14. Compatibility Formatting Tags";
    http://www.unicode.org/reports/tr44/#Character_Decomposition_Mappings

The prefixed tags supplied with a subset of the decomposition mappings generally
indicate formatting information. Where no such tag is given, the mapping is
canonical. Conversely, the presence of a formatting tag also indicates that
the mapping is a compatibility mapping and not a canonical mapping.
In the absence of other formatting information in a compatibility mapping,
the tag is used to distinguish it from canonical mappings.

additional fields added:
  None: default
  Canonical: no tag given
(cf.: PropertyValueAliases.txt)
  
*/
HERE
  #print $fh c_enum_begin(q(DecompositionType), "Decomposition Type"), "\n\n";
  
  ## enum DecompositionType
  my $enum = Idna2::Code::enum->create(
    c_name => "UCD_DECOMPOSITION_TYPE", cpp_name => "DecompositionType",
    help => "Decomposition Type"
    );


  my $re_dt = qr/^[A-Z][a-z]+$/;
  my $re_tag = qr/^(?:<[A-Z]+>)?$/i;
  my $re_long = qr/^[A-Za-z_]+$/;

  ## read Decomposition_Type.txt
  read_table(q[Decomposition_Type],sub {
    # Nb;<noBreak>;Nobreak;No-break version of a space or hyphen
    my ($dt,$tag,$long,$desc) = @_;
    $dt =~ /$re_dt/ or return undef;
    $tag =~ /$re_tag/ or return undef;
    $long =~ /$re_long/ or return undef;
    my $n = scalar keys %UCD_DT;
    $UCD_DT{$dt} = $n;
    $UCD_DT_tags{$tag} = $dt if $tag =~ /\S/;
    #for ( $desc, $dt ) { s/^\s+//; s/\s+$//; }
    &$add_enum_value($enum, to_variable($long), $n, "$desc ($dt)");
    1;
  });

  # finish "ucd_dt.h"
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H $enum->c_decl, "\n\n";
  
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H $enum->cpp_decl, "\n\n";

	#c_close_header($fh,$path);

	LOG __FILE__, "Decomposition_Type (dt) values found:", (scalar keys %UCD_DT);
}

1;
