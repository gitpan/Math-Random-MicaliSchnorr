eval "use Test::Pod 1.00";

if($@) {
  print "1..1\n";
  print "ok 1 - skipped, no sufficiently recent version of Test::Pod installed \n";
}

else {
     Test::Pod::all_pod_files_ok();
}