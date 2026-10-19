#!/usr/bin/perl
# SPDX-License-Identifier: GPL-2.0-only
# dh_yang must find every YANG module under debian/<package>, whatever the
# directory it runs from holds: its "find $tmp -name *.yang" left the glob
# to the shell, so a .yang file at the top of the source tree narrowed the
# search to that one name and the package lost its yang:Depends.
use strict;
use warnings;
use Carp qw(croak);
use Test::More;
use Cwd        qw(abs_path);
use File::Path qw(make_path);
use File::Temp qw(tempdir);

my $dh_yang = abs_path("scripts/dh_yang");

sub write_file {
    my ( $path, $text ) = @_;
    open my $fh, ">", $path or croak "$path: $!";
    print {$fh} $text or croak "$path: $!";
    close $fh         or croak "$path: $!";
    return;
}

my $dir = tempdir( CLEANUP => 1 );
chdir $dir or croak "$dir: $!";
make_path("debian/foo/usr/share/configd/yang");
write_file( "debian/control",
        "Source: foo\nBuild-Depends: debhelper-compat (= 13)\n\n"
      . "Package: foo\nArchitecture: all\nDescription: test\n test\n" );
write_file( "debian/foo/usr/share/configd/yang/foo-v1.yang",
    "module foo-v1 {\n  import vyatta-types-v1 {\n    prefix types;\n  }\n}\n" );
write_file( "stray.yang", "module stray {\n}\n" );    # top of the source tree

is( system( $^X, $dh_yang ), 0, "dh_yang runs" );
open my $fh, "<", "debian/foo.substvars" or croak "substvars: $!";
my $subst = do { local $/ = undef; <$fh> };
close $fh or croak "substvars: $!";
like(
    $subst,
    qr/^yang:Depends=vyatta-types-v1-yang$/mx,
    "the import in debian/foo is a dependency"
);
chdir "/" or croak "/: $!";
done_testing();
