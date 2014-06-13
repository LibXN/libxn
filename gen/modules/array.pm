package idna2::codegen::array;
use strict;

sub create {
  my $class = shift;
  my %this = @_;
  $this{array} = [];
  bless \%this, $class;
}

sub push {
  my $this = shift;
  push @{$this->{array}}, @_;
}

sub set {
  my $this = shift;
  my $p = shift;
  $this->{array}[$p] = shift;
}

sub length {
  my $this = shift;
  scalar @{$this->{array}};
}

# Shannon entropy
sub entropy {
  my $this = shift;
  
  my %h;
  foreach ( @{$this->{array}} ) {
    exists $h{$_} or $h{$_} = 0;
    $h{$_}++;
  }
  my $e = 0;
  my $len = scalar @{$this->{array}};
  foreach ( keys %h ) {
    my $a = $h{$_} / $len;
    $e -= $a * log($a)
  }
  $e / log(2);
}

sub decl {
  my $this = shift;
  my $len = $this->length;
  qq{static const $this->{type} $this->{name} [$len];};
}

sub accessor {
  my $this = shift;
  my ($param) = @_;
  qq{$this->{name} [$param]};
}

sub def {
  my $this = shift;
  my ($map) = @_;
  $map or $map = sub { $_[0] };
  my @l;
  my $s = '';
  foreach ( @{$this->{array}} ) {
    $s .= ',' if CORE::length $s;
    $s .= &$map(defined $_ ? $_ : 0);
    if ( (CORE::length $s) > 80 ) {
      CORE::push @l, $s;
      $s = '';
    }
  }
  CORE::push @l, $s if $s;
  qq{static const $this->{type} $this->{name}}.
    qq/[]= {\n/.(join ",\n", @l).qq/\n};/;
};

1;
