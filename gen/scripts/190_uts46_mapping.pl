## UTS46 IDNA Mapping Table
##
## @read: UTS46_Status.txt
## @read: IdnaMappingTable.txt
## @update: @UCD_records, %UTS46_Status
## @write: "uts46_status.h"
our ($UCD_H, %UCD_records, @UCD_records, %UTS46_Status);
our ($RE_codepoint_interval, $RE_codepoint);
package main;
use strict;
{

  my $re_status = qr/[a-z]+[A-Za-z0-9_]*+/;

  my $add_enum_value = sub {
    my $enum = shift;
    my ($name,$value,$help) = @_;
    $enum->push({
      c_name => "uts46_status_$name",
      cpp_name => $name,
      help => [$help],
      value => $value });
  };

  #my $path = +GEN_PATH("uts46_status.h");
  #my $fh = c_open_header($path, +BUILD_PATH("uts46_status.h"));
	print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H <<HERE;
/*
  Unicode IDNA Compatibility Processing
  see:
    http://unicode.org/reports/tr46/#IDNA_Mapping_Table

*/
HERE

  ## enum GeneralCategory
  my $enum = Idna2::Code::enum->create(
    c_name => "UTS46_STATUS", cpp_name => "Uts46Status",
    help => "UTS46 Status Values"
    );

  ## read UTS46_Status.txt
  read_table(q[UTS46_Status],sub {
    ## Lu;Uppercase_Letter;an uppercase letter
    my ($value,$desc) = @_;
    $value =~ /$re_status/ or return undef;
    my $n = 1 + scalar keys %UTS46_Status;
    $UTS46_Status{$value} = $n;
    &$add_enum_value($enum, to_variable($value), $n, "$desc");
    #LOG __FILE__, "UTS46 status: $value = $n";
    1;
  });



  # read: UTS46/IdnaMappingTable.txt
  # 0000..002C    ; disallowed_STD3_valid                  # 1.1  <control-0000>..COMMA
  # 00AE          ; valid                  ;      ; NV8    # 1.1  REGISTERED SIGN
  # 00AF          ; disallowed_STD3_mapped ; 0020 0304     # 1.1  MACRON
  my $re_line = qr/^
    $RE_codepoint_interval
    \s*;\s*
    ($re_status)
    (?:
      \s*;\s*
      ((?:$RE_codepoint\s+)*)
      (\s*;\s*NV8)?
    )?
  /x;
  
  my %stats;
  my $mapping_maxl = 0;
  my $src = require_source(q/UTS46_Mapping/);
  my $ex = 0;
  open my $src_h, '<', $src or die $!;
  my ($lno);
  for ($lno = 1; <$src_h>; $lno++) {
    chomp;
    s/#.*//;
    /\S/ or next;
    /$re_line/ or
      die "line not understood: '$_' on line $lno";
    
    my ($lo,$up,$status,$mapping,$nv8) = (hex($1),(defined $2 ? hex($2) : 0),$3,$4,$5);
    $up = $lo unless $up;
    exists $UTS46_Status{$status} or
      die "unexpected status '$status' on line $lno";
    my @mapping;
    if (defined $mapping) {
      for ($mapping) {
        s/^\s+//; s/\s+$//
      }
      if ($mapping =~ /\S/) {
        @mapping = map(hex, split /\s+/, $mapping);
      }
    }
    
    # If this status value is mapped, disallowed_STD3_mapped or deviation,
    # the table also supplies a mapping value for that code point.
    if (grep /^$status$/, qw( mapped disallowed_STD3_mapped )) {
      @mapping > 0 or
        die cp_range($lo,$up).": mapping expected for status '$status'";
    }
    
    $mapping_maxl = @mapping if @mapping > $mapping_maxl;

    foreach ($lo .. $up) {
      defined $UCD_records[$_] or next;
      my $r = $UCD_records[$_];
      
      $UCD_records[$_]{uts46_status} = $status;
      $UCD_records[$_]{uts46_nv8} = 1 if defined $nv8;
      if (@mapping > 0) {
        $UCD_records[$_]{uts46_mapping} = [@mapping];
      }
    }
    
    exists $stats{$status} or $stats{$status} = 0;
    $stats{$status}++;

  }
  close $src_h;

  foreach (keys %stats) {
    LOG __FILE__, "UTS46 status '$_': found $stats{$_}.";
  }
  
  LOG __FILE__, sprintf "maximum uts46 mapping length: %d", $mapping_maxl;

  # finish "uts46_status.h"
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H "#define UTS46_mapping_maxlength $mapping_maxl\n\n";

  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
	print $UCD_H $enum->c_decl, "\n\n";
	
	print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H $enum->cpp_decl, "\n\n";
  
  #c_close_header($fh,$path);

  #LOG __FILE__, "done: UTS46_Mapping.";
}

1;
