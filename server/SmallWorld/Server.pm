package SmallWorld::Server;


use strict;
use warnings;
use utf8;

use SmallWorld::Processor;


sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self
}

sub process {
	my ($this, $r) = @_;
	my $processor = SmallWorld::Processor->new($r);
	$processor->process();
}

1;

__END__
