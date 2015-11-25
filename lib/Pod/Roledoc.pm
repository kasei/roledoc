use v5.14;
use strict;
use warnings;
use Pod::Tree;

package Pod::Roledoc 0.001 {
	use strict;
	use Pod::Tree;
	use Moo;
	use Pod::Roledoc::RoleDelegate;
	use Pod::Roledoc::PodDelegate;
	use Types::Standard qw(ConsumerOf);
	use namespace::clean;
	
	has 'tree' => (is => 'ro', required => 1);
	has 'delegate' => (is => 'ro', isa => ConsumerOf['Pod::Roledoc::PodDelegate'], required => 1);
	
	sub serialize {
		my $self	= shift;
		my $tree	= $self->tree;
		my $root	= $tree->get_root;
		my $output	= '';
		foreach my $n (@{ $root->get_children }) {
			$output	.= $self->handle($n);
		}
		$output	.= "\n";
		return $output;
	}

	sub handle {
		my $self		= shift;
		my $node		= shift;
		my $depth		= shift // 0;
		my $counter		= shift // 1;
		my $tree		= $self->tree;
		my $delegate	= $self->delegate;
		$delegate->visit($tree, $node);

		my $type		= $node->get_type;
		return if ($type eq 'code');
		
		my $indent		= '  ' x $depth;
# 		warn "${indent}$type\n";
		my @children	= $delegate->children($tree, $node);
		if ($type eq 'command') {
			my $command = $node->get_command;
			my $text	= $delegate->text($tree, $node);
			$text		=~ s/\s*$//o;
			return "=$command $text\n\n";
		} elsif ($type eq 'item') {
			my $type	= $node->get_item_type;
			my $output	= '=item ';
			if ($type eq 'text') {
			} elsif ($type eq 'bullet') {
				$output	.= "* ";
			} elsif ($type eq 'number') {
				my $num	= $counter++;
				$output	.= "* ${num}. ";
			}
			foreach my $n (@children) {
				$output	.= $self->handle($n);
			}
			foreach my $n ($delegate->siblings($tree, $node)) {
				$output	.= $self->handle($n);
			}
			return $output;
		} elsif ($type eq 'list') {
			my $type	= $node->get_list_type;
			my $arg		= $node->get_arg;
			my $output	= "=over $arg\n\n";
			my $counter	= 1;
			foreach my $n (@children) {
				$output	.= $self->handle($n, 1+$depth, $counter++);
			}
			$output	.= "=back\n\n";
			return $output;
		} elsif ($type eq 'sequence') {
			my $code	= $node->get_letter;
			my $output	= "${code}<< ";
			foreach my $n (@children) {
				my $text	= $self->handle($n, 1+$depth);
				$output	.= $text;
			}
			$output	.= " >>";
			return $output;
		} elsif ($type eq 'text' or $type eq 'verbatim') {
			return $delegate->text($tree, $node);
		} elsif ($type eq 'ordinary') {
			my $output	= '';
			foreach my $n (@children) {
				$output	.= $self->handle($n, 1+$depth);
			}
			return $output;
		}
	
		my $output	= '';
		if (scalar(@children)) {
			warn "*** ${indent}$type";
			foreach my $n (@children) {
				$output	.= $self->handle($n, 1+$depth);
			}
			warn $output;
		} else {
			my $text	= $delegate->text($tree, $node);
			$text		=~ s/[\n\r\t]/ /g;
			warn "*** ${indent}$type\t- $text";
		}
		return $output;
	}
}

1;
