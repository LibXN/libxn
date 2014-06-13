## create block interval selector and enumeration
##
## @read: "Blocks.txt"
## @write "ucd_block.h"
## @write: %UCD_Blocks, @UCD_Blocks
our (%UCD_Blocks, @UCD_Blocks);
our ($RE_codepoint_interval);
package main;
use strict;
{

  my $re_block_interval = qr/^
    $RE_codepoint_interval
    \s*;\s*
    ([\w \-]+)
  $/x;
  
  my $add_enum_value = sub {
    my $enum = shift;
    my ($name,$value,$help) = @_;
    $enum->push({
      c_name => "ucd_block_$name",
      cpp_name => $name,
      help => [$help],
      value => $value });
  };

  my $ucd_block_h = c_open_header(__FILE__, +GEN_PATH("ucd_block.h"));
  print $ucd_block_h <<HERE;
/*
Unicode Block Names

  http://www.unicode.org/Public/UNIDATA/Blocks.txt
*/
HERE

  ## enum Block
  my $enum = Idna2::Code::enum->create(
    c_name => "UCD_BLOCK", cpp_name => "Block",
    help => "Unicode Block Names"
    );
    
  $UCD_Blocks{NoBlock} = 0;
  &$add_enum_value($enum, q/NoBlock/, 0,
    "Outside the Unicode code point range");

  my %block_iv_result;
  my $block_intervals = idna2::codegen::interval->create;
  my $src = require_source(q/Blocks/);
  open my $src_h, '<', $src or die $!;
  my ($lno);
  for ($lno = 1; <$src_h>; $lno++) {
    chomp;
    s/#.*//;
    /\S/ or next;
    /$re_block_interval/ or
      die "line $lno of $src not understood: '$_'";
    my ($lo,$up,$block_name) = (hex($1), hex($2), $3);
    $up = $lo unless $up > 0;

    my $block = to_variable($block_name);

    my $n;
    if ( exists $UCD_Blocks{$block} ) {
      $n = $UCD_Blocks{$block};
    } else {
      $n = scalar keys %UCD_Blocks;
      $UCD_Blocks{$block} = $n;
      my $comment = "$block_name ".
        (sprintf 'U+%04X', $lo).(($up > $lo)? '...'.(sprintf 'U+%04X', $up) : '');
      &$add_enum_value($enum, $block, $n, $comment);
    }

    # add intervaö
    my $iv = [$lo,$up];
    $block_intervals->push($iv);
    my $k = iv_key($iv);
    $block_iv_result{$k} = $n;

    foreach ( $lo .. $up ) {
      $UCD_Blocks[$_] = $block;
    }

  }
  close $src_h;
  
  # some paranoid checks
  scalar keys %UCD_Blocks == 1 + scalar @$block_intervals or
    die "number of blocks doesn't match the number of block intervals";
  0x110000 == $block_intervals->total_length or
    die "unexpected block interval range";
  
  # finish "ucd_block.h"
  print $ucd_block_h '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $ucd_block_h $enum->c_decl, "\n\n";
  
  print $ucd_block_h '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $ucd_block_h $enum->cpp_decl, "\n\n";
  
	c_include(__FILE__, +SCRIPT_SRC_PATH ("ucd_block.in.h") => $ucd_block_h);
  c_close_header($ucd_block_h);

  # accessor
  LOG __FILE__, "optimizing ...";
  $block_intervals->add_large_gaps;
  LOG __FILE__, "large gaps added: having", (scalar @$block_intervals), " intervals now.";

  my $accessor = $block_intervals->create_accessor(
    split_large_first => 256,
    split_large_max => 1, # no arrays
    get_result => sub { # $get_result
      my $k = iv_key($_[0]);
      return 0 unless exists $block_iv_result{$k};
      $block_iv_result{$k};
    },
    create_array => sub {
      die "the block interval accessor is expected to work without arrays";
    },
    param => 'cp',
    map => \&c_uint
    );

  my $stats = {};
  my $accessor_code = c_create_accessor($accessor, $stats);
  LOG __FILE__, "block accessor: max-depth: $stats->{max_depth};",
    "$stats->{branch_count} branches, $stats->{leave_count} leaves.";

  # code
  my $ucd_block_c = c_open_source(__FILE__, +GEN_PATH("ucd_block.c"));
  
  print $ucd_block_c qq(#include "ucd_block.gen.h"\n\n);
  print $ucd_block_c '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $ucd_block_c <<HERE;
enum UCD_BLOCK
	ucd_get_block (codepoint_t cp)
{

$accessor_code

  return(0);
}

HERE
  c_close_source($ucd_block_c);

	LOG __FILE__, "blocks found:", (scalar keys %UCD_Blocks);
}

1;
