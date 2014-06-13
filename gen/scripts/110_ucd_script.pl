## apply UCD script property and create enumeration,
## updating @UCD_records
##
## @read: "Scripts.txt"
## @write "ucd_script.h"
## @write: %UCD_Scripts, @UCD_records
our ($UCD_H, %UCD_Scripts, @UCD_records);
our ($RE_codepoint_interval);
package main;
use strict;
{

  my %script_names;
  my %script_iv_result;
  my $script_intervals = idna2::codegen::interval->create;


  # 0000..001F    ; Common # Cc  [32] <control-0000>..<control-001F>
  my $re_script_interval = qr/^
    $RE_codepoint_interval
    \s+;\s*
    (\w+)
  /x;

  my $add_enum_value = sub {
    my $enum = shift;
    my ($name,$value,$help) = @_;
    $script_names{$value} = $name;
    $enum->push({
      c_name => "ucd_script_$name",
      cpp_name => $name,
      help => [$help],
      value => $value });
  };

  #my $path = +GEN_PATH("ucd_script.h");
  #my $fh = c_open_header($path,+BUILD_PATH("ucd_script.h"));
	print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H <<HERE;
/*
Unicode Script Names

  source:
    http://www.unicode.org/Public/UNIDATA/Scripts.txt
*/
HERE

  ## enum Script
  my $enum = Idna2::Code::enum->create(
    c_name => "UCD_SCRIPT", cpp_name => "Script",
    help => "Unicode Script Names"
    );

  #  All code points not explicitly listed for Script
  #  have the value Unknown (Zzzz).
  $UCD_Scripts{Unknown} = 0;
  &$add_enum_value($enum, q/Unknown/, 0,
    "unassigned, private-use, noncharacter, and surrogate code points");

  $UCD_Scripts{Common} = 1;
  &$add_enum_value($enum, q/Common/, 1,
    "characters that may be used with multiple script");

  $UCD_Scripts{Inherited} = 2;
  &$add_enum_value($enum, q/Inherited/, 2,
    "characters that may be used with multiple scripts, and that inherit ".
    "their script from the preceding characters");

  my $src = require_source(q/Scripts/);
  open my $src_h, '<', $src or die $!;
  my ($lno);
  for ($lno = 1; <$src_h>; $lno++) {
    chomp;
    s/#.*//;
    /\S/ or next;
    /$re_script_interval/ or
      die "line $lno of $src not understood: '$_'";
    my ($lo,$up,$script_name) = (hex($1),(defined $2 ? hex($2) : 0),$3);
    $up = $lo unless $up > 0;
    
    my $script = to_variable($script_name);
    

    my $n;
    if ( exists $UCD_Scripts{$script} ) {
      $n = $UCD_Scripts{$script};
    } else {
      $n = scalar keys %UCD_Scripts;
      $UCD_Scripts{$script} = $n;
      &$add_enum_value($enum, $script, $n, "$script_name script");
    }

    # add interval
    unless ( $script eq q/Unknown/ ) {
      my $iv = [$lo,$up];
      $script_intervals->push($iv);
      my $k = iv_key($iv);
      $script_iv_result{$k} = $script;
    }

    # apply to records
    foreach ( $lo .. $up ) {
      exists $UCD_records[$_] or
        die "could not apply script property to non existing code point ".
        sprintf('%04X', $_);
      $UCD_records[$_]{script} = $script;
    }

  }
  close $src_h;

  # finish "ucd_script.h"
  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_H $enum->c_decl, "\n\n";
  print $UCD_H $enum->cpp_decl, "\n\n";

  #c_close_header($fh,$path);



  # accessor
  
  my $get_result = sub { # $get_result
      my ($lo,$up) = @{$_[0]};
      my $iv;
      foreach (@$script_intervals) {
        my ($lo2,$up2) = @$_;
        if ($lo2 <= $lo && $up <= $up2) {
          $iv = $_;
          last;
        }
      }
      die "no match: $lo:$up" unless $iv;
      my $k = iv_key($iv);
      #die "result not found for $k" unless exists $script_iv_result{$k};
      return q/Unknown/ unless exists $script_iv_result{$k};
      $script_iv_result{$k};
    };
  
  #LOG __FILE__, "optimizing ...";
  #$script_intervals->add_gaps;
  #LOG __FILE__, "gaps added: having", (scalar @$script_intervals), " intervals now.";

  my $old_c = scalar @$script_intervals;
  $script_intervals->join_equal($get_result);
  my $new_c = scalar @$script_intervals;
  my $s = int((1 - $new_c / $old_c) * 100);
  LOG __FILE__, "equal neighbours joined: having", (scalar @$script_intervals),
    "intervals now (saved: $s%).";

  my $accessor = $script_intervals->create_accessor(
    split_large_first => 256,
    split_large_max => 0, # no arrays
    get_result => $get_result,
#     sub { # $get_result
#       my ($lo,$up) = @{$_[0]};
#       my $iv;
#       foreach (@$script_intervals) {
#         my ($lo2,$up2) = @$_;
#         if ($lo2 <= $lo && $up <= $up2) {
#           $iv = $_;
#           last;
#         }
#       }
#       die "no match: $lo:$up" unless $iv;
#       my $k = iv_key($iv);
#       #die "result not found for $k" unless exists $script_iv_result{$k};
#       return q/Unknown/ unless exists $script_iv_result{$k};
#       $script_iv_result{$k};
#     },
    create_array => sub { # $create_array
      die "the script interval accessor is expected to work without arrays";
    },
    param => 'cp',
    map => \&c_uint
    );

  my $stats = {};
  my $accessor_code = c_create_accessor($accessor, $stats);
  LOG __FILE__, "script accessor: max-depth: $stats->{max_depth};",
    "$stats->{branch_count} branches, $stats->{leave_count} leaves.";

  #print $accessor_code, "\n";

	LOG __FILE__, "scripts found:", (scalar keys %UCD_Scripts);
}
1;
