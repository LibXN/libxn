## code.pm - A Perl library for generating C/C++ source code.
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
package main;
BEGIN {
  use Cwd qw(abs_path);
  use File::Spec;
  use File::Basename;
  use Sys::Hostname;

  ## path and filename constants
  use constant gen_dir => 'gen';
  use constant gen_src_dir => 'gen/src';
  use constant build_dir => 'lib';
  #use constant build_test_dir => 'test';
  use constant source_list => 'sources.txt';
  use constant target_dir => gen_dir . '/tmp';
  use constant source_dir => gen_dir . '/sources';
  use constant ucdata_h => 'ucdata.h';
  use constant ucdata_c => 'ucdata.c';
  

  ## absolute path setup
  my $script_path = abs_path($0);
  my $script_name = basename($script_path);
  my (undef,$base_dir) = fileparse(dirname($script_path));

  sub getpath {
		File::Spec->catdir($base_dir,@_)
	}

  ## path functions
  sub SCRIPT_NAME { $script_name }
  sub SCRIPT_PATH { &getpath(gen_dir,@_) }
  sub SCRIPT_SRC_PATH { &getpath(gen_src_dir,@_) }
  sub SOURCE_LIST { &getpath(gen_dir,source_list) }
  sub SOURCE_PATH { &getpath(source_dir,@_) }
  
  sub BUILD_PATH { &getpath(build_dir,@_) }
  #sub BUILD_TEST_PATH { &getpath(build_test_dir,$_[0]) }

  sub UCDATA_H { &getpath(gen_dir,ucdata_h) }
  sub UCDATA_C { &getpath(gen_dir,ucdata_c) }
  #sub UCD_SCRIPTS_H { &getpath(gen_dir,q/ucd_scripts.h/) }
  
  sub GEN_PATH { &getpath(target_dir,@_) }
  
  sub build_rel_path {
    File::Spec->abs2rel($_[0],+BUILD_PATH);
  }

  
  ## logger
  #sub LOG { local $\ = "\n"; local $, = ' ', print "[".(shift)."]", @_ }
}

use constant C_INDENT => "  ";

use constant CPP_BEGIN => '#ifdef __cplusplus

#ifndef X__public_enum
#define X__public_enum enum
#endif

';
use constant CPP_END => '#endif';

use constant CPP_NAMESPACE_BEGIN => '
namespace IDNA2 {
  namespace Unicode {';
  
use constant CPP_NAMESPACE_END => '
  }
}';

use constant CPP_ENUM_BEGIN => '___public_enum';
use constant CPP_ENUM_END => '';

use constant C_ENUM_BEGIN => 'enum';
use constant C_ENUM_END => '';

#our (%GENERATING);

sub LOG(@);


sub require_source {
  my ($name) = @_;
  my $src = +SOURCE_LIST;
  my ($p);
  open my $fh, '<', $src or die "$src: ".$!;
  for (my $lno = 1; <$fh>; $lno++) {
    my ($id,$fn,$uri,$comment) = split /;/;
    if ($id eq $name) {
      $p = +SOURCE_PATH $fn;
      
#       unless ( -f $p ) {
#         LOG(__FILE__, "local source not found.");
#         if ( $uri =~ /\S/ ) {
#           LOG __FILE__, "attempting to fetch $uri ...";
#           system qq{wget --output-document="$p" $uri};
#           die "faild to fetch source from $uri" if $?;
#         }
#       }
      -f $p or
        die "missing source file: $p (as refered in: $src, line $lno)";
      my $sz = -s $p;
      LOG(__FILE__, sprintf "found source '%s' (%d bytes)", $p, -s $p);
      last;
    }
  }
  close $fh;
  $p or
    die "required source was not found in $src: '$name'";
  $p;
}

sub read_table {
  my ($name,$readline) = @_;
  my $f = require_source($name);
  open my $fh, '<', $f or die "$f: " . $!;
  for (my $lno = 1; <$fh>; $lno++) {
    chomp;
    my @s = split /;/;
    foreach ( @s ) { s/^\s+//; s/\s+$// }
    &$readline(@s) or
      die "line $lno of $f not understood";
  }
  close $fh;
}

sub c_comment {
  "/*\n  " . $_[0] . "\n  */\n";
}

sub c_doc {
  my $indent = shift;
  join "\n",
  $indent . '/// <summary>',
  (map { $indent . '/// <para>' . $_ . '</para>' } @_),
  $indent . '/// </summary>';
}

sub c_uint {
  $_[0] > 9 ? sprintf q/0x%X/ => int($_[0]) : int($_[0]);
}

sub c_create_accessor {
  my ($acc,$stats,$depth) = @_;
  $depth or $depth = 0;
  $stats->{max_depth} = $depth
    if $depth > int(defined $stats->{max_depth} ? $stats->{max_depth} : 0);
  my $ret = '';
  my $in = '  ' x $depth;
  my $cmnd = shift @$acc;
  if ($cmnd eq q/result/) {
    my $res = shift @$acc;
    my $debug = shift @$acc;
    $ret .= $in."return($res); $debug\n";
    $stats->{leave_count}++;
  } elsif ($cmnd eq q/access/) {
    my $p = shift @$acc;
    my $a = shift @$acc;
    defined $a or return $ret;
    my $debug = shift @$acc;
    $ret .= $in."return(".$a->accessor($p)."); $debug\n";
    $stats->{leave_count}++;
  } elsif ($cmnd eq q/select/) {
    my $i = 0;
    while (@$acc) {
      my $c = shift @$acc;
      my $p = shift @$acc;
      my $debug = shift @$acc;
      my $s = '';
      $s .= qq{else } if $i > 0;
      $s .= qq{if($c) } if $c ne q|1|;
      $stats->{branch_count}++;
      $ret .= $in."$s {";
      $ret .= " $debug" if defined $debug;
      $ret .= "\n";
      $ret .= &c_create_accessor($p,$stats,$depth + 1);
      $ret .= $in."}";
      $ret .= " $debug" if defined $debug;
      $ret .= "\n";
      $i++;
    }
  }
  $ret;
}


sub c_enum_begin {
  my ($name,$comment) = @_;
  join "\n",
  "#ifdef __cplusplus\n",
  "#ifndef X__public_enum",
  "#define X__public_enum enum",
  "endif\n",
  "namespace IDNA2 {",
  +C_INDENT . "namespace Unicode {\n",
  (+C_INDENT x 2) . "/// <summary>",
  (map { (+C_INDENT x 2) . "/// <para>$_</para>" } (split /\n/, $comment)),
  (+C_INDENT x 2) . "/// </summary>",
  (+C_INDENT x 2) . "X__public_enum $name {";
}

sub c_enum_entry {
  my ($name,$value,$comment) = @_;
  join "\n",
  (+C_INDENT x 3) . "/// <summary>",
  (map { (+C_INDENT x 3) . "/// <para>$_</para>" } (split /\n/, $comment)),
  (+C_INDENT x 3) . "/// </summary>",
  (+C_INDENT x 3) . $name.' = '.$value;
}

sub c_enum_end {
  join "\n",
  '',
  (+C_INDENT x 2) . "}",
  +C_INDENT . "}",
  "}",
  "#endif\n";

}

# sub c_enum
# {
#   my ($name, $enum) = @_;
#   join "\n",
#   "#ifdef __cplusplus\n",
#   "namespace IDNA2 {",
#   +C_INDENT . "namespace Unicode {",
#   (+C_INDENT x 2) . "X__public_enum $name {",
#   (join ",\n", map {
#       (+C_INDENT x 3) . $_.' = '.$enum->{$_}
#     } sort { $enum->{$a} <=> $enum->{$b} }  keys %$enum),
#   (+C_INDENT x 2) . "}",
#   +C_INDENT . "}",
#   "}",
#   "#endif\n";
# }

sub print__c_source_preamble {
  my ($fh, $name) = @_;
  my $generator = +SCRIPT_NAME;
  my $now = scalar gmtime;
  my $host = &hostname;
  print $fh <<HERE;
/* "$name"
 * Copyright (C) 2011 Sebastian Böthin.
 *
 * Project home: <http://www.LibXN.org>
 * Author: Sebastian Böthin <sebastian@boethin.eu>
 *
 * This file is part of LibXN.
 *
 * LibXN is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * LibXN is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with LibXN.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
/* Generated File.
      --> Do not edit this file, edit the generator instead. <--
  \@ $host [$now]
*/
HERE
}

sub c_create_file {
  my ($gen_path,$build_path) = @_;
  
}

sub c_open_header {
  my ($caller,$path) = (shift,shift);
  my $fn = basename($path);
  my $hdef = '__'.qq/\U$fn/.'__';
  $hdef =~ s/[^A-Z0-9]/_/g;
  LOG $caller, "generating header:", qq("$fn");
  open my $fh, '>', $path or die $!;
  print__c_source_preamble($fh, $fn);
  print $fh <<HERE;
#pragma once
#ifndef $hdef
#define $hdef

HERE
  $fh;
}

sub c_close_header {
  my ($fh) = @_;
print $fh <<HERE;

#endif
/* end of generated file */
HERE
  close $fh;
}


sub c_open_source {
  my ($caller,$path) = (shift,shift);
  my @header = @_;
  push @header, q(stddef.h);
  my $fn = basename($path);
  LOG $caller, "generating source:", qq("$fn");
  open my $fh, '>', $path or die $!;
  print__c_source_preamble($fh, $fn);
print $fh <<HERE;
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef WIN32
#include "config.win32.h"
#endif

HERE
  foreach ( @header ) {
    print $fh qq(#include <$_>), "\n";
  }
  print $fh <<HERE;

#include "xn.h"

HERE
  $fh;
}

sub c_close_source {
  my ($fh) = @_;
print $fh <<HERE;


/* end of generated file */
HERE
  close $fh;
}

sub c_include {
	my ($caller,$path,$fh) = (shift,shift,shift);
  my %repl = @_;
  -f $path or die "file not found: '$path'";
  LOG $caller, sprintf "including %s (%d bytes).",
		File::Spec->abs2rel($path,+SCRIPT_PATH), -s $path;
  open my $fh_in, '<', $path or die $!;
  my $n = basename($path);
  print $fh qq[\n/* ---- BEGIN "$n" ---- */\n];
  print $fh '#line 1 "', build_rel_path($path), '"', "\n";
  while ( <$fh_in> ) {
    foreach my $k ( keys %repl ) { s/\/\*===\s+$k\s+===\*\//$repl{$k}/g  }
    print $fh $_;
  }
  close $fh_in;
  print $fh qq[\n/* ---- END "$n" ---- */\n\n];
}

# sub c_generated {
#   my ($path) = @_;
#   my $sz;
#   (-f $path && ($sz = -s $path)) or
#     die "file '$path' is missing or has zero size";
#   my $name = basename($path);
#   LOG __FILE__, "generated: $path ($sz bytes),";
#   # TOD:
#   # move to source dir
#   }


1;
