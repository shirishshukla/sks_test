class mytest {
   file {"/tmp/hello":
       ensure => present,
       content => "Hello shirish shukla"
 }
}
include mytest

