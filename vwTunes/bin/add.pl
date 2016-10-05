#!/usr/bin/perl

use strict;
use warnings;

=pod

=head1 NAME

add.pl - Flexibly add items to iPod-like directory structure

=head1 SYNOPSIS

add.pl
[B<-?>]
[B<-h>]
[B<-m> I<path>]
[B<-p> I<playlist>]
I<item> [I<item> I<...>]

=head1 DESCRIPTION

Takes the I<item>s on the command line and adds them to a
possibly-existing iPod-like directory structure.

If I<item> is a directory, then all files under it will be added,
recursively.

If I<item> begins with C<@> then the rest of the argument will be
treated as a file name.  The file by that name will be opened and
consulted for a list of items to add.  Recursion is possible by
this mechanism.

If I<item> is a relative pathname, it does not appear to exist in
the filesystem, but it does exist relative to the directory specified
by the environment variable C<ITUNES_LIBRARY>, then this program
will operate on the file under that directory.  If C<ITUNES_LIBRARY>
is not set, then the item will be ignored.

=head2 Options

=head3 B<-m> I<--mount>

Selects the directory where the removable media is mounted.  The
value on the command line overrides the value in the environment
variable C<IPOD_MOUNTPOINT>.  Defaults to C<mnt/iPod> under your
home directory if absent from both command line and environment.

=head3 B<-p> B<--playlist>

After all I<item>s have been processed, add all valid files to the
named playlist in the iPod.

=cut

use File::Find;
use File::Spec;
use Getopt::Long;
use IO::File;
use Mac::iPod::GNUpod;
use Pod::Usage;

no warnings 'File::Find';

my $help = undef;
my $mnt = $ENV{'IPOD_MOUNTPOINT'} || 
    File::Spec->catfile((getpwuid($<))[7], "mnt", "iPod");
my $playlist = undef;

my %options = (
    'mount|m=s' => \$mnt,
    'playlist|p=s' => \$playlist,
    'help|?|h' => \$help,
    );

my $ipod = Mac::iPod::GNUpod->new(mountpoint => $mnt);
$ipod->read_gnupod();

my @ids = ();
for my $maybe_song (@ARGV)
{
    add_things($maybe_song);
}

if ($playlist)
{
    $ipod->add_pl($playlist, @ids);
}

$ipod->write_gnupod();
$ipod->write_itunes(name => 'vwTunes');

sub add_things
{
    my $thing = shift;
    if (-d $thing)
    {
	File::Find::find(\&wanted, $thing)
    }
    elsif (-f $thing)
    {
	add_thing($thing);
    }
    elsif (substr($thing, 0, 1) eq '@')
    {
	my $realthing = substr($thing, 1);
	if (-r $realthing)
	{
	    my $fh = IO::File->new($realthing, "r");
	    my $l;
	    while ($l = $fh->getline())
	    {
		chomp($l);
		add_things($l);
	    }
	    $fh->close();
	}
    }
    elsif (substr($thing, 0, 1) ne '/')
    {
	my $library = $ENV{'ITUNES_LIBRARY'};
	if (defined $library)
	{
	    my $relative_thing = File::Spec->catfile($library, $thing);
	    add_things($relative_thing);	    
	}
    }
    else
    {
	warn "Unknown thing to add to iPod $thing\n";
    }
}

sub wanted
{
    if (-f $_)
    {
	add_thing($File::Find::name);
    }
}

sub add_thing
{
    my $thing = shift;
    my $id = $ipod->add_song($thing);
    if ($id)
    {
	push @ids, $id;
	return;
    }
    my @maybe_dups = $ipod->get_dup($thing);
    for my $dup (@maybe_dups)
    {
	unless (authn_dup($thing, $dup))
	{
	    $ipod->allow_dup(1);
	    add_thing($thing);
	    $ipod->allow_dup(0);
	}
    }
}

sub authn_dup
{
    my $thing = shift;
    my $dup = shift;
    my $dupinfo = $ipod->get_song($dup);
    my $thinginfo = Mac::iPod::GNUpod::Utils::wtf_is($thing);
    printf "Attempting to add song %s %s %s\n", $thinginfo->{'artist'}, $thinginfo->{'title'}, $thinginfo->{'album'};
    printf "Suspected duplicate %s %s %s\n", $dupinfo->{'artist'}, $dupinfo->{'title'}, $dupinfo->{'album'};
    if ($dupinfo->{'artist'} eq $thinginfo->{'artist'})
    {
	if ($dupinfo->{'title'} eq $thinginfo->{'title'})
	{
	    if ($dupinfo->{'album'} eq $thinginfo->{'album'})
	    {
		print "Confirmed duplicate\n";
		return "0 but true";
	    }
	}
    }
    print "Not a duplicate\n";
    return undef;
}

__END__

=pod

=head1 BUGS

Possibly obsolete.

=head1 SEE ALSO

L<File::Find>, L<Mac::iPod::GNUpod>

=head1 AUTHOR

Tony Monroe

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Tony Monroe.

GNU General Public License version 3 L<http://www.gnu.org/licenses/gpl.html>

=cut
