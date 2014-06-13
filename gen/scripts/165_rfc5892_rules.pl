##
## rfc5892 Contextual Rules Registry
##
## @write: "rfc5892_rules.c"
our ($RE_codepoint, $RE_codepoint_interval);
package main;
use strict;
{

  my $rules_c = c_open_source(__FILE__, +GEN_PATH("rfc5892_rules.c"));
  print $rules_c <<HERE;
  
#include "rfc5892_rules.h"

/*
  Contextual Rules Registry
  see: http://tools.ietf.org/html/rfc5892#appendix-A
*/
HERE

  my @registry;

  # read rules from rfc 5892
  my $re_start = qr/^Appendix A\.\s+Contextual Rules Registry/;
  my $re_end = qr/^Appendix B\./;

  my $re_rule_header = qr/Appendix (A\.\d+\.\s+[A-Z0-9\(\)\s\-]+)$/;
  my $re_rule_range = qr/^\s*U\+($RE_codepoint)|($RE_codepoint)\.\.($RE_codepoint)/;
  
  my $re_lookup = qr/\s+(True|False)/;

  my $buf;

  my $started = 0;
  my $src = require_source(q/RFC5892/);
  open my $src_h, '<', $src or die $!;
  my ($lno);
  for ($lno = 1; <$src_h>; $lno++) {
    chomp;
    unless ( $started )
    {
      /$re_start/ or next;
      $started = 1;
    }
    last if /$re_end/;
    
    /$re_rule_header/ or next;
    my $rule_name = $1;
    $rule_name =~ s/\s+/ /g;
    
    my $rule_var = q|rfc5892__|.(lc $rule_name);
    for ($rule_var) {
      s/[ \-]/_/g;
      s/[^a-z0-9_]//g;
    }
    
    my ($lo,$up,$lookup);
    for ( ; <$src_h>; $lno++) {
      chomp;

      if (/Code point:/) {
        # Code point:
        #       U+200C
        my $next = <$src_h>;
        $next =~ m/$re_rule_range/ or
          die "Code point range not recognized for '$rule_name'";
        if (defined $2) { ($lo,$up) = (hex($2),hex($3)); }
        else { $lo = $up = hex($1); }
        next;
      }
      
      if (/Lookup:/) {
        # Lookup:
        #       True
        my $next = <$src_h>;
        $next =~ m/$re_lookup/ or
          die "Lookup switch not recognized for '$rule_name'";
        $lookup = ($1 eq q|True|) ? 1 : 0;
        next;
      }
      
      last if defined($lo) && defined($lookup);
      
    }
    
    #LOG __FILE__, "rfc5892 rule: '$rule_name' -> $rule_var (lookup: $lookup) ", cp_range($lo,$up);
    
    my @crec = (
      q(lo:).(sprintf '0x%X',$lo),
      q(up:).(sprintf '0x%X',$up),
      qq(rule:&$rule_var),
      qq(name:"$rule_name"),
      qq(lookup:$lookup),
    );
    
    push @registry, {
#       lo => $lo,
#       up => $up,
#       name => $rule_name,
      rule => $rule_var,
      crec => join ',', @crec,
    };

  }
  close $src_h;
  my $rule_count = scalar @registry;

  ## c decl
  print $rules_c '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $rules_c <<HERE;

/* contextual rule signature */
typedef rfc5892_context_result
  (*rfc5892rule)(const ucd_record[],size_t,size_t);

/* rule data */
struct RFC5892_RULE
{
  codepoint_t lo;
  codepoint_t up;
  rfc5892rule rule;
  const char *name;
  char lookup;
};

static const struct RFC5892_RULE registry[$rule_count];

HERE

  ## include c proc
  #my $inc = +SCRIPT_SRC_PATH ("rfc5892_rules.in.c");
  c_include(__FILE__, +SCRIPT_SRC_PATH ("rfc5892_rules.in.c") => $rules_c,
		RULE_COUNT => $rule_count);
  
  ## include all the rules
  foreach my $r ( @registry )
  {
    #my $inc = +SCRIPT_SRC_PATH ("$r->{rule}.in.c");
    c_include(__FILE__, +SCRIPT_SRC_PATH ("$r->{rule}.in.c") => $rules_c);
  }

  print $rules_c "\n";

  ## the registry
  print $rules_c '#line ', __LINE__, ' "', build_rel_path(__FILE__), '"', "\n";
  print $rules_c "/* the registry */\n";
  print $rules_c qq(static const struct RFC5892_RULE registry[]={\n).(
    join ",\n", map {
      qq({$_->{crec}})
    } @registry
  ).qq(};\n);

  ## done with "rfc5892_rules.c"
  c_close_source($rules_c);

}

1;
