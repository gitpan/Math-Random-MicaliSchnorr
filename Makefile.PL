use ExtUtils::MakeMaker;

my %options = 
(
  'NAME' => 'Math::Random::MicaliSchnorr',
  'LIBS' => ['-lgmp'],
  'VERSION_FROM' => 'MicaliSchnorr.pm',
  PREREQ_PM => {'Math::GMP'  => 2.0,},
);

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
