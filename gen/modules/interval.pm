package idna2::codegen::interval;
use strict;

# The Unicode Character Database (UCD) consists of about a quarter of a million
# code points, spread among numbers between 0 and 1.1 million (0x10FFFF).
# Several properties are applied to either individual code points or
# ranges of them.

# There are two basic strategys:
#
# (1) Roll out everything to a huge if-else-construct, i.e. generating
#     a hard-coded binary search tree.
#     This will result in slow code, since you will need a very lot of
#     comparisons in order to localize a single code point (take log2 of 250.000).
# (2) Store the result as array, indexed by code points.
#     This will result in a huge amount of data.
#
# A mixed strategy is to create a search tree reflecting large intervals
# where the leaves are pointing to arrays reflecting collections of
# small intervals. Then,
# (1) the search tree depth determines the number of comparisons and
# (2) the avarage array entropy is a measure for the quality of distribution.
# So, the most efficient accessor code minimizes (1) and maximizes (2).
#
# The most frequently used code points (Latin, Greek, Cyrillic, Arabic, etc.)
# are located below U+085F, while U+085F.. U+08FF are unassigned and, as a
# rough guess, the code point access above U+0900 is assumed to be uniformely
# distributed.
#

# An interval is coded into an array if it's largest sub-interval
# is length less or equal to SPLIT_LARGE_MAX.
# Otherwise it's split into if-else.
# The smaller SPLIT_LARGE_MAX, the more accessor arrays you get.
#use constant SPLIT_LARGE_MAX => 100;

# 085F..08FF (161) is the first large interval
#use constant SPLIT_LARGE_FIRST => 100;

# the bound from where a gap is considered as an interval itself
use constant LARGE_GAP_THRESHOLD => 20;



sub create { bless [], shift }

sub upper_bound {
  my $this = shift;
  @$this ? $this->[$#{$this}][1] : undef;
}

sub lower_bound {
  my $this = shift;
  @$this ? $this->[0][0] : undef;
}

sub bounds {
  my $this = shift;
  @$this or  die "interval was empty";
  ($this->[0][0],$this->[$#{$this}][1]);
}

sub total_length {
  my $this = shift;
  @$this or return 0;
  my $lo = $this->lower_bound;
  my $up = $this->upper_bound;
  $up - $lo + 1;
}

sub max_length {
  my $this = shift;
  @$this or return 0;
  my $m = 0;
  foreach ( @$this ) {
    my $l = $_->[1] - $_->[0] + 1;
    $m = $l if $l > $m;
  }
  $m;
}

sub average_length {
  my $this = shift;
  @$this or return 0;
  $this->assigned / (scalar @$this);
}

sub assigned {
  my $this = shift;
  @$this or return 0;
  my $m = 0;
  foreach ( @$this ) {
    my $l = $_->[1] - $_->[0] + 1;
    $m += $l;
  }
  $m;
}

sub total_gap_length {
  my $this = shift;
  @$this or return 0;
  my $g = 0;
  for ( my $i = 0; $i < $#{$this}; ) {
    my ($up,$lo) = ($this->[$i][1],$this->[++$i][0]);
    $g += ($lo - $up - 1) if $up < $lo - 1;
  }
  $g;
}

# add and grade any new interval not overlapping with an existing one
sub push {
  my $this = shift;
  foreach ( @_ ) {
    2 == @$_ or
      die "invalid argument: 2-element array expected";
    my ($lo,$up) = map(int, @$_);
    $lo <= $up or
      die "lower bound must be less or equal than upper bound";
    if ( 0 == @$this || $lo > $this->upper_bound ) {
      push @$this, [$lo,$up];
    } elsif ( $up < $this->lower_bound ) {
      unshift @$this, [$lo,$up];
    } else {
      my @t;
      foreach my $iv ( @$this ) {
        if ( defined $lo && $up <= $iv->[1] ) {
          #printf 'inserting(%04X,%04X)', $lo, $up;
          (@t and ($lo > $t[$#t][1] && $up < $iv->[0])) or
            die sprintf(
              "overlapping intervals detected while considering ".
              "iv=[%04X,%04X]: ".
              "[%04X,%04X] doesn't fit between %04X and %04X (t=%d).",
              $iv->[0],$iv->[1],
              $lo,$up,$t[$#t][1],$iv->[0],scalar @t);
          push @t, [$lo,$up];
          undef $lo;
        }
        push @t, $iv;
      }
      @$this = @t;
    }
  }
}


sub __split3 {
  my $this = shift;
  my ($sp) = @_;
#  print "## __split3($sp) step1\n";

  my @ret;
  my $c1 = 0;
  if ( $sp > 0 ) {
    my $iv1 = idna2::codegen::interval->create;
    for ( ; $c1 < $sp; $c1++ ) {
      $iv1->push($this->[$c1]);
    }
    CORE::push @ret, $iv1;
  }

#  print "## __split3($sp): $c1 step2\n";
  my $iv2 = idna2::codegen::interval->create;
  $iv2->push($this->[$c1++]);
  CORE::push @ret, $iv2;

#  print "## __split3($sp): $c1 step3\n";
  if ( $sp < $#{$this} ) {
    my $iv3 = idna2::codegen::interval->create;
    for ( ; $c1 <= $#{$this}; $c1++ ) {
      $iv3->push($this->[$c1]);
    }
    CORE::push @ret, $iv3;
  }

  \@ret;
}


# split by largest sub-interval (if it's greater than $threshold)
sub split_large_max {
  my $this = shift;
  my ($threshold) = @_;
  @$this > 1 or
    die "two sub-intervals are required at least";

  my $m = 0;
  my $cm;
  for ( my $c = 0; $c <= $#{$this}; $c++ ) {
    my $iv = $this->[$c];
    my $l = $iv->[1] - $iv->[0] + 1;
    if ( $l > $m ) {
      $m = $l;
      $cm = $c;
    }
  }
  return undef if $m <= $threshold;
  $this->__split3($cm);
}

# splity by first sub-interval larger than $threshold
sub split_large_first {
  my $this = shift;
  my ($threshold) = @_;
  @$this > 1 or
    die "two sub-intervals are required at least";

  my $cm;
  for ( my $c = 0; $c <= $#{$this}; $c++ ) {
    my $iv = $this->[$c];
    my $l = $iv->[1] - $iv->[0] + 1;
    if ( $l > $threshold ) {
      $cm = $c;
      last;
    }
  }
  return undef unless defined $cm;
  $this->__split3($cm);
}

# sub split2 {
#   my $this = shift;
#   @$this > 1 or
#     die "split2 expects at least 2 intervals";
#   my $iv1 = idna2::codegen::interval->create;
#   my $iv2 = idna2::codegen::interval->create;
#   if ( 2 == @$this ) {
#     $iv1->push($this->[0]);
#     $iv2->push($this->[1]);
#   } else {
#     #print "-split2: lower=".($this->lower_bound)."; upper=".($this->upper_bound)."\n";
#     my $t = $this->total_length;
#     my $t2 = $t / 2;
#     #print "-split2: t=$t; t2=$t2\n";
#     foreach my $iv ( @$this)
#     {
#       if ( $iv->[1] <= $t2 ) { # left
#         #print "-split2: $iv->[1] <= $t2 -> left\n";
#         $iv1->push($iv);
#       } elsif ( $iv->[0] >= $t2 ) { # right
#         #print "-split2: $iv->[0] >= $t2 -> right\n";
#         $iv2->push($iv);
#       } else {
#         my ($d1,$d2) = map { abs($iv->[$_] - $t2) } (0 .. 1);
#         #print "-split2: d1=$d1; d2=$d2\n";
#         if ( $d1 > $d2 ) {
#           $iv1->push($iv);
#         } else {
#           $iv2->push($iv);
#         }
#       }
#     }
#   }
#   #print "=split2: ".(scalar @$iv1)."; ".(scalar @$iv2)."\n";
#
#
#   if (0 == $iv1->total_length) {
#     my $iv = shift @$iv2;
#     push @$iv1, $iv;
#   }
#   elsif (0 == $iv2->total_length) {
#     my $iv = pop @$iv1;
#     unshift @$iv2, $iv;
#   }
#   die unless ($iv1->total_length > 0 && $iv1->total_length > 0);
#   ($iv1,$iv2);
# }

# large gaps (i.e. ranges of unassigned numbers) are considered as
# intervals as well (they have a null-result)
sub add_large_gaps {
  my $this = shift;
  @$this or return;

  my @add;
  my $lb = $this->[0][1]; # first upper bound
  foreach ( 1 .. $#{$this} ) {
    my $iv = $this->[$_];
    if ( $lb < $iv->[0] - (+LARGE_GAP_THRESHOLD) ) {
      my ($lo,$up) = ($lb + 1,$iv->[0] - 1);
      CORE::push @add, [$lo,$up];
    }
    $lb = $iv->[1];
  }
  $this->push(@add) if @add > 0;
}

sub add_gaps {
  my $this = shift;
  @$this or return;

  my @add;
  my $lb = $this->[0][1]; # first upper bound
  foreach ( 1 .. $#{$this} ) {
    my $iv = $this->[$_];
    if ( $lb < $iv->[0] -1 ) {
      my ($lo,$up) = ($lb + 1,$iv->[0] - 1);
      CORE::push @add, [$lo,$up];
    }
    $lb = $iv->[1];
  }
  $this->push(@add) if @add > 0;
}


# join neighboring intervals with equal result
sub join_equal {
  my $this = shift;
  my ($get_result) = @_;
  @$this or return;

  my @new;
  my $iv;
  for ( my $i = 0; $i <= $#{$this}; $i++ ) {
    $iv = $this->[$i];
    my $res = &$get_result($iv);
    my $ubound = undef;
    my $j = $i;
    while ( $j < $#{$this} && $res eq &$get_result($this->[++$j]) ) {
      $ubound = $this->[$j][1];
    }
    unless (defined $ubound) {
      CORE::push @new, $iv if $j < $#{$this};
      next;
    }
    $i = $j - 1;
    CORE::push @new, [$iv->[0],$ubound];
  }

  @$this = @new;
}

sub __range_debug {
  my ($lo,$up) = @_;
  '/* '.
    (sprintf '%04X',$lo).( ($up > $lo) ?
      ('..'.(sprintf '%04X',$up).' ('.($up - $lo + 1).')') : '').
  ' */'
}

# if-selector
sub __select_split {
  my $this = shift;
  my $sp = shift;
  #my (undef,undef,$param,$map) = @_;
  my %opt = @_;

  my @acc;
  my $lb;
  foreach ( 0 .. $#{$sp} ) {
    my $iv = $sp->[$_];
    my ($lo,$up) = $iv->bounds;
    my ($select);
    my $acc = $iv->__rec_create_accessor(@_);
    
    my $debug = &__range_debug($lo,$up);
    if ($_ == 0) { # first
      my $map_up = $opt{map} ? &{$opt{map}}($up) : $up;
      $select = qq{ ($opt{param}) <= $map_up };
    } elsif ($_ == $#{$sp}) { # last
      my $map_lo = $opt{map} ? &{$opt{map}}($lo) : $lo;
      $select = ($lb < $lo - 1) ? qq{ ($opt{param}) >= $map_lo } : 1;
    } else { # middle
      my @c;
      my ($map_lo,$map_up) = map { $opt{map} ? &{$opt{map}}($_) : $_ } ($lo,$up);
      CORE::push @c, qq{($opt{param}) >= $map_lo} if $lb < $lo - 1;
      CORE::push @c, qq{($opt{param}) <= $map_up};
      $select = join q/ && /, @c;
    }
    CORE::push @acc, $select, $acc, $debug;
    $lb = $up;
  }
  return [select => @acc];
}


sub create_accessor {
  my $this = shift;
  #my (undef,undef,$param,$map) = @_;
  my %opt = @_;
  my ($lo,$up) = $this->bounds;

  my ($acc);
  if ( defined (my $sp = $this->split_large_first(
      $opt{split_large_first})) ) {
    #return $this->__select_split($sp, @_);
    $acc = $this->__select_split($sp, @_);
  } else {
    $acc = $this->__rec_create_accessor(@_);
  }
  #my $acc = $this->__rec_create_accessor(@_);
  
  return [select => qq( (($opt{param}) <= $up) ) => $acc];
}

sub __rec_create_accessor {
  my $this = shift;
  #my ($get_result,$create_array,$param,$map) = @_;
  my %opt = @_;

  # create direct accessor for single result
  if ( 1 == @$this ) {
    return [result => &{$opt{get_result}}($this->[0]),
      &__range_debug($this->[0][0],$this->[0][1])];
#     return [result => &$get_result($this->[0]),
#       &__range_debug($this->[0][0],$this->[0][1])];
  }

  # create if-selector for large intervals
  if ( defined (my $sp = $this->split_large_max(
      $opt{split_large_max})) ) {
    return $this->__select_split($sp, @_);
  }
  
  # create array accessor
  my @a;
  my ($lo,$up) = $this->bounds;
  my $debug = &__range_debug($lo,$up);
  my $map_lo = $opt{map} ? &{$opt{map}}($lo) : $lo;
  my $index = ($lo > 0) ? qq{ ($opt{param})-$map_lo } : $opt{param};
  my $i = $lo;
  foreach ( @$this ) {
    my ($lo,$up) = @$_;
    my $r = &{$opt{get_result}}($_);
    for ( ; $i <= $up; $i++) {
      CORE::push @a, ($i >= $lo ? $r : 0);
    }
  }
  my $array = &{$opt{create_array}}(\@a);
#   if (defined $first_array) {
#     unless ( @$first_array ) {
#       @$first_array = ($up, $array, $debug);
#     }
#   }
  return [access => $index, $array, $debug];



  #return [access => $sel,\@a];



#   }
#
#   my ($iv1,$iv2) = $this->split2;
#   print "split2: ".(scalar @$iv1)."; ".(scalar @$iv2)."\n";
#
#   my ($up1,$lo2) = ($iv1->upper_bound, $iv2->lower_bound);
#   my $acc1 = $iv1->__rec_create_accessor($get_result);
#   my $acc2 = $iv2->__rec_create_accessor($get_result);
#   my $sel1 = "(p)<=$up1";
#   my $sel2 = ($lo2 > $up1 + 1) ? "(p)>=$lo2" : 1;
#   return [select => ($sel1 => $acc1, $sel2 => $acc2)];

}





# debug
sub to_string {
  my $this = shift;
  my $sz = @$this;
  my $tl = $this->total_length;
  my $ml = $this->max_length;
  my ($lo,$up) = map { sprintf '%04X', $_ } ($this->lower_bound, $this->upper_bound);
  "[$sz] ($lo .. $up) total=$tl, max=$ml";
}















1;
