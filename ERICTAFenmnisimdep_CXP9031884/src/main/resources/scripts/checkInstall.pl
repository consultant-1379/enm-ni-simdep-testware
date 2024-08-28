#!/usr/bin/perl -w
use ExtUtils::Installed;
use Switch;
use Cwd 'abs_path';
use File::Basename;

my $check=$ARGV[0];
my $value=0;
#print "$check";
my $inst = ExtUtils::Installed->new();
my $module;
my (@modules) = $inst->modules();
 foreach $module (@modules) 
         {
           if($module eq $check)
          {
                  $value=1;
                  last;
              
          }
          }
		  
if($value eq 1){
print "1";
}
else
{
print "0";
}

