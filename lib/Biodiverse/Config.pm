#!/usr/bin/perl -w

package Biodiverse::Config;

use strict;
use warnings;

use English ( -no_match_vars );

our $VERSION = '0.16';

#use Exporter;
#use Devel::Symdump;

our @ISA = qw (Exporter);
our @EXPORT = qw /use_base add_lib_paths/;
#our %base_packages;

use Carp;
use Data::Dumper qw /Dumper/;

#  update interval for progress bars
our $progress_update_interval     = $ENV{BIODIVERSE_PROGRESS_INTERVAL} || 0.3;
our $progress_update_interval_pct = $ENV{BIODIVERSE_PROGRESS_INTERVAL_PCT} || 5;

our $license = << 'END_OF_LICENSE'
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

For a full copy of the license see <http://www.gnu.org/licenses/>.
END_OF_LICENSE
  ;

#  add biodiverse lib paths so we get all the extensions
#  should be a sub not a begin block
sub add_lib_paths {
    my $var = shift;

    if (! defined $var) {
        $var = 'BIODIVERSE_LIB';
    }

    my @lib_paths;

    #  set user defined libs not collected by the perl interpreter,
    #  eg when using the perlapp exe file
    if ( defined $ENV{$var} ) {
        my $sep = q{:};    #  path list separator for *nix systems

        if ( $OSNAME eq 'MSWin32' ) {
            $sep = q{;};
        }
        push @lib_paths, split $sep, $ENV{$var};
    }

    print "Adding $var paths\n";
    print join q{ }, @lib_paths, "\n";

    #no warnings 'closure';
    eval 'use lib @lib_paths';

    return;
}

#  load all the relevant user defined libs into their respective packages
sub use_base {
    my $file = shift;
    my $use_envt_var;
    if (!defined $file) {
        if (exists $ENV{BIODIVERSE_EXTENSIONS}
            && ! $ENV{BIODIVERSE_EXTENSIONS_IGNORE}) {
            $file = $ENV{BIODIVERSE_EXTENSIONS};
            $use_envt_var = 1;
        }
        else {
            print "[USE_BASE] No user defined extensions\n";
            return;
        }
    }
    my %check_packages;

    print "[USE_BASE] Checking and loading user modules";
    my $x;
    if (-e $file) {
        print " from file $file\n";
        local $/ = undef;
        my $success = open (my $fh, '<', $ENV{BIODIVERSE_EXTENSIONS});
        croak "Unable to open extensions file $ENV{BIODIVERSE_EXTENSIONS}\n"
            if ! $success;

        $x = eval (<$fh>);
        carp $EVAL_ERROR if $EVAL_ERROR;;
        close ($fh);
    }
    elsif ($use_envt_var) {
        print " directly from environment variable\n";
        $x = eval "$ENV{BIODIVERSE_EXTENSIONS}";
        #warn $EVAL_ERROR if $EVAL_ERROR;;
    }
    if ($EVAL_ERROR) {
        warn "[USE_BASE] Problems with environment variable BIODIVERSE_EXTENSIONS - check the filename or syntax\n";
        warn $EVAL_ERROR;
        warn "$ENV{BIODIVERSE_EXTENSIONS}\n";
        return;
    }
    @check_packages{keys %$x} = values %$x if (ref $x) =~ /HASH/;

    foreach my $package (keys %check_packages) {
        my @packs = @{$check_packages{$package}};
        my $pack_list = join (q{ }, @packs);
        my $cmd = "package $package;\n"
                . "use base qw/$pack_list/;";
        #print "$cmd\n";
        eval $cmd;
        warn $EVAL_ERROR if $EVAL_ERROR;
    }

    return;
}

1;


__END__

=head1 NAME

Biodiverse::Config


=head1 DESCRIPTION

Configuration for the Biodiverse modules.

See http://purl.oclc.org/biodiverse for more details.

=head1 SYNOPSIS

  use Biodiverse::Config qw /use_base add_lib_paths/;
  BEGIN {
      add_lib_paths();
      use_base();
  }

=head1 METHODS and VARIABLES

=over

=item add_lib_paths()

Add the paths specified in C<$ENV{BIODIVERSE_LIB}> to @INC.
Also adds the Biodiverse lib folder if needed (using C<../lib>).

=item use_base()

Load user defined libs into the modules specified in the control file
specified in C<$ENV{BIODIVERSE_EXTENSIONS}>.
Set C<$ENV{BIODIVERSE_EXTENSIONS_IGNORE}> to 1 to not load the extensions.

=item my $update_interval = $Biodiverse::Config::progress_update_interval

Update frequency for the progress dialogue in the GUI.  Default is 0.3.

=back

=head1 AUTHOR

Shawn Laffan

=head1 License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

For a full copy of the license see <http://www.gnu.org/licenses/>.

=cut

