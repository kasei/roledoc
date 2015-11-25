use v5.14;
use strict;
use warnings;
use Pod::Tree;

package Pod::Roledoc::ExtractListItemsDelegate {
	use strict;
	use Moo;
	use Pod::Perldoc;
	use Types::Standard qw(ArrayRef Str Int);
	use namespace::clean;
	with 'Pod::Roledoc::PodDelegate';
	has heading => (is => 'ro', isa => Str, required => 1);
	has head1 => (is => 'rw', isa => Str, default => '');
	has elements => (is => 'ro', isa => ArrayRef, default => sub { [] });
	sub visit {
		my $self	= shift;
		my $tree	= shift;
		my $node	= shift;
		my $type	= $node->get_type;
		
		if ($node->is_command) {
			my $text	= $node->get_text;
			$text		=~ s/\s*$//o;
			if ($node->is_c_head1) {
				$self->head1($text);
			}
		} elsif ($type eq 'item') {
			if ($self->head1 eq $self->heading) {
				push(@{ $self->elements }, $node);
			}
		}
	}
}

1;
