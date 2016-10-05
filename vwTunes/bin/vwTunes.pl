#!/usr/bin/perl

use strict;
use warnings;

=pod

=head1 NAME

vwTunes.pl - Make playlists so that removable media can attempt to imitate iPod

=head1 SYNOPSIS

B<vwTunes.pl> [I<mountpoint>]

=head1 DESCRIPTION

Reads the iPod-like directory structure under I<mountpoint>.  Writes
out a bunch of C<.m3u> playlist files so that removable media can imitate
artist- and album-oriented views provided by an iPod.

The intent is not to fully imitate the iPod interface, but mostly
to make removable media much more navigable.

I<mountpoint> defaults to the value of the environment variable
C<IPOD_MOUNTPOINT> if present, otherwise the directory C<mnt/iPod>
under the user's home directory.

=cut

use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use IO::File;
use Mac::iPod::GNUpod;
use MP3::Icecast;
use URI::Escape;

my $mnt = $ARGV[0] ||
    $ENV{'IPOD_MOUNTPOINT'} ||
    (getpwuid($<))[7] . "/mnt/iPod";

my %pl;
my $ipod = Mac::iPod::GNUpod->new(mountpoint => $mnt);
$ipod->read_gnupod();

my @songs = $ipod->all_songs();
for my $songid (@songs)
{
    my $song_info = $ipod->get_song($songid);
    my $artist = $song_info->{'artist'};
    my $album = $song_info->{'album'};
    push @{$pl{'_all'}->{'_all'}}, $songid;
    push @{$pl{$artist}->{'_all'}}, $songid;
    push @{$pl{$artist}->{$album}}, $songid;
    push @{$pl{'_album'}->{$album}}, $songid;
}

write_artist_album_playlists();
write_artist_playlists();
write_album_playlists();
write_everything_playlist();
write_playlist_playlists();

sub write_artist_album_playlists
{
    for my $artist (grep { substr($_,0,1) ne '_' } keys %pl)
    {
	my $albums = $pl{$artist};
	for my $album (grep { substr($_,0,1) ne '_' } keys %$albums)
	{
	    my $pl = $albums->{$album};
	    my @songids = $ipod->search(
		exact => 1, 
		artist => $artist, 
		album => $album,
		);
	    write_artist_album_playlist($artist, $album, @songids);
	}
    }
}

sub write_artist_playlists
{
    for my $artist (grep { substr($_,0,1) ne '_' } keys %pl)
    {
	my @songids = $ipod->search(
	    exact => 1,
	    artist => $artist,
	    );
	write_artist_playlist($artist, @songids);
    }
}

sub write_album_playlists
{
    for my $album (keys %{$pl{'_album'}})
    {
	my @songids = $ipod->search(
	    exact => 1,
	    album => $album,
	    );
	write_album_playlist($album, @songids);
    }
}

sub write_everything_playlist
{
    my @songids = @{$pl{'_all'}->{'_all'}};
    my $m3ufn = File::Spec->catfile($mnt, 'vwTunes', "all songs");
    write_playlist($m3ufn, @songids);
}

sub write_playlist_playlists
{
    my @pls = $ipod->all_pls();
    for my $pl (@pls)
    {
	my @songids = $ipod->render_pl($pl);
	write_playlist_playlist($pl, @songids);
    }
}

sub write_artist_album_playlist
{
    my $artist = shift;
    my $album = shift;
    my @songids = @_;
    my $m3ufn = File::Spec->catfile($mnt, 'vwTunes', 'Artists', $artist, $album);
    write_playlist($m3ufn, @songids);
}

sub write_artist_playlist
{
    my $artist = shift;
    my @songids = @_;
    my $m3ufn = File::Spec->catfile($mnt, 'vwTunes', 'Artists', $artist, "all songs by $artist");
    write_playlist($m3ufn, @songids);
}

sub write_album_playlist
{
    my $album = shift;
    my @songids = @_;
    my $m3ufn = File::Spec->catfile($mnt, 'vwTunes', 'Albums', $album);
    write_playlist($m3ufn, @songids);
}

sub write_playlist_playlist
{
    my $pl = shift;
    my @songids = @_;
    my $m3ufn = File::Spec->catfile($mnt, 'vwTunes', 'Playlists', $pl);
    write_playlist($m3ufn, @songids);
}

sub write_playlist
{
    my $plf = shift;
    my @songids = @_;
    my $icy = MP3::Icecast->new();
    for my $id (@songids)
    {
	my $path = $ipod->get_path($id);
	$icy->add_file($path);
    }
    make_path(dirname($plf));
    write_m3u($plf, $icy);
#    write_pls($plf, $icy);
    printf "Wrote %d songs into %s\n", scalar @songids, $plf;
}

sub write_m3u
{
    my $plf = shift;
    my $icy = shift;
    my $m3u = $icy->m3u();
    unless ($m3u)
    {
	warn "No M3U data for playlist file $plf\n";
	return;
    }

    $m3u =~ s,$mnt,,g;
    $m3u =~ s,/,\\,g;
    write_plf($plf . ".m3u", $m3u);
}

sub write_pls
{
    my $plf = shift;
    my $icy = shift;
    my $pls = $icy->pls();
    unless ($pls)
    {
	warn "No PLS data for playlist file $plf\n";
	return;
    }
    $pls = uri_unescape($pls);
    $pls =~ s,$mnt,,g;
    $pls =~ s,/,\\,g;
#    $pls = uri_escape_utf8($pls);
    write_plf($plf . ".pls", $pls);
}


sub write_plf
{
    my $plf = shift;
    my $data = shift;
    my $fh = IO::File->new($plf, "w");
    unless ($fh)
    {
	warn "Can't write playlist file $plf - $!\n";
	return;
    }
    $fh->print($data);
    $fh->close();

}
__END__

=pod

=head1 BUGS

Possibly obsolete.

=head1 SEE ALSO

L<Mac::iPod::GNUpod>, L<MP3::Icecast>, L<URI::Escape>

=head1 AUTHOR

Tony Monroe

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Tony Monroe.

GNU General Public License version 3 L<http://www.gnu.org/licenses/gpl.html>

=cut
