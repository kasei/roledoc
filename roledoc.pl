#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use lib qw(lib);
use Pod::Perldoc;

use Pod::Roledoc;
use Data::Dumper;

if (scalar(@ARGV) == 0) {
	print <<"END";
Usage: $0 Class.pm

Prints POD composed of the documentation from Class.pm and all roles
references in a head1 ROLES section of Class.pm.

Specifically, roles are identified inside a ROLES head1 section by reference
inside of L<Role> formatting codes. The POD for L<Role> will be loaded, and
C<item>s contained within the C<METHODS> and C<ATTRIBUTES> head1 sections will
be extracted and included in their respective section output for Class.pm.

END
	exit;
}

my $p			= Pod::Perldoc->new();
my $d			= Pod::Roledoc::RoleDelegate->new(get_pod_text => sub {
	my $text	= shift;
	my @found	= $p->grand_search_init([$text]);
	if (my $filename = shift(@found)) {
		if (-r $filename) {
			open(my $fh, '<:utf8', $filename) or return;
			return do { local($/); <$fh> };
		}
	}
	return;
});
my $filename	= shift;
my $tree		= Pod::Tree->new();
$tree->load_file($filename);
my $r			= Pod::Roledoc->new( tree => $tree, delegate => $d );
print $r->serialize();

