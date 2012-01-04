package AI::Consts;


use strict;
use warnings;
use utf8;


require Exporter;
sub BEGIN {
  our @ISA    = qw( Exporter );
  our @export_list;

  my $filename = __FILE__;
  open ME, "<$filename" or die "Can't open $filename for input: $!";
  my @lines = <ME>;
  foreach ( @lines ) {
    if ( m/^\s*use\s+constant\s+([A-Z_]+)\s+/x ) {
      push @export_list, $1;
    }
  }

  our @EXPORT = @export_list;
}

use constant ABORT         => 0;
use constant CONQUERED     => 1;
use constant NOT_CONQUERED => 2;

# таблицы в БД
use constant STATES_TABLE => 'states';

# оценки для рас
use constant EST_AMAZONS   =>  0.5;
use constant EST_DWARVES   =>  0.0;
use constant EST_ELVES     =>  0.5;
use constant EST_GIANTS    =>  0.0;
use constant EST_HALFLINGS =>  1.5;
use constant EST_HUMANS    => -0.5;
use constant EST_ORCS      =>  0.5;
use constant EST_RATMEN    =>  0.0;
use constant EST_SKELETONS =>  0.5;
use constant EST_SORCERERS =>  0.5;
use constant EST_TRITONS   => -0.5;
use constant EST_TROLLS    =>  0.0;
use constant EST_WIZARDS   => -0.5;

# оценки для умений
use constant EST_ALCHEMIST     => 1.0;
use constant EST_BERSERK       => 0.0;
use constant EST_BIVOUACKING   => 0.5;
use constant EST_COMMANDO      => 0.0;
use constant EST_DIPLOMAT      => 0.5;
use constant EST_DRAGON_MASTER => 1.0;
use constant EST_FLYING        => 0.5;
use constant EST_FOREST        => 0.0;
use constant EST_FORTIFIED     => 0.5;
use constant EST_HEROIC        => 1.0;
use constant EST_HILL          => 0.0;
use constant EST_MERCHANT      => 1.0;
use constant EST_MOUNTED       => 0.5;
use constant EST_PILLAGING     => 1.0;
use constant EST_SEAFARING     => 0.5;
use constant EST_STOUT         => 1.0;
use constant EST_SWAMP         => 0.5;
use constant EST_UNDERWORLD    => 0.5;
use constant EST_WEALTHY       => 1.0;

1;

__END__
