#!/usr/bin/perl

use strict;
use warnings;

=pod

=head1 NAME

extract.pl - Display list of files in a playlist in the iTunes library

=head1 SYNOPSIS

B<extract.pl> I<playlist>

=head1 DESCRIPTION

Walks through the user's iTunes library and attempts to display the
names of all the media files in I<playlist>.

I<playlist> defaults to C<vwTunes>.

=cut

use File::Spec;
use Mac::iTunes::Library::XML;
use URI;

my $pln = $ARGV[0] || 'vwTunes';
my $homedir = (getpwuid($<))[7];
my $libxml = File::Spec->catfile($homedir, 'Music', 'iTunes', 'iTunes Music Library.xml');
my $ituneslib = Mac::iTunes::Library::XML->parse($libxml);
my %pls = $ituneslib->playlists();
my @plk = grep { $pls{$_}->name() eq $pln } keys %pls;
my @pl = $pls{$plk[0]}->items();
for my $item (@pl)
{
	my $u = URI->new($item->location());
	print $u->file, "\n";
}

__END__

=pod

=head1 BUGS

Possibly obsolete.

=head1 SEE ALSO

L<Mac::iTunes::Library>

=head1 AUTHOR

Tony Monroe

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Tony Monroe.

GNU General Public License version 3 L<http://www.gnu.org/licenses/gpl.html>

=cut
