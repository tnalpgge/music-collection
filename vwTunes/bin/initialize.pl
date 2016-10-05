#!/usr/bin/perl

use strict;
use warnings;

=pod

=head1 NAME

initialize.pl - create an empty iPod-like directory structure on removable media

=head1 SYNOPSIS

=head1 DESCRIPTION

Create a new, "empty" directory structure imitating that of an iPod
under the directory I<mountpoint>.  May be used later by other
programs in this suite.

I<mountpoint> defaults to the value of the environment variable
C<IPOD_MOUNTPOINT> if present, otherwise the directory C<mnt/iPod>
under the user's home directory.

=cut

use File::Path qw(make_path remove_tree);
use File::Spec;
use Mac::iPod::GNUpod;

my $mnt = $ARGV[0] || 
    $ENV{'IPOD_MOUNTPOINT'} || 
    File::Spec->catfile((getpwuid($<))[7], "mnt", "iPod");

remove_tree($mnt);
make_path($mnt);
my $ipod = Mac::iPod::GNUpod->new(mountpoint => $mnt);
$ipod->init();
$ipod->read_gnupod();
$ipod->write_gnupod();
$ipod->write_itunes(name => 'vwTunes');

__END__

=pod

=head1 BUGS

Possibly obsolete.

=head1 SEE ALSO

L<Mac::iPod::GNUpod>

=head1 AUTHOR

Tony Monroe

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Tony Monroe.

GNU General Public License version 3 L<http://www.gnu.org/licenses/gpl.html>

=cut
