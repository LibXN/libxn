#!/usr/bin/perl -Imodules
##
## Copyright (C) 2011 Sebastian Böthin.
##
## Project home: <http://www.LibXN.org>
## Author: Sebastian Böthin <sebastian@boethin.eu>
##
## This file is part of LibXN.
##
## LibXN is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## LibXN is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with LibXN. If not, see <http://www.gnu.org/licenses/>.
##
##
use strict;
use code;
use File::Copy;

BEGIN {
  our $START = time;

  ## logger
  *LOG = sub {
    local $\ = "\n"; local $, = ' '; print "[".(shift)."]", @_
	};

	## modules
  require q/array.pm/;
  require q/enum.pm/;
  require q/interval.pm/;
}
END {
  our ( $START );
  my $duration = time - $START;
  LOG __FILE__, "took $duration seconds.";
}

## =============================================================================
## globals
##
our (
  #%GENERATING,
  
  %UCD_record_flags,

  # Unicode character names
  $UCD_name_array, $UCD_word_array,

  # UCD record data
  %UCD_records, @UCD_records,
  $UCD_record_array,
  @UCD_record_ptr_arrays,
  $UCD_intervals, %UCD_interval_ptr,

  # General_Category
  %UCD_GC,

  # Bidi classes
  %UCD_BC,
  
  # UCD Decomposition types
  %UCD_DT, %UCD_DT_tags,

  # Scripts
  %UCD_Scripts,

  # Unicode Blocks
  %UCD_Blocks, @UCD_Blocks,
  
  # Derivied properties (RFC 5892)
  %RFC5892_prop,
  
  %UTS46_Status,

  # "ucd.c" file handle
  $UCD_C,
  
  # "ucd.h" file handle
  $UCD_H,


);


## =============================================================================
## regex definitions
##
our $RE_codepoint = qr/[0-9A-F]{4,6}/;
our $RE_codepoint_interval = qr/^($RE_codepoint)(?:\.\.($RE_codepoint))?/;
our $RE_cpname = qr/^(?:[A-Z0-9 \-]+|<control>)$/i;

## =============================================================================
## procedures
##

# map anything to a C compatible variable name
my $re_variable = qr/^[a-z][a-z0-9]*$/i;
sub to_variable {
  my $s = shift;
  for ( my $t = $s ) {
    s/[_\-]/ /g; s/\b(\w+)/qq{\u$1}/eg; s/\s+//g;
    m/$re_variable/ or
      die "inappropriate variable name: '$s'";
    return $t;
  }
}

# create hash key from a pair of values
sub iv_key {
  my ($lo,$up) = @{$_[0]};
  qq($lo:$up);
}


# code point range output (for debugging)
sub cp_range {
  my ($lo,$up) = @_;
  my $s = sprintf 'U+%04X' => $lo;
  $s .= sprintf '..U+%04X' => $up if $up > $lo;
  $s;
}

# utf-16 encoding
sub encode_utf16 {
  my ($cp) = @_;
  $cp > 0xFFFF or return ($cp);
  my $lead_offset = 0xD800 - (0x10000 >> 10);
  my $surrogate_offset = 0x10000 - (0xD800 << 10) - 0xDC00;
  my $lead = $lead_offset + ($cp >> 10);
  my $trail = 0xDC00 + ($cp & 0x3FF);
  ($lead,$trail);
}


# 8bit flags
# must be compatible with UCD_PROP_FLAG (ucd.h):
#
#   enum UCD_PROP_FLAG
#   {
#
#     /* code points appearing as part of a canonical combining pair */
#     ucd_prop_COMPOSING = (1 << 1),
#
#     /* bidi mirrored property */
#     ucd_prop_BIDI_MIRRORED = (1 << 2)
#   };
%UCD_record_flags = (

  # /* code points appearing as part of a canonical combining pair */
  # ucd_prop_COMPOSING = 1,
  COMPOSING => 1,
  
  # /* bidi mirrored property */
  # ucd_prop_BIDI_MIRRORED = 2
  BIDI_MIRRORED => 2,
  
#  HAVE_UPPERCASE => 4,
#  HAVE_LOWERCASE => 8,
  
  # decomposition mapping equals uts46 mapping (61% of all mappings)
  UTS46MAP_EQUALS_DECOMPMAP => 8,
  
  
  # code point name ends with hex code, e.g.:
  # "CJK COMPATIBILITY IDEOGRAPH-2FA02"
  NAME_HEX_SUFFIX => 16,
  
);


#   $name,       ## Character name
#   $gc,         ## General Category                    ## 0 .. 30
#   $ccc,        ## Canonical Combining Class           ## 0 .. 240
#   $bidi,       ## Bidirectional Category              ## 0 .. 20
#   $decomp,     ## Character Decomposition Mapping     ## Compatibility Formatting Tags + Sequence
#   $decdigv,    ## Decimal digit value
#   $digv,       ## Digit value
#   $numv,       ## Numeric value
#   $bidi_m,   ## Mirrored                            ## Y/N
#   $name2,      ## Unicode 1.0 Name
#   undef,       ## 10646 comment field
#   $uc_map,     ## Uppercase Mapping                   ## single code point
#   $lc_map,     ##	Lowercase Mapping                   ## single code point
#   $tc_map      ## Titlecase Mapping                   ## single code point


# record encoding in 16bit sequence:
# [0] (8bit flags) + (General Category 0 .. 30)
# [1] (Bidirectional Category 0 .. 20) + (Compatibility Formatting Tags 0 .. 15)
#

## =============================================================================
## main process
##

##
## open "ucd.h" for writing
##
$UCD_H = c_open_header(__FILE__, +GEN_PATH("ucd.h"));


##
## open "ucd.c" for writing
##
$UCD_C = c_open_source(__FILE__, +GEN_PATH("ucd.c"), qw(string.h));
print $UCD_C '#include "encoding.h"', "\n\n";


## Unicode Character Database Version
##
## @read: "Readme.txt"
## @write: "ucd.c"
require q|scripts/001_ucd_version.pl|;
LOG __FILE__;


## General_Category
##
## @read: "General_Category.txt"
## @write: "ucd_gc.h"
## @update: %UCD_GC
require q|scripts/010_ucd_gc.pl|;
LOG __FILE__;

## Bidi_Class
##
## @read: "Bidi_Class.txt"
## @write: "ucd_bc.h"
## @update: %UCD_BC
require q|scripts/020_ucd_bc.pl|;
LOG __FILE__;

## Decomposition_Type
##
## @read: "Decomposition_Type.txt"
## @write: "ucd_dt.h"
## @update: %UCD_BC, %UCD_DT_tags
require q|scripts/030_ucd_dt.pl|;
LOG __FILE__;


#
#
# ## read UnicodeData.txt
# ## see "UnicodeData File Format, Version 3.0.1",
# ## http://www.unicode.org/reports/tr44/#UnicodeData.txt
# LOG __FILE__, "processing UnicodeData.txt ...";
# $UCD_intervals = idna2::codegen::interval->create;
# my $d = 0;
# {
#
#   ## http://www.unicode.org/reports/tr44/#Character_Decomposition_Mappings
#   my $re_decomposition = qr/^
#       (?:(<[a-zA-Z]+>)\s+)?
#       ((?:$RE_codepoint\s*)+)
#     $/x;
#
#   my $path = require_source(q/UnicodeData/);
#   open my $fh, '<', $path or die $!;
#   my ($lno,$range);
#   for ($lno = 1; <$fh>; $lno++) {
#     chomp;
#     my (
#       $value,      ## Code value
#       $name,       ## Character name
#       $gc,         ## General Category
#       $ccc,        ## Canonical Combining Class
#       $bidi,       ## Bidirectional Category
#       $decomp,     ## Character Decomposition Mapping
#       $decdigv,    ## Decimal digit value
#       $digv,       ## Digit value
#       $numv,       ## Numeric value
#       $bidi_m,     ## Bidi_Mirrored
#       $name2,      ## Unicode 1.0 Name
#       undef,       ## 10646 comment field
#       $uc_map,     ## Uppercase Mapping
#       $lc_map,     ##	Lowercase Mapping
#       $tc_map      ## Titlecase Mapping
#       ) = split /;/;
#
#     my $cp = hex($value);
#
#     # check for character range
#     if ( $name =~ /^<(.+),\s*First>$/ ) { # range begins
#       $range = [$cp => $1];
#       next;
#     }
#     my ($cp_lo,$cp_up);
#     if ( defined $range ) { # range completed
#       my ($cp1,$n) = @$range;
#       ( $name =~ /^<(.+),\s*Last>$/ && ($1 eq $n) ) or
#         die "end of range missing for '$n'";;
#       ($name,$cp_lo,$cp_up) = ($1,$cp1,$cp);
#       undef $range;
#     } else {
#       $cp_lo = $cp_up = $cp;
#     }
#     #$UCD_intervals->push([$cp_lo,$cp_up]);
#
#     my $flags = 0;
#
#     # (1) Name
#     $name =~ /$RE_cpname/ or
#       die "unexpected name '$name'";
#     # to save storage, cut off code point suffix
#     $flags |= $UCD_record_flags{NAME_HEX_SUFFIX}
#       if $name =~ s/-$value$//;
#
#     # (2) General_Category (gc)
#     exists $UCD_GC{$gc} or
#       die "unknown General_Category '$gc' (field 2)";
#
#     # (3) Canonical_Combining_Class (ccc)
#     if ($ccc =~ /\S/) {
#       ($ccc =~ /^\d+$/ && (0 <= $ccc && $ccc < 0x100)) or
#         die "Canonical_Combining_Class '$ccc' not understood (field 3)";
#     }
#
#     ## (4) Bidi_Class
#     exists $UCD_BC{$bidi} or
#       die "unexpected Bidi_Class '$bidi' (field 4)";
#
#     ## (5) Decomposition_Type, Decomposition_Mapping
#     my ($dm,$dt);
#     if ( $decomp =~ /\S/ ) {
#       if ( $decomp =~ /$re_decomposition/ ) {
#         my ($tag,$seq) = ($1,$2);
#         my @seq = map(hex, split /\s+/, $seq);
#         $dm = \@seq;
#         if ($tag) {
#           # get decomposition type from compatibility formatting tag
#           exists $UCD_DT_tags{$tag} or
#             die "unexpected compatibility decomposition tag '$tag' (field 5)";
#           $dt = $UCD_DT_tags{$tag};
#         } else {
#           # canonical mapping
#           die "canonical decompositions must be singles or pairs"
#             if ($#seq > 1);
#           exists $UCD_DT{Can} or
#             die "missing required decomposition type (Canonical)";
#           $dt = q/Can/;
#         }
#       } else {
#         die "Character Decomposition Mapping (field 5) not understood";
#       }
#     }
#     else {
#       exists $UCD_DT{None} or
#         die "missing required decomposition type (None)";
#       $dt = q/None/; # default
#     }
#
#     # (12) Simple_Uppercase_Mapping
#     my ($ucase);
# #     if ( $uc_map =~ /\S/ ) {
# #       $flags |= $UCD_record_flags{HAVE_UPPERCASE};
# #       $ucase = hex($uc_map);
# #     }
#
#     # (13) Simple_Lowercase_Mapping
#     my ($locase);
# #     if ( $lc_map =~ /\S/ ) {
# #       $flags |= $UCD_record_flags{HAVE_LOWERCASE};
# #       $locase = hex($lc_map);
# #     }
#
#     # (9) Bidi_Mirrored
#     $flags |= $UCD_record_flags{BIDI_MIRRORED}
#       if q|Y| eq $bidi_m; # Y/N
#
#     # (10) Unicode_1_Name
#     # Unicode 1.0 name for <control> (0000..001F, 007F..009F)
#     if ( $name eq q|<control>| && $name2 =~ /\S/ ) {
#       $name .= " ($name2)";
#     }
#
#     my $rkey = iv_key([$cp_lo,$cp_up]);
#     my $r = {
#       lower => $cp_lo,
#       upper => $cp_up,
#       info => cp_range($cp_lo,$cp_up),
#       name => $name,
#       flags => $flags,
#       gc => $gc,
#       ccc => $ccc,
#       bc => $bidi,
#       bm => (q|Y| eq $bidi_m ? 1 : 0),
#       dt => $dt,
#       dm => $dm,
#       upper_case => $ucase,
#       lower_case => $locase,
#       block => 0,
#       script => q/Unknown/,
#       nfqc => 0,
#     };
#
# #    $UCD_records{$rkey} = $r;
#     foreach ( $cp_lo .. $cp_up ) {
#        my $rk = iv_key([$_,$_]);
#        my %r = %$r;
#        $r{lower} = $r{upper} = $_;
#        my $rr = \%r;
#        $UCD_records{$rk} = $rr;
#        $UCD_records[$_] = $rr;
#        $UCD_intervals->push([$_,$_]);
#
#       #$UCD_records[$_] = $r;
#
#
#     }
#   }
#   close $fh;
#   LOG __FILE__, "$lno lines read.";
# }
#
#
# LOG __FILE__, "intervals found:", (scalar @{$UCD_intervals});
# LOG __FILE__, "code points assigned:", $UCD_intervals->assigned;
# LOG __FILE__, "highest code point:", (sprintf 'U+%04X', $UCD_intervals->upper_bound);
# LOG __FILE__, "records:", (scalar keys %UCD_records);
# LOG __FILE__, "done: UnicodeData.txt";
# LOG __FILE__,;
# {
#   # stats
#   my $total = (scalar keys %UCD_records);
#   my $ccc_c = 0;
#   my $bidi_c = 0;
#   my $dt_c = 0;
#   my $can_c = 0;
#   foreach ( keys %UCD_records ) {
#     my $r = $UCD_records{$_};
#     $ccc_c++ if $r->{ccc} == 0;
#     $bidi_c++ if $r->{bc} eq 'L';
#     $dt_c++ if $r->{dt} eq 'None';
#     $can_c++ if $r->{dt} eq 'Can';
#
#   }
#   LOG __FILE__, int($ccc_c/$total * 100)."% ($ccc_c records) have ccc = 0";
#   LOG __FILE__, int($dt_c/$total * 100)."% ($dt_c records) have dt = None";
#   LOG __FILE__, int($can_c/$total * 100)."% ($can_c records) have dt = Can";
#   LOG __FILE__, int($bidi_c/$total * 100)."% ($bidi_c records) have bc = L";
# }
# LOG __FILE__,;
#
#
require q|scripts/100_ucd_data.pl|;
LOG __FILE__;


## apply UCD script property and create enumeration,
## updating @UCD_records
##
## @read: "Scripts.txt"
## @write "ucd_script.h"
## @update: %UCD_Scripts, @UCD_records
require q|scripts/110_ucd_script.pl|;
LOG __FILE__;

## update UCD records with the joining type (Arabic and Syriac positional shaping)
##
## @read: "Joining_Type.txt"
## @read: "ArabicShaping.txt"
## @write: "ucd_joining.h"
## @update: @UCD_records
require q|scripts/120_ucd_joining.pl|;
LOG __FILE__;



## apply the Full_Composition_Exclusion property
##
## @read: "DerivedNormalizationProps.txt"
## @update: %UCD_records
## @write: "ucd_composition.c"
require q|scripts/150_ucnf_composition.pl|;
LOG __FILE__;

## read quick check values for Unicode Normalization Forms
##
## @read: "DerivedNormalizationProps.txt"
## @update: @UCD_records
require q|scripts/155_ucnf_nfqc.pl|;
LOG __FILE__;


##
## Derived property values according to rfc5892
##
## @read: "RFC5892_Property.txt", "rfc5892.txt"
## @write: %RFC5892_prop
## @write: "rfc5892.h"
require q|scripts/160_rfc5892_property.pl|;
LOG __FILE__;

##
## rfc5892 Contextual Rules Registry
##
## @write: "rfc5892_rules.c"
require q|scripts/165_rfc5892_rules.pl|;
LOG __FILE__,;

##
## UTS46 IDNA Mapping Table
##
## @read: UTS46_Status.txt
## @read: IdnaMappingTable.txt
## @update: @UCD_records, %UTS46_Status
## @write: "uts46_status.h"
require q|scripts/190_uts46_mapping.pl|;
LOG __FILE__,;



## create code pouint accessor code
##
## @read: $UCD_intervals
## @update: @UCD_record_ptr_arrays, $UCD_cprec_acc_code
require q|scripts/200_ucd_records.pl|;
LOG __FILE__,;

## create block interval selector and enumeration
##
## @read: "Blocks.txt"
## @write "ucd_block.h"
## @update: %UCD_Blocks, $UCD_block_access_code
require q|scripts/210_ucd_block.pl|;

LOG __FILE__;


## "ucd.c" data section
print $UCD_C '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
print $UCD_C $UCD_record_array->def, "\n";
foreach ( @UCD_record_ptr_arrays ) {
  print $UCD_C $_->def(\&c_uint), "\n";
}
print $UCD_C "\n";

#print $UCD_C $UCD_name_array->def, "\n";
print $UCD_C '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
print $UCD_C $UCD_word_array->def(sub { qq("$_[0]")}), "\n";


## done with "ucd.c"
c_close_source($UCD_C);

## done with "ucd.h"
c_include(__FILE__, +SCRIPT_SRC_PATH ("ucd.in.h") => $UCD_H);
c_close_header($UCD_H);


# LOG __FILE__, "creating tests ...";
# require q|scripts/ucd_test.pl|;

#require q|scripts/normalization_test.pl|;
#LOG __FILE__, "done.";
#LOG __FILE__,;

## move generated files to their final target
# foreach ( keys %GENERATING ) {
#   copy ($_ => $GENERATING{$_}) or
#     die "failed to copy $_: $!";
#   LOG __FILE__, "generated: $GENERATING{$_}";
# }

exit(0);
