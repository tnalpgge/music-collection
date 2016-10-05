#!/usr/bin/perl

use strict;
use warnings;

=pod

=head1 NAME

herd.pl - Corral a bunch of music files into a directory structure

=head1 SYNOPSIS

B<herd.pl> I<directory> [I<directory> ...]

=head1 DESCRIPTION

Looks through any I<directory> named on the command line for files
whose names end in C<.mp3>, C<.ogg>, C<.m4a>, or C<.aac>.  Hard-links
or copies them to a directory structure whose filenames are based
on SHA1 checksums of the contents of the files.  Duplicate files
will produce warnings.

The SHA1 checksum in hexadecimal is used to create the filename.
The first digit is the first path component, the next two are the
next path component, and the remaining digits plus the original
extension of the file are used to create the new file name.

Hard links are attempted before copies, in case your source and
target directory structures happen to be on different filesystems.

It is generally safe to run this multiple times with the same
arguments; if no changes have occurred then you will get a bunch
of warnings with no change in disk space used.

=head2 Sample output

Generated from a single directory containing a single album's worth of music.

	./2/0e/0acab587d31fb73a5ba95ed997c6b0defa80f.mp3
	./5/e6/b0010d09f8bcabeb09b1336a60b9497a83681.mp3
	./6/30/ed45167c32ac59bde697e927ad9ca28d27bee.mp3
	./6/a6/bc25fd3cbe41e4786e74f05b42e70c7f1ed76.mp3
	./9/f7/6ecde0cf958e2206001dbc860c4127710e3cb.mp3
	./d/44/930702d2b75502ad272d6589e29d147c11d5f.mp3
	./d/8c/cd6bd6f02ab2850b32b0ca008fe4fb92f9cf8.mp3
	./d/bb/59cd3584c4192a45c8cf6a6067b1476b04e08.mp3
	./f/31/cded5c9a3c87d18a4a01a3786873b221a8be4.mp3
	./f/7a/aa339df16cacf6024d9d801cab6f7eb536d57.mp3
	./f/cb/f944afbfcfe14bdad3d06611baf11e525c3b8.mp3


=cut

use Cwd;
use Digest::SHA qw(sha1);
use File::Basename;
use File::Find ();
use File::Spec;
use File::Copy;
use File::Path qw(make_path);
use Log::Log4perl;

my $l4p = q(
log4perl.rootLogger = INFO, SCREEN
log4perl.appender.SCREEN = Log::Log4perl::Appender::ScreenColoredLevels
log4perl.appender.SCREEN.layout = Log::Log4perl::Layout::SimpleLayout
);

my @extensions = qw(.aac .m4a .mp3 .ogg);

Log::Log4perl::init(\$l4p);

# Set the variable $File::Find::dont_use_nlink if you're using AFS,
# since AFS cheats.

# for the convenience of &wanted calls, including -eval statements:
use vars qw/*name *dir *prune/;
*name   = *File::Find::name;
*dir    = *File::Find::dir;
*prune  = *File::Find::prune;

sub wanted;

my $logger = Log::Log4perl->get_logger();
my $cwd = getcwd();

# Traverse desired filesystems
File::Find::find({wanted => \&wanted}, @ARGV);
exit;

sub wanted {
    my ($dev,$ino,$mode,$nlink,$uid,$gid);

    if (
	( ($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_) ) &&
	(-f _) &&
        (
	    /^.*aac\z/si
	    ||
	    /^.*m4a\z/si
	    ||
	    /^.*mp3\z/si
	    ||
	    /^.*ogg\z/si
	)
    )
    {
	my $sha = Digest::SHA->new();
	my $digest;
	my ($x, $y, $suffix) = fileparse($name, @extensions);
	eval { 
	    $sha->addfile($name);
	    my $digest = $sha->hexdigest;
	    my $destdir = File::Spec->catfile(
		$cwd,
		substr($digest, 0, 1),
		substr($digest, 1, 2),
	    );
	    my $destfile = File::Spec->catfile(
		$destdir,
		substr($digest, 3) . $suffix,
	    );
	    $logger->info($name, " => ", $destfile);
	    if (-f $destfile)
	    {
		$logger->warn($destfile, " already exists");
		next;
	    }
	    if (1)
	    {
		make_path($destdir);
		link($name, $destfile) || copy($name, $destfile) || $logger->warn($?);
	    }
	};
    }
}

=pod

=head1 BUGS

If you somehow manage to find two files that have the same SHA1
checksum over their contents, and both are valid but different music
files, that's a major bummer.  Try changing the metadata for one
of them.

=head1 MOTIVATION

Between iTunes and Time Machine and NFS-mounted volumes, my music
collection got severely messed up.  Creating a new empty iTunes
music library and repopulating using the output of this program
appears to have been a solution to the problem.

=head1 SEE ALSO

L<Digest::SHA>, L<File::Find>, L<Log::Log4perl>

=head1 AUTHOR

Tony Monroe

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016 Tony Monroe.  Redistribution permitted under GNU
General Public License version 3 L<http://www.gnu.org/licenses/gpl.html>.

=cut

