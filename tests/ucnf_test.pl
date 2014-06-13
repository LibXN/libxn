#!/usr/bin/perl -w
#
# Unicode Normalization Test Suite
#
# get the latest NormalizationTest.txt from_
#   http://www.unicode.org/Public/UNIDATA/NormalizationTest.txt
#
use strict;

our ($Exec,$Source,%Done,$Verbose);
local (*SRC, *PROG_OUT, *PROG_IN);

BEGIN {
  require Cwd;
  require File::Spec;
  require File::Basename;

  @ARGV >= 2 or die "usage: $0 <command> <source> [-v]\n";

  $Exec = File::Spec->catdir(
  	File::Basename::dirname(Cwd::abs_path($0)),shift @ARGV);
  -x $Exec or die "not executable: '$Exec'";

  $Source = shift @ARGV;
  -f $Source or die "source file doesn't exist: '$Source'";

  $Verbose = 0;
}

use IPC::Open2;

open2(\*PROG_OUT,\*PROG_IN, $Exec) or
  die "cannot open2 '$Exec': $!";

# 1E0A;1E0A;0044 0307;1E0A;0044 0307; #
my $re_test = qr/^([0-9A-F; ]+);\s+#/;

print "Unicode Normalization Test Suite:\n";
open SRC, '<', $Source or die $!;
print scalar <SRC> foreach (1 .. 8);
for (my $lno = 1; <SRC>; $lno++)
{
  chomp;
  m/$re_test/ or next;
  my @p = split /;/, $1;

  # Normalization Test Suite
  # Format:
  #
  #   Columns (c1, c2,...) are separated by semicolons
  #   They have the following meaning:
  #      source; NFC; NFD; NFKC; NFKD
  #   Comments are indicated with hash marks
  #   Each of the columns may have one or more code points.
  #
  # CONFORMANCE:
  # 1. The following invariants must be true for all conformant implementations
  #
  #    NFC
  #      c2 ==  toNFC(c1) ==  toNFC(c2) ==  toNFC(c3)
  #      c4 ==  toNFC(c4) ==  toNFC(c5)
  #
  #    NFD
  #      c3 ==  toNFD(c1) ==  toNFD(c2) ==  toNFD(c3)
  #      c5 ==  toNFD(c4) ==  toNFD(c5)
  #
  #    NFKC
  #      c4 == toNFKC(c1) == toNFKC(c2) == toNFKC(c3) == toNFKC(c4) == toNFKC(c5)
  #
  #    NFKD
  #      c5 == toNFKD(c1) == toNFKD(c2) == toNFKD(c3) == toNFKD(c4) == toNFKD(c5)
  #
  # 2. For every code point X assigned in this version of Unicode that is not specifically
  #    listed in Part 1, the following invariants must be true for all conformant
  #    implementations:
  #
  #      X == toNFC(X) == toNFD(X) == toNFKC(X) == toNFKD(X)
  #

  5 == scalar @p or die "line format not understood: '$_'";
  my @c = map { [ map(hex,(split / /)) ] } @p;

  ## c2 ==  NFC(c1)
  &run_test($lno, qw/C c1 c2/,$c[0],$c[1]);

  ## c2 ==  NFC(c2)
  &run_test($lno, qw/C c2 c2/,$c[1],$c[1]);

  ## c2 ==  NFC(c3)
  &run_test($lno, qw/C c3 c2/,$c[2],$c[1]);

  ## c4 ==  NFC(c4)
  &run_test($lno, qw/C c4 c4/,$c[3],$c[3]);

  ## c4 ==  NFC(c5)
  &run_test($lno, qw/C c5 c4/,$c[4],$c[3]);



  ## c3 ==  NFD(c1)
  &run_test($lno, qw/D c1 c3/,$c[0],$c[2]);

  ## c3 ==  NFD(c2)
  &run_test($lno, qw/D c2 c3/,$c[1],$c[2]);

  ## c3 ==  NFD(c3)
  &run_test($lno, qw/D c3 c3/,$c[2],$c[2]);

  ## c5 ==  NFD(c4)
  &run_test($lno, qw/D c4 c5/,$c[3],$c[4]);

  ## c5 ==  NFD(c5)
  &run_test($lno, qw/D c5 c5/,$c[4],$c[4]);


  ## c5 ==  NFKD(c1)
  &run_test($lno, qw/KD c1 c5/,$c[0],$c[4]);

  ## c5 ==  NFKD(c2)
  &run_test($lno, qw/KD c2 c5/,$c[1],$c[4]);


  ## c4 ==  NFKC(c1)
  &run_test($lno, qw/KC c1 c4/,$c[0],$c[3]);

}
printf "OK: %d test cases.\n", (scalar keys %Done);
close SRC;

close PROG_IN;
exit 0;


sub run_test {
  my ($lno, $nf, $c1, $c2, $arg, $exp) = @_;
  my $in = join ' ', map { sprintf '%04X' => $_ } @$arg;
  my $in_l = scalar @$arg;
  my $input = qq($nf $in_l $in);
  return if $Done{$input};
  $Done{$input} = 1;
  
  print "[$lno] $c2 == NF$nf($c1): '$input' " if $Verbose;
  print PROG_IN "$input\n";
  
  my $res = <PROG_OUT>;
  defined $res or die "failed: '$Exec'";
  chomp $res;
  
  print " -> '$res'" if $Verbose;
  $res =~ s/^(YES|NO|MAYBE)\s+([0-9A-F ]+)$/$2/ or
    die "response not recognized";
  my $qc = $1;
  
  # check result
  my @res = map(hex, (split / /, $2));
  unless (&equals(\@res,$exp)) {
    die "result doesn't match.";
  }

  # check quickcheck result
  if ($qc ne q|MAYBE|) {
    my $is = &equals(\@res,$arg);
    if (($is && $qc eq q|NO|) || (!$is && $qc eq q|YES|)) {
      die "wrong quickcheck result";
    }
  }
  
  print " OK\n" if $Verbose;
}

sub equals {
  my ($s1,$s2) = @_;
  return 0 unless scalar @$s1 == scalar @$s2;
  for (my $i = 0; $i <= $#{$s1}; $i++) {
    return 0 if $s1->[$i] != $s2->[$i];
  }
  1;
}

__END__
