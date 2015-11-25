use v5.14;
use strict;
use warnings;
use Pod::Tree;

package Pod::Roledoc::RoleDelegate {
	use strict;
	use Moo;
	use Data::Dumper;
	use Pod::Roledoc::ExtractListItemsDelegate;
	use Types::Standard qw(CodeRef HashRef ArrayRef Str Int);
	use namespace::clean;
	with 'Pod::Roledoc::PodDelegate';
	
	has sections => (is => 'rw', isa => ArrayRef, default => sub { return [qw(METHODS ATTRIBUTES)] });
	has get_pod_text => (is => 'rw', isa => CodeRef, required => 1);
	has extras => (is => 'rw', isa => HashRef, default => sub { +{} });
	has head1 => (is => 'rw', isa => Str, default => '');
	has roles => (is => 'ro', isa => ArrayRef[Str], default => sub { [] });
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
		} elsif ($type eq 'sequence') {
			if ($self->head1 eq 'ROLES') {
				my $code	= $node->get_letter;
				if ($code eq 'L') {
					my $text	= $node->get_deep_text;
					if (my $string = $self->get_pod_text->($text)) {
						foreach my $sec (@{ $self->sections }) {
							my @extras	= $self->extract_pod_items_from_string_section($string, $sec);
							push(@{ $self->extras->{$sec} }, @extras);
						}
						push(@{ $self->roles }, [$text => $string]);
					}
				}
			}
		}
	}

	around 'children' => sub {
		my $orig	= shift;
		my $self	= shift;
		my $tree	= shift;
		my $node	= shift;
		my @children	= $orig->($self, $tree, $node, @_);
		my $type		= $node->get_type;
		
		if ($type eq 'list') {
			my %seen;
			foreach my $item (@children) {
				my $text	= $item->get_deep_text;
				$text		=~ s/\s*$//;
				$seen{$text}++;
			}
			my $section	= $self->head1;
			if (my $e = delete $self->extras->{ $section }) {
# 				warn "- Adding items to $section...\n";
				foreach my $item (@$e) {
					my $text	= $item->get_deep_text;
					$text		=~ s/\s*$//;
					if ($seen{$text}) {
# 						warn "* $text is already in the POD\n";
					} else {
# 						warn "* Adding $text from role\n";
						push(@children, $item);
					}
				}
			}
		}
		return @children;
	};
	
	sub extract_pod_items_from_string_section {
		my $self	= shift;
		my $string	= shift;
		my $section	= shift;
		my $e		= Pod::Roledoc::ExtractListItemsDelegate->new( heading => $section );
		my $subtree	= Pod::Tree->new();
		$subtree->load_string($string);
		my $rr	= Pod::Roledoc->new( tree => $subtree, delegate => $e );
		$rr->serialize();
		return @{ $e->elements };
	}
}

1;
