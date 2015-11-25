use v5.14;
use warnings;
use Test::More;
use Pod::Roledoc;

my $role_pod	= <<"END";
=head1 METHODS

=over 4

=item C<role_method>

=back
END

my $role2_pod	= <<"END";
=head1 ATTRIBUTES

=over 4

=item attr1

Description of attr1.

=item C<< attr2 >>

Description of attr2.

=back

=head1 METHODS

=over 4

=item method1

Method1 description from Role::External2.

=item method2

Method2 description from Role::External2.

=back
END

my $d		= Pod::Roledoc::RoleDelegate->new(get_pod_text => sub {
	my $name	= shift;
# 	warn "Getting POD for $name\n";
	if ($name eq 'Role::External') {
		return $role_pod;
	} elsif ($name eq 'Role::External2') {
		return $role2_pod;
	}
});

##########################################################################################

{
	my $input	= <<"END";
=head1 ROLES

L<Role::External>

=head1 METHODS

=over 4

=item C<< method >>

=back

=cut
END

	my $tree	= Pod::Tree->new();
	$tree->load_string($input);
	my $r		= Pod::Roledoc->new( tree => $tree, delegate => $d );
	my $pod		= $r->serialize();
	like($pod, qr/C<< method >>/, 'original method from class');
	like($pod, qr/C<< role_method >>/, 'adding method from role');
}

##########################################################################################

{
	my $input	= <<"END";
=head1 ROLES

L<Role::External>, L<Role::External2>

=head1 METHODS

=over 4

=item C<< method0 >>

=item C<< method1 >>

=back

=cut
END

	my $tree	= Pod::Tree->new();
	$tree->load_string($input);
	my $r		= Pod::Roledoc->new( tree => $tree, delegate => $d );
	my $pod		= $r->serialize();
	like($pod, qr/C<< role_method >>/, 'adding method from first role');
	my @methods	= ($pod =~ /(method\d)/sg);
	is(scalar(@methods), 3, 'expected count of methods in environment with multiple defintions');
	is_deeply(\@methods, [qw(method0 method1 method2)], 'union of methods from class and second role');
}

done_testing();
