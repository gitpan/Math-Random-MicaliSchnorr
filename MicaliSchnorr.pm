package Math::Random::MicaliSchnorr;
use strict;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

$Math::Random::MicaliSchnorr::VERSION = '0.01';

DynaLoader::bootstrap Math::Random::MicaliSchnorr $Math::Random::MicaliSchnorr::VERSION;

@Math::Random::MicaliSchnorr::EXPORT_OK = qw(ms ms_seedgen monobit longrun runs poker);
%Math::Random::MicaliSchnorr::EXPORT_TAGS =(all => [qw(ms ms_seedgen monobit longrun runs poker)]);

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

1;

__END__

=head1 NAME

   Math::Random::MicaliSchnorr - the Micali-Schnorr pseudorandom bit generator.
   
=head1 DEPENDENCIES

   This module needs the GMP C library - available from:
   http://swox.com/gmp

   The functions in this module take either Math::GMP or Math::GMPz objects
   as their arguments - so you'll need either Math::GMP or Math::GMPz as
   well. (Actually, *any* perl scalar that's a reference to a GMP mpz
   structure will suffice - it doesn't *have* to be a Math::GMP or
   Math::GMPz object.)

=head1 DESCRIPTION

   An implementation of the Micali-Schnorr pseudorandom bit generator.

=head1 SYNOPSIS

   use warnings;
   use Math::Random::MicaliSchnorr qw(ms ms_seedgen);

   use Math::GMP;
   # and/or:
   use Math::GMPz;

   my $s1 = '1255031698703398971890886237939563492533';
   my $s2 = '10512667662093824763131998324796018248471';
   my $prime1    = Math::GMPz->new($s1);
   my $prime2    = Math::GMPz->new($s2);
   my $seed      = Math::GMPz->new(time + int(rand(10000)));
   my $exp;
   my $bitstream = Math::GMPz->new();
   my $bits_out  = 500;

   # Generate the seed value
   ms_seedgen($seed, $exp, $prime1, $prime2);

   # Fill $bitstream with 500 random bits using $seed, $prime1 and $prime2
   ms($bitstream, $prime1, $prime2, $seed, $exp, $bits_out);

=head1 FUNCTIONS

   ms($o, $prime1, $prime2, $seed, $exp, $bits);

    "$o", "$p", "$q", and "$seed" are all Math::GMP or Math::GMPz objects.
    $p and $q are large primes. (The ms function does not check that they
    are, in fact, prime.)
    Output a $bits-bit random bitstream to $o - calculated using the 
    Micali-Schnorr algorithm, based on the inputs $p, $q, $seed and $exp.
    See the ms_seedgen documentation (below) for the requirements regarding
    $seed and $exp.

   ms_seedgen($seed, $exp, $prime1, $prime2);
    $seed is a Math::GMP or Math::GMPz object. $exp is just a normal perl
    scalar (that will have an unsigned integer value assigned to it). The
    ms_seedgen function assigns suitable values to both $seed and $exp. You
    can, of course, write your own routine for determining these values.
    (The ms function checks that $seed and $exp are in the allowed range.)
    Here are the rules for determining those values:
    Let N be the bitlength of n = $prime1 * $prime2.
    Let phi = ($prime1 - 1) * ($prime2 - 1). $exp must satisfy all 3 of the 
    following conditions:
     i) 2 < $exp < phi
     ii) The greatest common denominator of $exp and phi is 1
     iii) $exp * 80 <= N
    Conditions i) and iii) mean that N has to be at least 340 (80 * 3).
    The ms_seedgen function selects the largest value for $exp that
    satisfies those 3 conditions. Having found a suitable value for $exp, we
    then need to calculate the integer value k = int(N *(1 - (2 / $exp))).
    Then calculate r = N - k.
    $seed is a random number of bitlength r. The ms_seedgen function uses
    the GMP library's mpz_urandomb function to select $seed.
    The mpz_urandomb function is seeded by the value supplied in $seed.

   $bool = monobit($op);
   $bool = longrun($op);
   $bool = runs($op);
   $bool = poker($op);

    These are the 4 standard FIPS-140 statistical tests for testing
    prbg's. They return '1' for success and '0' for failure.
    They test 20000-bit pseudorandom sequences, stored in the
    Math::GMPz/Math::GMP object $op.

=head1 BUGS

   You can get segfaults if you pass the wrong type of argument to the
   functions - so if you get a segfault, the first thing to do is to check
   that the argument types you have supplied are appropriate.

=head1 LICENSE

 This program is free software; you may redistribute it and/or 
 modify it under the same terms as Perl itself.

=head1 AUTHOR

  Copyright Sisyhpus <sisyphus at(@) cpan dot (.) org>

   
=cut
