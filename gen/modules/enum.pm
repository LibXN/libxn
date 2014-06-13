package Idna2::Code::enum;
use strict;

sub create {
  my $class = shift;
  my %this = @_;
  $this{values} = [];
  bless \%this, $class;
}

sub push {
  my $this = shift;
  push @{$this->{values}}, @_;
}

sub length {
  my $this = shift;
  scalar @{$this->{values}};
}

sub c_decl {
  my $this = shift;
  join "\n",
  main::C_ENUM_BEGIN . qq| $this->{c_name}|,
  '{',
  (join ",\n", (map {
    main::C_INDENT . qq|$_->{c_name} = $_->{value}| .
    (defined $_->{help} ? ' /* '.( join ' ', map {
			defined $_ ? $_ : '' } @{$_->{help}} ).' */' : '' )
    } @{$this->{values}})),
  '};',
  main::C_ENUM_END;
}

sub cpp_decl {
  my $this = shift;
  
  # cpp disabled
  return '';
  
  join "\n",
  main::CPP_BEGIN,
  main::CPP_NAMESPACE_BEGIN, "\n",
  (main::C_INDENT x 2) .
    main::CPP_ENUM_BEGIN . qq| $this->{cpp_name}|,
  (main::C_INDENT x 2) . "{\n",
  (join ",\n\n", (map {
    main::c_doc((main::C_INDENT x 3), @{$_->{help}}) . "\n" .
    (main::C_INDENT x 3) .
      qq|___enum_member($this->{cpp_name},$_->{cpp_name}) = $_->{value}| } @{$this->{values}})),
  (main::C_INDENT x 2) . "};\n",
  main::CPP_ENUM_END,
  main::CPP_NAMESPACE_END,
  main::CPP_END;
}

1;
