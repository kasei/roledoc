use v5.14;
use strict;
use warnings;
use Pod::Tree;

package Pod::Roledoc::PodDelegate {
	use strict;
	use Moo::Role;
	requires qw(visit text children siblings);
	sub text {
		my $self	= shift;
		my $tree	= shift;
		my $node	= shift;
		
		return $node->get_text // '';
	}
	
	sub children {
		my $self	= shift;
		my $tree	= shift;
		my $node	= shift;
		
		return @{ $node->get_children || [] };
	}
	
	sub siblings {
		my $self	= shift;
		my $tree	= shift;
		my $node	= shift;
		
		return @{ $node->get_siblings };
	}
}

1;
