#!/usr/bin/perl

use strict;
use warnings;

=pod

=head1 NAME

estimate.pl - Estimate disk space for a playlist

=head1 SYNOPSIS

B<estimate.pl> [I<playlist>]

=head1 DESCRIPTION

Opens up the iTunes music library in the user's home directory and
attempts to find the named I<playlist>.  Prints an estimate of the
amount of disk space consumed by items in that playlist.

If I<playlist> is not specified, it defaults to C<vwTunes>.

=cut

use File::Spec;
use Mac::iTunes::Library::XML;

my $pln = $ARGV[0] || 'vwTunes';
my $homedir = (getpwuid($<))[7];
my $libxml = File::Spec->catfile($homedir, 'Music', 'iTunes', 'iTunes Music Library.xml');
print "Parsing...\n";
my $ituneslib = Mac::iTunes::Library::XML->parse($libxml);
my %pls = $ituneslib->playlists();
my @plk = grep { $pls{$_}->name() eq $pln } keys %pls;
my @pl = $pls{$plk[0]}->items();
print "Estimating...\n";
my $gnupodlib = Mac::iTunes::Library->new();
for my $item (@pl)
{
	$gnupodlib->add($item);
}
printf("%d songs, %0.1f GiB\n", $gnupodlib->num(), $gnupodlib->size() / 1_000_000_000.0 );

__END__

=pod

=head1 BUGS

Possibly needs to be re-educated about where iTunes libraries are
typically found under the user's home directory.

=head1 SEE ALSO

L<Mac::iTunes::Library>

=head1 AUTHOR

Tony Monroe

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Tony Monroe.

GNU General Public License version 3 L<http://www.gnu.org/licenses/gpl.html>

=cut
