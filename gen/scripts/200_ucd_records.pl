##
## code pouint accessor code
##
## @read: $UCD_intervals, %UCD_record_flags
## @write: @UCD_record_ptr_arrays, $accessor_code
our (
	$UCD_H, $UCD_C,
	
  %Generated,
  %UCD_record_flags,
  $UCD_intervals,
  @UCD_record_ptr_arrays,

);
our (
  $UCD_record_array,
  %UCD_records,

  $UCD_name_array, $UCD_word_array,
  
  %UCD_GC,
  %UCD_BC, %UCD_DT,
  %UCD_Scripts,
  %RFC5892_prop,
  %UTS46_Status,
  
);
package main;
use strict;
{

  sub iv_result {
    my ($iv) = @_;
    my $k = iv_key($iv);
    return $UCD_records{$k}{ptr}
      if exists $UCD_records{$k};
    my $lo = $iv->[0];
    foreach my $r ( values %UCD_records ) {
      return $r->{ptr}
        if $r->{lower} == $lo;
    }
    0;
  }


  $UCD_record_array = idna2::codegen::array->create(
    name => q/records/, type => 'uint16_t');

  my %record_seq;
  my $decompmap_maxlength = 0; # maximum UTF16-length of decomposition mappings
  
  $UCD_name_array = idna2::codegen::array->create(
    name => q/names/, type => 'uint16_t');
  $UCD_word_array = idna2::codegen::array->create(
    name => q/words/, type => 'char *');

  my %words;
  
  #my $mappings_c = 0;
  #my $uts46_eq_decomp_c = 0;

  LOG __FILE__, sprintf "encoding %d records ...", (scalar keys %UCD_records);
  foreach ( keys %UCD_records ) {
    my $r = $UCD_records{$_};
    my ($record_ptr);

    my @word_ptr;
    my @words = split /\s+/, $r->{name};
    foreach ( @words ) {
      my $p;
      if ( exists $words{$_} ) {
        $p = $words{$_};
      } else {
        $p = $words{$_} = $UCD_word_array->length;
        $UCD_word_array->push($_);
      }
      push @word_ptr, $p;
    }
    
    # Decomposition_Mapping
    my $decompmap_c = 0;
    my @decompmap;
    if ( defined $r->{dm} ) {
      $decompmap_c = scalar @{$r->{dm}};
      foreach ( @{$r->{dm}} ) {
        push @decompmap, encode_utf16($_);
      }
      $decompmap_maxlength = $decompmap_c
        if $decompmap_c > $decompmap_maxlength;
    }

    # UTS46 Mapping
    my $uts46_mapping_c = 0;
    my @uts46_mapping;
    if ( defined $r->{uts46_mapping} ) {
      $uts46_mapping_c = scalar @{$r->{uts46_mapping}};
      foreach ( @{$r->{uts46_mapping}} ) {
        push @uts46_mapping, encode_utf16($_);
      }
    }
    
    # Check whether docimposition map equals uts46 map.
    #
    # Both mappings are equal in 61% of all mappings, so we can
    # save data by omitting uts46_mapping in this case.
    if ($decompmap_c > 0) {
      if ($decompmap_c == $uts46_mapping_c) {
        my $eq = 1;
        foreach (0 .. $#decompmap) {
          if ($decompmap[$_] != $uts46_mapping[$_]) {
            $eq = 0;
            last;
          }
        }
        $r->{flags} |= $UCD_record_flags{UTS46MAP_EQUALS_DECOMPMAP}
          if $eq;
      }
    }

    # paranoid checks
    exists $UCD_GC{$r->{gc}} or
      die "missing gc value";
    exists $UCD_BC{$r->{bc}} or
      die "undefined bc value '$r->{bc}'";
    exists $UCD_DT{$r->{dt}} or
      die "undefined dt value '$r->{dt}'";
    exists $UCD_Scripts{$r->{script}} or
      die "unregistered script value '$r->{script}'";
    exists $RFC5892_prop{$r->{rfc5892}} or
      die "unregistered rfc5892 value '$r->{rfc5892}'";
    exists $UTS46_Status{$r->{uts46_status}} or
      die sprintf
      "unexpected uts46_status value '$r->{uts46_status}' for U+%04X.", $_;

    my @a; # 16bit array sequence
    
    # /* flags + gc */
    push @a, (
      ($r->{flags} & 0x00FF) |
      (($UCD_GC{$r->{gc}} << 8) &0xFF00 )
    );

    # /* script + bidi_class */
    push @a, (
      ($UCD_Scripts{$r->{script}} & 0x00FF) |
      (($UCD_BC{$r->{bc}} << 8) &0xFF00 )
    );
    
    # /* ccc + dt  */
    push @a, (
      ($r->{ccc} & 0x00FF) |
      (($UCD_DT{$r->{dt}} << 8) &0xFF00 )
    );
    
    # /* nfqc + (decomposition length) */
    push @a, (
      (int($r->{nfqc}) & 0x00FF) |
      (($decompmap_c << 8) &0xFF00 ) # decomposition sequence
    );
    
    # /* decomposition mapping sequence */
    if ($decompmap_c > 0)
    {
      push @a, @decompmap;
    }
    
    # /* (joining_type) + (rfc5892 prop.) */
    push @a, (
      (int($r->{joining_type}) & 0x00FF) |
      (($RFC5892_prop{$r->{rfc5892}} << 8) & 0xFF00 )
    );

    # /* (uts46_status) + (uts46_mapping length) */
    push @a, (
      (($UTS46_Status{$r->{uts46_status}}) & 0x00FF ) |
      (($uts46_mapping_c << 8) &0xFF00 ) # decomposition sequence
    );

    if ($uts46_mapping_c > 0) {
      if (0 == ($r->{flags} & $UCD_record_flags{UTS46MAP_EQUALS_DECOMPMAP})) {
      #LOG __FILE__, sprintf "## UTS46 mapping %04X", $r->{lower};
        push @a, @uts46_mapping;
      }
    }

    # /* (name word count) + (rfc5892 prop.) */
    push @a, (
      ((scalar @word_ptr) & 0x00FF) |  # name length
      0
      #(($RFC5892_prop{$r->{rfc5892}} << 8) & 0xFF00 )
    );
    
    # /* words of name */
    push @a, @word_ptr;

#     # /* uppercase */
#     if ( $r->{flags} & $UCD_record_flags{HAVE_UPPERCASE} ) {
#       push @a, encode_utf16($r->{upper_case});
#     }
#
#     # /* lowercase */
#     if ( $r->{flags} & $UCD_record_flags{HAVE_LOWERCASE} ) {
#       push @a, encode_utf16($r->{lower_case});
#     }

    # get record pointer
    my $a = join ',', @a;
    if ( exists $record_seq{$a} ) {
      $record_ptr = $record_seq{$a};
    } else {
      $record_ptr = 1 + $UCD_record_array->length;
      $record_seq{$a} = $record_ptr;
      #my @uint16 = (map { sprintf '0x%04X' => $_ } @a);
      my @uint16 = (map { c_uint($_) } @a);
      $uint16[0] = " /* $r->{info} */ " . $uint16[0];
      $UCD_record_array->push(@uint16);
      #$UCD_record_array->push((map { sprintf '0x%04X' => $_ } @a));
    }

    $r->{ptr} = $record_ptr;
  }
  LOG __FILE__, sprintf "records pointers created: %d", (scalar keys %record_seq);
  LOG __FILE__, sprintf "record array length: %d", $UCD_record_array->length;
  
  #LOG __FILE__, "uts46_eq_decomp = $uts46_eq_decomp";
  #LOG __FILE__, sprintf "uts46 and decomposition mappings are equal: %d%%",
  #  ($uts46_eq_decomp_c / $mappings_c * 100);


  LOG __FILE__, "adding large gaps ...";
  my $oldc = scalar @$UCD_intervals;
  $UCD_intervals->add_large_gaps;
  LOG __FILE__, sprintf "large gaps added: having %d intervals now (%d more).",
    (scalar @$UCD_intervals), ((scalar @$UCD_intervals) - $oldc);

#
# # debug
# open my $debug_h, '>', 'debug1' or die $!;
# foreach my $iv (@$UCD_intervals) {
#   my $s = sprintf '%04X' => $iv->[0];
#   if ($iv->[1] > $iv->[0]) {
#     $s .= (sprintf '..%04X' => $iv->[1]);
#   }
#   my $t = iv_result($iv);
#   printf $debug_h "$s ; $t\n";
# }
# close $debug_h;
#

  # optimization
  LOG __FILE__, "joining equal neighbours ...";
  my $old_c = scalar @$UCD_intervals;
  $UCD_intervals->join_equal(\&iv_result);
  my $new_c = scalar @$UCD_intervals;
  LOG __FILE__, sprintf "equal neighbours joined: having %d intervals now (saved %d%%)",
    (scalar @$UCD_intervals), int((1 - $new_c / $old_c) * 100);

#   LOG __FILE__, "equal neighbours joined: having", (scalar @$UCD_intervals),
#     "intervals now (saved: $s%).";
#  LOG __FILE__, "highest interval: ", cp_range(@{$UCD_intervals->[$#{$UCD_intervals}]});

#
# # debug
# open my $debug_h, '>', 'debug2' or die $!;
# foreach my $iv (@$UCD_intervals) {
#   my $s = sprintf '%04X' => $iv->[0];
#   if ($iv->[1] > $iv->[0]) {
#     $s .= (sprintf '..%04X' => $iv->[1]);
#   }
#   my $t = iv_result($iv);
#   printf $debug_h "$s ; $t\n";
# }
# close $debug_h;
#
#die "stop here";

  LOG __FILE__, "creating accessor ...";
  # create record accessor
  my $array_assigned = 0;
  my $split_large_first = 100;
  my $split_large_max = 300;

  my $accessor = $UCD_intervals->create_accessor(
    split_large_first => $split_large_first,
    split_large_max => $split_large_max,
    get_result => \&iv_result,
    create_array => sub { # $create_array
      my ($a) = @_;
      my $n = 1 + scalar @UCD_record_ptr_arrays;
      my $name = qq/record_ptr_a/ . (sprintf '%02d' => $n);
      my $array = idna2::codegen::array->create(
        name => $name, type => q|uint32_t|);
      $array->push(@$a);
      $array_assigned += scalar @$a;
      push @UCD_record_ptr_arrays, $array;
      $array;
    },
    param => 'cp',
    map => \&c_uint);

  my $stats = {};
  my $accessor_code = c_create_accessor($accessor, $stats);
  LOG __FILE__, "accessor: max-depth: $stats->{max_depth};",
    "$stats->{branch_count} branches, $stats->{leave_count} leaves.";
  LOG __FILE__, "accessor: $array_assigned pointers distributed on",
    (scalar @UCD_record_ptr_arrays), "accessor arrays.";

  # calculate Shannon's entropy for the arrays
  my $e = 0;
  foreach ( @UCD_record_ptr_arrays ) {
    $e += $_->entropy;
  }
  LOG __FILE__, sprintf "average array entropy: %f", ($e / (scalar @UCD_record_ptr_arrays));
  LOG __FILE__, "maximum length of decomposition mappings: ", $decompmap_maxlength;

  print $UCD_H '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
	printf $UCD_H "#define UCD_DECOMPMAP_MAXL %d\n", (2*$decompmap_maxlength);


  # array decls
  print $UCD_C '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_C $UCD_record_array->decl, "\n";
  foreach ( @UCD_record_ptr_arrays ) {
    print $UCD_C $_->decl, "\n";
  }
  print $UCD_C "\n";
  
  print $UCD_C '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $UCD_C $UCD_word_array->decl, "\n";
  print $UCD_C "\n\n";

  #my $inc = +SCRIPT_SRC_PATH ("ucd_records.in.c");
  c_include(__FILE__, +SCRIPT_SRC_PATH ("ucd_records.in.c") => $UCD_C,
    FLAG_BIDI_MIRRORED => $UCD_record_flags{BIDI_MIRRORED},
    UTS46MAP_EQUALS_DECOMPMAP => $UCD_record_flags{UTS46MAP_EQUALS_DECOMPMAP},
    NAME_HEX_SUFFIX => $UCD_record_flags{NAME_HEX_SUFFIX},
    #HAVE_UPPERCASE => $UCD_record_flags{HAVE_UPPERCASE},
    #HAVE_LOWERCASE => $UCD_record_flags{HAVE_LOWERCASE},
    RECORD_ACCESSOR => $accessor_code);

}

1;
