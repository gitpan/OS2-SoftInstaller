# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use OS2::SoftInstaller;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

%zip = ( pods => 'perl_pod.zip',
	 site_lib => 'perl_ste.zip',
	 binary_lib => 'perl_blb.zip',
	 main_lib => 'perl_mlb.zip',
	 manual_main => 'perl_man.zip',
	 manual_mod => 'perl_mam.zip',
	 utilities => 'perl_utl.zip',
	 execs => 'perl_exc.zip',
	 aout => 'perl_aou.zip',
	 sh => 'perl_sh.zip',
       );
%dirid = ( pods => 'AUX6',
	   site_lib => 'AUX5',
	   binary_lib => 'FILE',
	   main_lib => 'FILE',
	   manual_main => 'AUX7',
	   manual_mod => 'AUX7',
	   utilities => 'AUX2',	# Will be corrected to AUX3 when needed
	   execs => 'AUX1',
	   aout => 'AUX1',
	   sh => 'AUX4',
	 );

%shortid = ( binary_lib => 'binlib',
	     manual_main => 'mainman',
	     manual_mod => 'modman',
	     utilities => 'utils',
	   );

$tmp = $ENV{TMP} || $ENV{TEMP} || '/tmp';
$tmp =~ s,\\,/,g ;

$tmpdir = "$tmp/pl.$$";
mkdir $tmpdir, 0777 or die "mkdir: $!";

#$tmpdir1 = "$tmp/out.$$";
#mkdir $tmpdir1, 0777 or die "mkdir1: $!";

use Cwd 'cwd';


$tmpdir1 = cwd . "/dist";
mkdir $tmpdir1, 0777 or die "mkdir1: $!" unless -d $tmpdir1;

END {
  system 'rm', '-rf', $tmpdir;
}

use Config '%Config';

File::Copy::syscopy $Config{privlib}, $tmpdir or die "copy: $!";

use File::Basename;

#($name,$path,$suffix) = fileparse($Config{privlib});
#$perldir = "$tmpdir/$name$suffix";
$perldir = $tmpdir;

chdir $tmpdir or die "cd: $!";

system 'zip', '-ru', "$tmpdir1/$zip{pods}", "pod" and die "zip: $?, $!";
system 'rm', '-rf', "pod" and die "rm: $?, $!";

chdir 'site_perl' or die "cd: $!";
system 'zip', '-ru', "$tmpdir1/$zip{site_lib}", "*" and die "zip: $?, $!";
chdir '..' or die "cd: $!";
system 'rm', '-rf', "site_perl" and die "rm: $?, $!";

$core = "$Config{archlib}/CORE";
$core = substr $core, (length $Config{privlib}) + 1;
system 'zip', '-ru', "$tmpdir1/$zip{binary_lib}", $core and die "zip: $?, $!";
system 'zip', '-ru', "$tmpdir1/$zip{binary_lib}", '.', '-i', '*.a', '*.lib'
  and die "zip: $?, $!";
system 'rm', '-rf', $core and die "rm: $?, $!";

use File::Find 'find';

@found = ();

find sub {
  push @found, $File::Find::name if /\.(a|lib|rej|orig)$/i;
  push @found, $File::Find::name if /[~\#]$/;
}, '.';

chmod 0666, @found or die "chmod: $!";
unlink @found or die "unlink: $!";

system 'zip', '-ru', "$tmpdir1/$zip{main_lib}", '.' and die "zip: $?, $!";
chdir '..' or die "cd: $!";
system 'rm', '-rf', "pl.$$/*" and die "rm: $?, $!";

chdir substr $Config{privlib}, 0, length($Config{privlib}) - 4;	# /lib
chdir 'man' or die "cd: $!";
system 'zip', '-ru', "$tmpdir1/$zip{manual_main}", 'man1'
  and die "zip: $?, $!";
system 'zip', '-ru', "$tmpdir1/$zip{manual_mod}", 'man3' and die "zip: $?, $!";

chdir '../bin' or die "cd: $!";
@found = ();

find sub {
  push @found, $File::Find::name unless /\./;
}, '.';

@scripts = map "$_.cmd", @found;
system 'zip', '-u', "$tmpdir1/$zip{utilities}", '*.exe' and die "zip: $?, $!";

chdir 'f:/emx.add/bin' or die "cd: $!";
system 'zip', '-u', "$tmpdir1/$zip{utilities}", @scripts and die "zip: $?, $!";
system 'zip', '-u', "$tmpdir1/$zip{execs}", 'perl.exe', 'perl__.exe' 
  and die "zip: $?, $!";
system 'zip', '-u', "$tmpdir1/$zip{aout}", 'perl_.exe' and die "zip: $?, $!";
chdir '../dll' or die "cd: $!";
system 'zip', '-u', "$tmpdir1/$zip{execs}", 'perl.dll' and die "zip: $?, $!";

($name,$path,$suffix) = fileparse($Config{sh});

chdir $path or die "cd: $!";
system 'zip', '-u', "$tmpdir1/$zip{sh}", "$name$suffix" and die "zip: $?, $!";

mkdir "$tmpdir/unzip", 0777 or die "mkdir: $!";

my $cnt = 1;

for $file (keys %zip) {
  if ($file eq 'execs') {
    process($file, 0, '*.exe');
    local $dirid{file} = 'AUX3';
    process($file, 1, '*.dll');
  } else {
    process($file, 0);
  }
}

sub process {
  my ($file, $nozip) = (shift, shift);
  if (-r "$tmpdir1/$file.pkg" 
      and -M "$tmpdir1/$zip{$file}" > -M "$tmpdir1/$file.pkg") {
    $cnt++;
    print STDOUT "ok $cnt\n# skipped\n";
    return;
  }
  system 'unzip', "$tmpdir1/$zip{$file}", '-d', "$tmpdir/unzip", @_
    and die "unzip: $?, $!";
  if ($nozip) {
    open PKG, ">>$tmpdir1/$file.pkg" or die "open: $!";
  } else {
    open PKG, ">$tmpdir1/$file.pkg" or die "open: $!";
  }
  select PKG;
  make_pkg toplevel => "$tmpdir/unzip", zipfile => $zip{$file}, 
    nozip => $nozip, packid => ($shortid{$file} || $file), 
    dirid => $dirid{$file};
  close PKG or die "close: $!";
  #system 'rm', '-rf', "$tmpdir/unzip" and die "rm: $?, $!"; # Does not work
  system 'rm', '-rf', "$tmpdir/unzip/*" and die "rm: $?, $!"; # Does not work
  $cnt++;
  print STDOUT "ok $cnt\n";
}

$p_version = $] ;
$p_version =~ s/^5\.0/05/ or die "Bad version string";

open ICF, ">$tmpdir1/Perl.ICF" or die "open: $!";
print ICF <<EOC;
CATALOG
  NAME         = 'Perl interpreter',
  DESCRIPTION  = 'This catalog contains Perl interpreter.'

PACKAGE
  NAME            = 'Perl interpreter',
  * Number is decimal for 'P' 'e' 'r' (in fact 'e' is 101):
  NUMBER          = '8001-114',
  FEATURE         = '0000',
  VRM             = '$p_version',
  PACKAGEFILE     = 'DRIVE: Perl.PKG',
  PKGDESCRFILE    = 'DRIVE: Perl.DSC',
  SIZE            = '7000000',
  UPDATECONFIGSYS = 'YES'
EOC

close ICF or die "close: $!";

open PKG, ">$tmpdir1/Perl.pkg" or die "open: $!";
print PKG <<EOP;
SERVICELEVEL
   LEVEL = '$p_version'


**********************************************************************


*---------------------------------------------------------------------
*  Include 1 DISK entry for each diskette needed.
*
*  The following changes are required:
*  - Change "<Product Name>" in the each NAME keyword to your product
*    name.
*  - Set each VOLUME keyword to a unique value.
*---------------------------------------------------------------------
DISK
   NAME   = '<Product Name> - Diskette 1',
   VOLUME = 'PROD001'

DISK
   NAME   = '<Product Name> - Diskette 2',
   VOLUME = 'PROD002'


**********************************************************************


*---------------------------------------------------------------------
*  Default directories
*---------------------------------------------------------------------
PATH
   FILE	     = 'G:/perllib/lib',
   FILELABEL = 'Directory for perl library:',
   AUX1      = 'G:/emx/bin',
   AUX1LABEL = 'Directory for perl execs:',
   AUX2      = 'G:/emx/bin',
   AUX2LABEL = 'Directory for perl utils:',
   AUX3      = 'G:/emx/dll',
   AUX3LABEL = 'Directory for perl dlls:',
   AUX4      = 'G:/bin',
   AUX4LABEL = 'Directory for pdksh exec:',
   AUX5      = 'G:/perllib/lib/site_perl',
   AUX5LABEL = 'Directory for optnl library:',
   AUX6      = 'G:/perllib/lib/pod',
   AUX6LABEL = 'Directory for PODs:',
   AUX7      = 'G:/perllib/man',
   AUX7LABEL = 'Directory for manpages:'


**********************************************************************


*---------------------------------------------------------------------
*  Exit to define your product folder's object ID.
*
*  The following changes are required:
*  - Set variable FOLDERID to your folder's object ID; be sure to make
*    the value sufficiently unique; do not use "PRODFLDR".
*---------------------------------------------------------------------
FILE
   EXITWHEN = 'ALWAYS',
   EXIT     = 'SETVAR FOLDERID=PERLFLDR'


**********************************************************************


*---------------------------------------------------------------------
*  This component creates a folder on the desktop.  You must create
*  the folder in a hidden component to ensure that deleting your
*  product does not delete the folder before the objects within the
*  folder are deleted.
*---------------------------------------------------------------------
COMPONENT
   NAME    = 'INSFIRST',
   ID      = 'INSFIRST',
   DISPLAY = 'NO',
   SIZE    = '1000'

*---------------------------------------------------------------------
*  Include a FILE entry to install the catalog file.
*
*  The following changes are required:
*  - Change the SOURCE and PWS keywords to the name of your catalog
*    file.
*---------------------------------------------------------------------
FILE
   VOLUME        = 'PROD001',
   WHEN          = 'OUTOFDATE',
   REPLACEINUSE  = 'I U D R',
   UNPACK        = 'NO',
   SOURCE        = 'DRIVE: Perl.ICF',
   PWS           = 'perl.ICF',
   DATE          = '950101',
   TIME          = '1200',
   SIZE          = '1000'

*---------------------------------------------------------------------
*  Set variable CATALOG to be the name of the catalog file;
*  the variable is used in EPFISINC.PKG.
*
*  The following changes are required:
*  - Change "CATALOG.ICF" in the EXIT keyword to the name of your
*    catalog file.
*---------------------------------------------------------------------
FILE
   EXITWHEN      = 'INSTALL || UPDATE || RESTORE',
   EXITIGNOREERR = 'NO',
   EXIT          = 'SETVAR CATALOG=Perl.ICF'

*---------------------------------------------------------------------
*  Include a FILE entry to install the description file.
*
*  The following changes are required:
*  - Change the SOURCE and PWS keywords to the name of your
*    description file.
*---------------------------------------------------------------------
FILE
   VOLUME        = 'PROD001',
   WHEN          = 'OUTOFDATE',
   REPLACEINUSE  = 'I U D R',
   UNPACK        = 'NO',
   SOURCE        = 'DRIVE: Perl.DSC',
   PWS           = 'Perl.DSC',
   DATE          = '950101',
   TIME          = '1200',
   SIZE          = '1000'

*---------------------------------------------------------------------
*  Create your product's folder on the desktop.
*
*  The following changes are required:
*  - Change "<Product Name>" in the EXIT keyword to your product name.
*---------------------------------------------------------------------
FILE
   EXITWHEN      = 'INSTALL || UPDATE',
   EXITIGNOREERR = 'NO',
   EXIT          = 'CREATEWPSOBJECT WPFolder "<Product Name>"
                   <WP_DESKTOP> R
                   "OBJECTID=<%FOLDERID%>;"'

*---------------------------------------------------------------------
*  The included package file will install and register the
*  Installation Utility.  You do not need to make any changes to
*  EPFISINC.PKG.
*---------------------------------------------------------------------

* INCLUDE
   * NAME = 'DRIVE: EPFISINC.PKG'


**********************************************************************


FILE
  EXIT = 'setvar unzip=unzip.exe -oj'

FILE
  EXIT = 'setvar unzip_d=-d'

*---------------------------------------------------------------------
*  Include 1 COMPONENT entry for each component.
*
*  The following changes are required:
*  - Change "Component 1" in the NAME keyword to the name of the
*    component.
*  - Describe the component in the DESCRIPTION keyword.
*
*  The component must require at least the INSFIRST and DELLAST
*  components.
*---------------------------------------------------------------------
COMPONENT
   NAME        = 'Perl library as shipped',
   ID          = 'PerlLib',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Libraries from the standard distribution + OS/2 specific libraries',
   SIZE        = '1500000'


INCLUDE
  NAME = 'main_lib.pkg'

COMPONENT
   NAME        = 'Perl executables',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Executables and a DLL for VIO mode and PM mode perl.',
   SIZE        = '700000'


INCLUDE
  NAME = 'execs.pkg'

COMPONENT
   NAME        = 'Executables for Perl utilities',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Executables for Perl-related utilities: conversion to Perl from different formats, autogeneration of modules, documentation tools',
   SIZE        = '400000'


INCLUDE
  NAME = 'utilities.pkg'

COMPONENT
   NAME        = 'Additional Perl modules',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Assortment of perl modules which are not included in the standard distribution, but are very useful.',
   SIZE        = '500000'


INCLUDE
  NAME = 'site_lib.pkg'

COMPONENT
   NAME        = 'Executable for PDKSH shell',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Contains sh.exe. Sometimes Perl would use a shell to run an external program. This shell should take sh-syntax command line. This component contains a simplified version of one of such shells.',
   SIZE        = '150000'


INCLUDE
  NAME = 'sh.pkg'

COMPONENT
   NAME        = 'Support for new modules',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Perl headers and link libraries which are needed for new modules which require compilation. Both static linking and dynamic linking is supported.',
   SIZE        = '1700000'


INCLUDE
  NAME = 'binary_lib.pkg'

COMPONENT
   NAME        = 'Perl a.out-style executable',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Executable for a.out-style-compiled Perl. Only this perl executable can fork(), but it cannot load dynamically-loadable modules. This executable has many modules statically-linked-in.',
   SIZE        = '1000000'


INCLUDE
  NAME = 'aout.pkg'

COMPONENT
   NAME        = 'Perl manpages',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = '"manual pages" for Perl. One needs to have man installed to use perl documentation in this form.',
   SIZE        = '1500000'


INCLUDE
  NAME = 'manual_main.pkg'

COMPONENT
   NAME        = 'Perl modules manpages',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = '"manual pages" for perl modules. One needs to have man installed to use perl documentation in this form.',
   SIZE        = '1100000'


INCLUDE
  NAME = 'manual_mod.pkg'

COMPONENT
   NAME        = 'Perl PODs',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'The "source form" for perl documentation. This form is human-readable, and there are numerous converters to different other forms, including HTML, MAN, INFO, INF, plain-text, PDF and so on.',
   SIZE        = '1200000'


INCLUDE
  NAME = 'pods.pkg'

*---------------------------------------------------------------------
*  This component deletes the product folder; it must be the last
*  COMPONENT entry in the package file.
*
*  No changes are required to any entry in this component.
*---------------------------------------------------------------------
COMPONENT
   NAME    = 'DELLAST',
   ID      = 'DELLAST',
   DISPLAY = 'NO',
   SIZE    = '0'

FILE
   EXITWHEN      = 'DELETE',
   EXITIGNOREERR = 'YES',
   EXIT          = 'DELETEWPSOBJECT <%FOLDERID%>'

EOP

close PKG or die "close: $!";

open DSC, ">$tmpdir1/Perl.dsc" or die "open: $!";
print DSC <<EOP;
Perl is a programming language. This package makes it possible to run
perl programs on your computer.
EOP

close DSC or die "close: $!";

print STDOUT "#Installation files written to $tmpdir1.\n";
