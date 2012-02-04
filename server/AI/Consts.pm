package AI::Consts;


use strict;
use warnings;
use utf8;


require Exporter;
sub BEGIN {
  our @ISA    = qw( Exporter );
  our @export_list;

  my $filename = __FILE__;
  open(ME, '<', $filename) or die "Can't open $filename for input: $!";
  my @lines = <ME>;
  close(ME);
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
use constant EST_AMAZONS   =>  1.0;
use constant EST_DWARVES   => -0.5;
use constant EST_ELVES     =>  0.5;
use constant EST_GIANTS    =>  0.0;
use constant EST_HALFLINGS =>  1.0;
use constant EST_HUMANS    => -0.5;
use constant EST_ORCS      =>  0.0;
use constant EST_RATMEN    =>  1.0;
use constant EST_SKELETONS =>  0.5;
use constant EST_SORCERERS =>  0.5;
use constant EST_TRITONS   =>  0.5;
use constant EST_TROLLS    =>  0.5;
use constant EST_WIZARDS   => -0.5;

# оценки для умений
use constant EST_ALCHEMIST     => 1.0;
use constant EST_BERSERK       => 1.0;
use constant EST_BIVOUACKING   => 0.5;
use constant EST_COMMANDO      => 1.0;
use constant EST_DIPLOMAT      => 1.0;
use constant EST_DRAGON_MASTER => 1.0;
use constant EST_FLYING        => 0.5;
use constant EST_FOREST        => 0.0;
use constant EST_FORTIFIED     => 0.5;
use constant EST_HEROIC        => 1.0;
use constant EST_HILL          => 0.0;
use constant EST_MERCHANT      => 1.0;
use constant EST_MOUNTED       => 0.5;
use constant EST_PILLAGING     => 0.5;
use constant EST_SEAFARING     => 0.5;
use constant EST_STOUT         => 0.5;
use constant EST_SWAMP         => 0.5;
use constant EST_UNDERWORLD    => 0.5;
use constant EST_WEALTHY       => 0.5;


# оценки для рас и умений в зависимости от фазы игры
use constant GP_EARLY => 0;
use constant GP_MIDDLE => 1;
use constant GP_LATE => 2;

use constant EST_RACE => {
  'Amazons'   => [5, 3, 4],
  'Dwarves'   => [1, 1, 1],
  'Elves'     => [3, 4, 2],
  'Giants'    => [4, 3, 4],
  'Halflings' => [2, 4, 3],
  'Humans'    => [1, 3, 3],
  'Orcs'      => [1, 2, 3],
  'Ratmen'    => [5, 4, 4],
  'Skeletons' => [1, 5, 3],
  'Sorcerers' => [1, 3, 2],
  'Tritons'   => [5, 2, 4],
  'Trolls'    => [4, 4, 2],
  'Wizards'   => [1, 3, 3]
};

use constant EST_POWER => {
  'Alchemist'    => [1, 4, 3],
  'Berserk'      => [3, 2, 3],
  'Bivouacking'  => [2, 5, 2],
  'Commando'     => [4, 3, 4],
  'Diplomat'     => [2, 4, 3],
  'DragonMaster' => [4, 4, 4],
  'Flying'       => [3, 3, 3],
  'Forest'       => [1, 3, 3],
  'Fortified'    => [2, 3, 1],
  'Heroic'       => [2, 5, 2],
  'Hill'         => [1, 3, 3],
  'Merchant'     => [1, 3, 3],
  'Mounted'      => [4, 3, 3],
  'Pillaging'    => [1, 3, 3],
  'Seafaring'    => [4, 3, 4],
  'Stout'        => [4, 3, 2],
  'Swamp'        => [1, 3, 3],
  'Underworld'   => [4, 4, 4],
  'Wealthy'      => [4, 2, 4]
};

# глубина поиска атак при одном прохождении
use constant CONQ_WAY_MAX_REGIONS_NUM => 200;

1;

__END__
