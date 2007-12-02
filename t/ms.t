use warnings;
use strict;
use Math::Random::MicaliSchnorr qw(:all);

my($have_gmp, $have_gmpz) = (0, 0);

eval{require Math::GMP;};
$have_gmp = 1 if !$@;

eval{require Math::GMPz;};
$have_gmpz = 1 if !$@;

if(!$have_gmp && !$have_gmpz) {die "You need Math::GMP and/or Math::GMPz to use this module"}

if($have_gmp && $have_gmpz) {print "1..22\n"}
else {print "1..11\n"}

my $s1 = '1321504170932111985396356262763066993793762008163514975192515895662363186950339008427484439562304981449124279315172028837928502023';
my $s2 = '4708624379265391660414608347401740900398587896933217500884932058580284684718941809905763824694692577';
my $count = 0;

if($have_gmp) {
  my $p1 =  Math::GMP->new($s1);
  my $p2 =  Math::GMP->new($s2);
  my $seed = Math::GMP->new(int(rand(100000)));
  my $exp = 0;
  my $bitstream = Math::GMP->new(0);

  ms_seedgen($seed, $exp, $p1, $p2);
  if(Math::GMP::sizeinbase_gmp($seed, 2) <= 305 && Math::GMP::sizeinbase_gmp($seed, 2) >= 275 && $exp == 5) {print "ok 1\n"}
  else {print "not ok 1 $seed $exp\n"}

  ms($bitstream, $p1, $p2, $seed, $exp, 20000);

  if(monobit($bitstream)) {print "ok 2\n"}
  else {print "not ok 2\n"}

  if(longrun($bitstream)) {print "ok 3\n"}
  else {print "not ok 3\n"}

  if(runs($bitstream)) {print "ok 4\n"}
  else {print "not ok 4\n"}

  if(poker($bitstream)) {print "ok 5\n"}
  else {print "not ok 5\n"}

  eval{ms($bitstream, $p1, $p2, $seed, 2, 2000);};
  if($@ =~ /needs to be greater than 2/) {print "ok 6\n"}
  else {print "not ok 6\n"}

  eval{ms($bitstream, $p1, $p2, $seed, 11, 2000);};
  if($@ =~ /needs to be less than or equal to/) {print "ok 7\n"}
  else {print "not ok 7\n"}

  eval{ms($bitstream, $p1, $p2, $seed, 9, 2000);};
  if($@ =~ /gcd/) {print "ok 8\n"}
  else {print "not ok 8\n"}

  my $string = randstring(306);
  my $seed2 = Math::GMP->new($string, 2);
  eval{ms($bitstream, $p1, $p2, $seed2, 5, 2000);};
  if($@ =~ /too big/) {print "ok 9\n"}
  else {print "not ok 9\n"}

  eval{ms_seedgen($seed * -1, $exp, $p1, $p2);};
  if($@ =~ /Negative seed/){print "ok 10\n"}
  else {print "not ok 10\n"}

  eval{ms($bitstream, $p1, $p2, $seed * -1, $exp, 2000);};
  if($@ =~ /Negative seed/) {print "ok 11\n"}
  else {print "not ok 11\n"}

  $count = 11;
}

if($have_gmpz) {
  my $p1 =  Math::GMPz->new($s1);
  my $p2 =  Math::GMPz->new($s2);
  my $seed = Math::GMPz->new(int(rand(100000)));
  my $exp;
  my $bitstream = Math::GMPz->new();

  ms_seedgen($seed, $exp, $p1, $p2);
  if(Math::GMPz::Rmpz_sizeinbase($seed, 2) <= 305 && Math::GMPz::Rmpz_sizeinbase($seed, 2) >= 275 && $exp == 5) {print "ok ", $count + 1, "\n"}
  else {print "not ok ", $count + 1, " $seed $exp\n"}

  ms($bitstream, $p1, $p2, $seed, $exp, 20000);

  if(monobit($bitstream)) {print "ok ", $count + 2, "\n"}
  else {print "not ok ", $count + 2, "\n"}

  if(longrun($bitstream)) {print "ok ", $count + 3, "\n"}
  else {print "not ok ", $count + 3, "\n"}

  if(runs($bitstream)) {print "ok ", $count + 4, "\n"}
  else {print "not ok ", $count + 4, "\n"}

  if(poker($bitstream)) {print "ok ", $count + 5, "\n"}
  else {print "not ok ", $count + 5, "\n"}

  eval{ms($bitstream, $p1, $p2, $seed, 2, 2000);};
  if($@ =~ /needs to be greater than 2/) {print "ok ", $count + 6, "\n"}
  else {print "not ok ", $count + 6, "\n"}

  eval{ms($bitstream, $p1, $p2, $seed, 11, 2000);};
  if($@ =~ /needs to be less than or equal to/) {print "ok ", $count + 7, "\n"}
  else {print "not ok ", $count + 7, "\n"}

  eval{ms($bitstream, $p1, $p2, $seed, 9, 2000);};
  if($@ =~ /gcd/) {print "ok ", $count + 8, "\n"}
  else {print "not ok ", $count + 8, "\n"}

  my $string = randstring(306);
  my $seed2 = Math::GMPz->new($string, 2);
  eval{ms($bitstream, $p1, $p2, $seed2, 5, 2000);};
  if($@ =~ /too big/) {print "ok ", $count + 9, "\n"}
  else {print "not ok ", $count + 9, "\n"}

  eval{ms_seedgen($seed * -1, $exp, $p1, $p2);};
  if($@ =~ /Negative seed/){print "ok ", $count + 10, "\n"}
  else {print "not ok ", $count + 10, "\n"}

  eval{ms($bitstream, $p1, $p2, $seed * -1, $exp, 2000);};
  if($@ =~ /Negative seed/) {print "ok ", $count + 11, "\n"}
  else {print "not ok ", $count + 11, "\n"}

}

sub randstring {
    my $ret = 1;
    $ret .= int rand 2 for 1 .. $_[0] - 1;
    return $ret;
}