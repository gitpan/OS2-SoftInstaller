# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
use OS2::SoftInstaller;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Cwd 'cwd';
use Config '%Config';
use File::Basename;


my %zip = ( pods => 'perl_pod.zip',
	    site_lib => 'perl_ste.zip',
	    binr_lib => 'perl_blb.zip',
	    main_lib => 'perl_mlb.zip',
	    man_main => 'perl_man.zip',
	    man_modl => 'perl_mam.zip',
	    utilits => 'perl_utl.zip',
	    execs => 'perl_exc.zip',
	    aout => 'perl_aou.zip',
	    sh => 'perl_sh.zip',
	    inf => 'perl_inf.zip',
	    readme => 'plREADME.zip',
	  );
my %dirid = ( pods => 'AUX6',
	      site_lib => 'AUX5',
	      binr_lib => 'FILE',
	      main_lib => 'FILE',
	      man_main => 'AUX7',
	      man_modl => 'AUX7',
	      utilits => 'AUX2',
	      execs => 'AUX1',	# Will be corrected to AUX3 for DLL
	      aout => 'AUX1',
	      sh => 'AUX4',
	      inf => 'AUX8',
	      readme => 'AUX9',
	    );

my %shortid = ( binr_lib => 'binlib',
		man_main => 'mainman',
		man_modl => 'modman',
		utilits => 'utils',
	      );

my $rel_configpm = substr $INC{'Config.pm'}, 1 + length $Config{privlib};

my $tmp = $ENV{TMP} || $ENV{TEMP} || '/tmp';
$tmp =~ s,\\,/,g ;

my $tmpdir = "$tmp/pl.$$";
mkdir $tmpdir, 0777 or die "mkdir: $!";

#$tmpdir1 = "$tmp/out.$$";
#mkdir $tmpdir1, 0777 or die "mkdir1: $!";


$tmpdir1 = cwd . "/dist";
mkdir $tmpdir1, 0777 or die "mkdir1: $!" unless -d $tmpdir1;

END {
  system 'rm', '-rf', $tmpdir;
}

File::Copy::syscopy $Config{privlib}, $tmpdir or die "copy: $!";

#($name,$path,$suffix) = fileparse($Config{privlib});
#$perldir = "$tmpdir/$name$suffix";
$perldir = $tmpdir;

chdir $tmpdir or die "cd: $!";

chdir 'pod' or die "cd: $!";
system 'zip', '-rmu', "$tmpdir1/$zip{pods}", "*.pod" and die "zip: $?, $!";
chdir '..' or die "cd: $!";
# Should not do this, there are some .pm files there...
#system 'rm', '-rf', "pod" and die "rm: $?, $!";

chdir 'site_perl' or die "cd: $!";
system 'zip', '-ru', "$tmpdir1/$zip{site_lib}", "*" and die "zip: $?, $!";
chdir '..' or die "cd: $!";
system 'rm', '-rf', "site_perl" and die "rm: $?, $!";

$core = "$Config{archlib}/CORE";
$core = substr $core, (length $Config{privlib}) + 1;
system 'zip', '-ru', "$tmpdir1/$zip{binr_lib}", $core and die "zip: $?, $!";
system 'zip', '-ru', "$tmpdir1/$zip{binr_lib}", '.', '-i', '*.a', '*.lib'
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
system 'zip', '-ru', "$tmpdir1/$zip{man_main}", 'man1'
  and die "zip: $?, $!";
system 'zip', '-ru', "$tmpdir1/$zip{man_modl}", 'man3' and die "zip: $?, $!";

chdir '../bin' or die "cd: $!";
@found = qw(pod2ipf pod2texi);

find sub {
  push @found, $File::Find::name unless /\./;
}, '.';

@scripts = map "$_.cmd", @found;
system 'zip', '-u', "$tmpdir1/$zip{utilits}", '*.exe' and die "zip: $?, $!";

chdir '..' or die "cd: $!";
unless (-f 'README.os2') {
  File::Copy::syscopy 'lib/pod/perlos2.pod', 'README.os2' or die "copy: $!";
}
system 'zip', '-ru', "$tmpdir1/$zip{readme}", 'README.os2'
  and die "zip: $?, $!";
system 'zip', '-ru', "$tmpdir1/$zip{readme}", 'patch.os2'
  and die "zip: $?, $!" if -f 'patch.os2';

chdir 'f:/emx.add/bin' or die "cd: $!";
system 'zip', '-u', "$tmpdir1/$zip{utilits}", @scripts and die "zip: $?, $!";
system 'zip', '-u', "$tmpdir1/$zip{execs}", 'perl.exe', 'perl__.exe', 'perl___.exe', 'perl.ico', 'perl__.ico' 
  and die "zip: $?, $!";
system 'zip', '-u', "$tmpdir1/$zip{aout}", 'perl_.exe' and die "zip: $?, $!";
chdir '../dll' or die "cd: $!";
system 'zip', '-u', "$tmpdir1/$zip{execs}", 'perl.dll' and die "zip: $?, $!";

($name,$path,$suffix) = fileparse($Config{sh});

chdir $path or die "cd: $!";
system 'zip', '-u', "$tmpdir1/$zip{sh}", "$name$suffix" and die "zip: $?, $!";
system 'zip', '-uj', "$tmpdir1/$zip{inf}", "f:/book/perl.inf" and die "zip: $?, $!";

my $cnt = 1;

process_many(keys %zip);

sub process_many {
  mkdir "$tmpdir/unzip", 0777 or die "mkdir: $!";
  
  my $done;
  my $file;
  
  for $file (@_) {
    if ($file eq 'execs') {
      $done = process($file, 0, '*.exe', '*.ICO');
      local $dirid{$file} = 'AUX3';
      process($file, 1, '*.dll') if $done; # Auto-skipping would not work
    } else {
      process($file, 0);
    }
  }
}

sub process {
  my ($file, $nozip) = (shift, shift);
  if ($nozip == 0 and -r "$tmpdir1/$file.pkg" 
      and -M "$tmpdir1/$zip{$file}" > -M "$tmpdir1/$file.pkg") {
    $cnt++;
    print STDOUT "ok $cnt\n# skipped\n";
    return 0;
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
  return 1;
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
  SIZE            = '10000000'
  * UPDATECONFIGSYS = 'YES'
EOC

close ICF or die "close: $!";

for $fileid ('Perl', keys %zip) {
  if (-f "$tmpdir1/$fileid.PKG") {
    ($size{$fileid}, $date{$fileid}, $time{$fileid})
      = size_date_time_pkg("$tmpdir1/$fileid.PKG");
  } else {
    ($size{$fileid}, $date{$fileid}, $time{$fileid}) 
      = ("1000", "950101", "0000");
  }
}

open PKG, ">$tmpdir1/Perl.pkg" or die "open: $!";
my $manglepath = uc $Config{privlib};
$manglepath =~ s,/,\\,g ;

$configsub_lib = "";
$configpm = $INC{'Config.pm'};
$configpm =~ s/^\Q$Config{privlib}/%EPFIFILEDIR%/o or die "s:";

@keys = grep $Config{$_} =~ m,^\Q$Config{privlib}\E[\'/],o , keys %Config;
foreach $key (@keys) {
  $value = $Config{$key};
  $value =~ s/\Q$Config{privlib}/%EPFIFILEDIR%/o or die "s:" ;
  $configsub_lib .= <<EOS if 0;

UPDATECONFIG
  NAME = $configpm,
  CASESENSITIVE = 'YES',
  VAR = '$key',
  ADDSTR = "'$value'",
  ADDWHEN = '(INSTALL || UPDATE || RESTORE)'
EOS
}

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
   FILE	     = 'F:/perllib/lib',
   FILELABEL = 'Directory for perl library:',
   AUX1      = 'F:/emx/bin',
   AUX1LABEL = 'Directory for perl execs:',
   AUX2      = 'F:/emx/bin',
   AUX2LABEL = 'Directory for perl utils:',
   AUX3      = 'F:/emx/dll',
   AUX3LABEL = 'Directory for perl dlls:',
   AUX4      = 'F:/bin',
   AUX4LABEL = 'Directory for pdksh exec:',
   AUX5      = 'F:/perllib/lib/site_perl',
   AUX5LABEL = 'Directory for optnl library:',
   AUX6      = 'F:/perllib/lib/pod',
   AUX6LABEL = 'Directory for PODs:',
   AUX7      = 'F:/perllib/man',
   AUX7LABEL = 'Directory for manpages:',
   AUX8      = 'F:/perllib/book',
   AUX8LABEL = 'Directory for INF docs:',
   AUX9      = 'F:/perllib',
   AUX9LABEL = 'Directory for READMEs:',
   AUX10      = 'F:/perllib/install',
   AUX10LABEL = 'Directory for install utls:'


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

FILE
   EXITWHEN = 'ALWAYS',
   EXIT     = 'SETVAR CONFIGFL=%EPFIFILEDIR%\\config.dat'

* Touch the file
FILE
   PWS = '%CONFIGFL%',
   PWSPATH = 'FILE',
   EXITWHEN = 'INSTALL || UPDATE || RESTORE',
   EXIT     = 'EXEC bg tw cmd.exe /c "echo .>%CONFIGFL%"'

*FILE
*  PWS  = '%CONFIGFL%',
*  DOWNLOAD = 'DELETE',
*  WHEN = 'DELETE'


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

*FILE
*   VOLUME        = 'PROD001',
*   WHEN          = 'OUTOFDATE',
*   REPLACEINUSE  = 'I U D R',
*   UNPACK        = 'NO',
*   SOURCE        = 'DRIVE: Perl.ICF',
*   PWS           = 'perl.ICF',
*   DATE          = '950101',
*   TIME          = '1200',
*   SIZE          = '1000'

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

FILE
   EXITWHEN      = 'ALWAYS',
   EXIT          = 'SETVAR SLASHES=////'

*---------------------------------------------------------------------
*  Include a FILE entry to install the description file.
*
*  The following changes are required:
*  - Change the SOURCE and PWS keywords to the name of your
*    description file.
*---------------------------------------------------------------------

*FILE
*   VOLUME        = 'PROD001',
*   WHEN          = 'OUTOFDATE',
*   REPLACEINUSE  = 'I U D R',
*   UNPACK        = 'NO',
*   SOURCE        = 'DRIVE: Perl.DSC',
*   PWS           = 'Perl.DSC',
*   DATE          = '950101',
*   TIME          = '1200',
*   SIZE          = '1000'

*---------------------------------------------------------------------
*  Create your product''s folder on the desktop.
*
*  The following changes are required:
*  - Change "<Product Name>" in the EXIT keyword to your product name.
*---------------------------------------------------------------------
FILE
   EXITWHEN      = 'INSTALL || UPDATE',
   EXITIGNOREERR = 'NO',
   EXIT          = 'CREATEWPSOBJECT WPFolder "Perl^ maintenance"
                   <WP_DESKTOP> R
                   "OBJECTID=<%FOLDERID%>;"'

FILE
   EXITWHEN      = 'INSTALL || UPDATE',
   EXITIGNOREERR = 'YES',
   EXIT          = 'CREATEWPSOBJECT WebExplorer_Url "CPAN WWW"
                   <%FOLDERID%> U
                   "LOCATOR=http:%SLASHES%www.perl.com/CPAN/;OBJECTID=<%FOLDERID%_CPAN>;"'

FILE
   EXITWHEN      = 'INSTALL || UPDATE',
   EXITIGNOREERR = 'YES',
   EXIT          = 'CREATEWPSOBJECT WebExplorer_Url "CPAN WWW^ OS2"
                   <%FOLDERID%> U
                   "LOCATOR=http:%SLASHES%www.perl.com/CPAN/ports/os2;OBJECTID=<%FOLDERID%_CPANos2>;"'

FILE
   EXITWHEN      = 'INSTALL || UPDATE',
   EXITIGNOREERR = 'YES',
   EXIT          = 'CREATEWPSOBJECT WebExplorer_Url "CPAN WWW^ modules"
                   <%FOLDERID%> U
                   "LOCATOR=http:%SLASHES%www.perl.com/CPAN/modules;OBJECTID=<%FOLDERID%_CPANmod>;"'

FILE
   EXITWHEN      = 'INSTALL || UPDATE',
   EXITIGNOREERR = 'YES',
   EXIT          = 'CREATEWPSOBJECT WebExplorer_Url "CPAN WWW Index"
                   <%FOLDERID%> U
                   "LOCATOR=http:%SLASHES%www.perl.com/CPAN/index.html;OBJECTID=<%FOLDERID%_CPANind>;"'

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
   NAME        = 'Perl executables',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Executables and a DLL for VIO mode and PM mode perl.',
   SIZE        = '700000'


* Write where it is installed
FILE
   EXITWHEN = 'INSTALL || UPDATE || RESTORE',
   EXIT     = 'EXEC bg tw cmd.exe /c "echo exec %EPFIAUX1DIR%>>%CONFIGFL%"'

INCLUDE
  NAME = 'execs.pkg'

ADDCONFIG
  VAR = 'set PERL_BADLANG',
  ADDSTR = '1',
  ADDWHEN = '(INSTALL || UPDATE || RESTORE) && ("%LANG%" != "") && ("%LANG%" != "en_us") && ("%LANG%" != "en_gb") && ("%LANG%" != "de_de") && ("%LANG%" != "C") && ("%LANG%" != "FRAN") && ("%LANG%" != "GERM") && ("%LANG%" != "ITAL") && ("%LANG%" != "USA") && ("%LANG%" != "SPAIN") && ("%LANG%" != "UK")',
  * DELETEWHEN = '(DELETE || DIREMPTY)',
  DELETEWHEN = DELETE

UPDATECONFIG
  VAR = 'set PATH',
  ADDSTR = '%EPFIAUX1DIR%',
  ADDWHEN = '(INSTALL || UPDATE || RESTORE)',
  * DELETEWHEN = '(DELETE || DIREMPTY)',
  DELETEWHEN = 'DIREMPTY'

UPDATECONFIG
  VAR = 'LIBPATH',
  ADDSTR = '%EPFIAUX3DIR%',
  ADDWHEN = '(INSTALL || UPDATE || RESTORE)',
  * DELETEWHEN = '(DELETE || DIREMPTY)',
  DELETEWHEN = 'DIREMPTY'

* U option of CREATEWPSOBJECT does not work :-()

*FILE
*  PWS = 'putico.cmd',
*  SOURCE = 'DRIVE: putico.cmd',
*  UNPACK = 'NO',
*  PWSPATH = 'FILE',
*  EXITWHEN = 'INSTALL',
*  * Arguments: icofile
*  EXIT = 'EXEC bg tw cmd.exe /c %EPFICURPWS% %EPFIAUX1DIR%\\perl__.ico'

FILE
   EXITWHEN      = 'INSTALL || UPDATE',
   EXITIGNOREERR = 'NO',
   EXIT          = 'CREATEWPSOBJECT WPFolder "Perl^ maintenance"
                   <WP_DESKTOP> U
                   "OBJECTID=<%FOLDERID%>;ICONFILE=%EPFIAUX1DIR%\\perl__.ico"'

COMPONENT
   NAME        = 'Perl library as shipped',
   ID          = 'PerlLib',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Libraries from the standard distribution + OS/2 specific libraries',
   SIZE        = '1500000'

* Write where it is installed
FILE
   EXITWHEN = 'INSTALL || UPDATE || RESTORE',
   EXIT     = 'EXEC bg tw cmd.exe /c "echo privlib %EPFIFILEDIR%>>%CONFIGFL%"'


INCLUDE
  NAME = 'main_lib.pkg'

ADDCONFIG
  VAR = 'set PERLLIB_PREFIX',
  ADDSTR = '$Config{privlib};%EPFIFILEDIR%',
  ADDWHEN = 'NEVER',
  * DELETEWHEN = '(DELETE || DIREMPTY)',
  DELETEWHEN = 'INSTALL'

ADDCONFIG
  VAR = 'set PERLLIB_PREFIX',
  ADDSTR = '$Config{privlib};%EPFIFILEDIR%',
  ADDWHEN = '(INSTALL || UPDATE || RESTORE) && ("%EPFIFILEDIR%" != "$Config{privlib}") && ("%EPFIFILEDIR%" != "$manglepath")',
  * DELETEWHEN = '(DELETE || DIREMPTY)',
  DELETEWHEN = DELETE

FILE
   EXITWHEN = '(INSTALL || UPDATE || RESTORE)',
   EXITIGNOREERR = 'NO',
   EXIT = 'CREATEWPSOBJECT WPProgram "Interactive^ Perl^ evaluator"
	     <%FOLDERID%> R   
	     "PROGTYPE=WINDOWABLEVIO;EXENAME=PERL.EXE;OBJECTID=<%FOLDERID%db>;STARTUPDIR=%EPFIFILEDIR%;PARAMETERS=-de 0;"'

FILE
   EXITWHEN = '(INSTALL || UPDATE || RESTORE)',
   EXITIGNOREERR = 'NO',
   EXIT = 'CREATEWPSOBJECT WPProgram "Interactive^ CPAN"
	     <%FOLDERID%> R   
	     "PROGTYPE=WINDOWABLEVIO;EXENAME=PERL.EXE;OBJECTID=<%FOLDERID%db>;STARTUPDIR=%EPFIFILEDIR%;PARAMETERS=-MCPAN -e shell;"'

$configsub_lib

COMPONENT
   NAME        = 'Executables for Perl utilities',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Executables for Perl-related utilities: conversion to Perl from different formats, autogeneration of modules, documentation tools',
   SIZE        = '400000'


* Write where it is installed
FILE
   EXITWHEN = 'INSTALL || UPDATE || RESTORE',
   EXIT     = 'EXEC bg tw cmd.exe /c "echo bin %EPFIAUX2DIR%>>%CONFIGFL%"'

INCLUDE
  NAME = 'utilits.pkg'

COMPONENT
   NAME        = 'Additional Perl modules',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Assortment of perl modules which are not included in the standard distribution, but are very useful.',
   SIZE        = '500000'


* Write where it is installed
FILE
   EXITWHEN = 'INSTALL || UPDATE || RESTORE',
   EXIT     = 'EXEC bg tw cmd.exe /c "echo sitelib %EPFIAUX5DIR%>>%CONFIGFL%"'

INCLUDE
  NAME = 'site_lib.pkg'

* If PERL5LIB is set, update it.

UPDATECONFIG
  VAR = 'set PERL5LIB',
  ADDSTR = '%EPFIAUX5DIR%/os2',
  ADDWHEN = '(INSTALL || UPDATE || RESTORE) && ("%EPFIFILEDIR%\\SITE_PERL" != "%EPFIAUX5DIR%") && ("%PERL5LIB%" != "")',
  * DELETEWHEN = '(DELETE || DIREMPTY)',
  DELETEWHEN = DELETE

UPDATECONFIG
  VAR = 'set PERL5LIB',
  ADDSTR = '%EPFIAUX5DIR%',
  ADDWHEN = '(INSTALL || UPDATE || RESTORE) && ("%EPFIFILEDIR%\\SITE_PERL" != "%EPFIAUX5DIR%") && ("%PERL5LIB%" != "")',
  * DELETEWHEN = '(DELETE || DIREMPTY)',
  DELETEWHEN = DELETE

* If PERL5LIB is not set, update PERLLIB.

UPDATECONFIG
  VAR = 'set PERLLIB',
  ADDSTR = '%EPFIAUX5DIR%/os2',
  ADDWHEN = '(INSTALL || UPDATE || RESTORE) && ("%EPFIFILEDIR%\\SITE_PERL" != "%EPFIAUX5DIR%") && ("%PERL5LIB%" == "")',
  * DELETEWHEN = '(DELETE || DIREMPTY)',
  DELETEWHEN = DELETE

UPDATECONFIG
  VAR = 'set PERLLIB',
  ADDSTR = '%EPFIAUX5DIR%',
  ADDWHEN = '(INSTALL || UPDATE || RESTORE) && ("%EPFIFILEDIR%\\SITE_PERL" != "%EPFIAUX5DIR%") && ("%PERL5LIB%" == "")',
  * DELETEWHEN = '(DELETE || DIREMPTY)',
  DELETEWHEN = DELETE

COMPONENT
   NAME        = 'Executable for PDKSH shell',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Contains sh.exe. Sometimes Perl would use a shell to run an external program. This shell should take sh-syntax command line. This component contains a simplified version of one of such shells.',
   SIZE        = '150000'

* Write where it is installed
FILE
   EXITWHEN = 'INSTALL || UPDATE || RESTORE',
   EXIT     = 'EXEC bg tw cmd.exe /c "echo shell %EPFIAUX4DIR%>>%CONFIGFL%"'


INCLUDE
  NAME = 'sh.pkg'

ADDCONFIG
  VAR = 'set PERL_SH_DIR',
  ADDSTR = '%EPFIAUX4DIR%',
  ADDWHEN = '(INSTALL || UPDATE || RESTORE) && ("%EPFIAUX4DIR%" != "F:\\BIN")',
  * DELETEWHEN = '(DELETE || DIREMPTY)',
  DELETEWHEN = DELETE

COMPONENT
   NAME        = 'Support for new modules',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Perl headers and link libraries which are needed for new modules which require compilation. Both static linking and dynamic linking is supported.',
   SIZE        = '1700000'


INCLUDE
  NAME = 'binr_lib.pkg'

COMPONENT
   NAME        = 'Perl a.out-style executable',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Executable for a.out-style-compiled Perl. Only this perl executable can be run under DOS and Win*, but it cannot load dynamically-loadable modules. This executable has many modules statically-linked-in.',
   SIZE        = '1000000'


INCLUDE
  NAME = 'aout.pkg'

COMPONENT
   NAME        = 'Perl docs in .INF file',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Documentation for Perl in OS/2-specific format. One may read it by giving a command "view perl logo", or "view perl topic_name" (without quotes)',
   SIZE        = '1000000'


INCLUDE
  NAME = 'inf.pkg'

UPDATECONFIG
  VAR = 'set BOOKSHELF',
  ADDSTR = '%EPFIAUX8DIR%',
  ADDWHEN = '(INSTALL || UPDATE || RESTORE)',
  * DELETEWHEN = '(DELETE || DIREMPTY)',
  DELETEWHEN = DELETE

FILE
   EXITWHEN = '(INSTALL || UPDATE || RESTORE)',
   EXITIGNOREERR = 'NO',
   EXIT = 'CREATEWPSOBJECT WPProgram "Perl^ documentation" <%FOLDERID%> 
           R   "EXENAME=VIEW.EXE;OBJECTID=<%FOLDERID%inf>;STARTUPDIR=%EPFIFILEDIR%;PARAMETERS=Perl Logo"'

COMPONENT
   NAME        = 'Perl manpages',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = '"manual pages" for Perl. One needs to have man installed to use perl documentation in this form.',
   SIZE        = '1500000'


* Write where it is installed
FILE
   EXITWHEN = 'INSTALL || UPDATE || RESTORE',
   EXIT     = 'EXEC bg tw cmd.exe /c "echo man1dir %EPFIAUX7DIR%/man1>>%CONFIGFL%"'

INCLUDE
  NAME = 'man_main.pkg'

UPDATECONFIG
  VAR = 'set MANPATH',
  ADDSTR = '%EPFIAUX7DIR%',
  ADDWHEN = '(INSTALL || UPDATE || RESTORE)',
  * DELETEWHEN = '(DELETE || DIREMPTY)',
  DELETEWHEN = DELETE

COMPONENT
   NAME        = 'Perl modules manpages',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = '"manual pages" for perl modules. One needs to have man installed to use perl documentation in this form.',
   SIZE        = '1100000'

* Write where it is installed
FILE
   EXITWHEN = 'INSTALL || UPDATE || RESTORE',
   EXIT     = 'EXEC bg tw cmd.exe /c "echo man3dir %EPFIAUX7DIR%/man3>>%CONFIGFL%"'

INCLUDE
  NAME = 'man_modl.pkg'

UPDATECONFIG
  VAR = 'set MANPATH',
  ADDSTR = '%EPFIAUX7DIR%',
  ADDWHEN = '(INSTALL || UPDATE || RESTORE)',
  * DELETEWHEN = '(DELETE || DIREMPTY)',
  DELETEWHEN = DELETE

COMPONENT
   NAME        = 'Perl PODs',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'The "source form" for perl documentation. This form is human-readable, and there are numerous converters to different other forms, including HTML, MAN, INFO, INF, plain-text, PDF and so on. Needed for -Mdiagnostics and splain.',
   SIZE        = '1200000'

* Write where it is installed
FILE
   EXITWHEN = 'INSTALL || UPDATE || RESTORE',
   EXIT     = 'EXEC bg tw cmd.exe /c "echo pods %EPFIAUX6DIR%>>%CONFIGFL%"'

INCLUDE
  NAME = 'pods.pkg'


COMPONENT
   NAME        = 'Perl README, patch',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'Text form of documentation of OS/2-specific features. Is just a duplicate of perlos2.pod from "POD" section of distribution. Also may include the patch to the master Perl distribution needed under OS/2.',
   SIZE        = '500000'

INCLUDE
  NAME = 'readme.pkg'

COMPONENT
   NAME        = 'Perl installation/deinstallation',
   REQUIRES    = 'INSFIRST DELLAST',
   DISPLAY     = 'YES',
   DESCRIPTION = 'The utility to install/deinstall perl. Not needed if you preserve the directory you installed perl from.',
   SIZE        = '700000'

FILE
   VOLUME        = 'PROD001',
   WHEN          = 'OUTOFDATE',
   REPLACEINUSE  = 'I U D R',
   UNPACK        = 'NO',
   SOURCE        = 'DRIVE: Perl.DSC',
   PWS           = 'perl.DSC',
   DATE          = '950101',
   TIME          = '1200',
   SIZE          = '1000',
   PWSPATH       = 'AUX10'

FILE
   VOLUME        = 'PROD001',
   WHEN          = 'OUTOFDATE',
   REPLACEINUSE  = 'I U D R',
   UNPACK        = 'NO',
   SOURCE        = 'DRIVE: Perl.ICF',
   PWS           = 'perl.ICF',
   DATE          = '950101',
   TIME          = '1200',
   SIZE          = '1000',
   PWSPATH       = 'AUX10'

FILE
   VOLUME        = 'PROD001',
   WHEN          = 'OUTOFDATE',
   REPLACEINUSE  = 'I U D R',
   UNPACK        = 'NO',
   SOURCE        = 'DRIVE: install.exe',
   PWS           = 'install.exe',
   DATE          = '950101',
   TIME          = '1200',
   SIZE          = '1000',
   PWSPATH       = 'AUX10'

FILE
   VOLUME        = 'PROD001',
   WHEN          = 'OUTOFDATE',
   REPLACEINUSE  = 'I U D R',
   UNPACK        = 'NO',
   SOURCE        = 'DRIVE: install.in_',
   PWS           = 'install.in_',
   DATE          = '950101',
   TIME          = '1200',
   SIZE          = '1000',
   PWSPATH       = 'AUX10'

EOP
;

for $fileid ('Perl', keys %zip) {
  print PKG <<EOP;
FILE
   VOLUME        = 'PROD001',
   WHEN          = 'OUTOFDATE',
   REPLACEINUSE  = 'I U D R',
   UNPACK        = 'NO',
   SOURCE        = 'DRIVE: $fileid.PKG',
   PWS           = '$fileid.PKG',
   DATE          = '$date{$fileid}',
   TIME          = '$time{$fileid}',
   SIZE          = '$size{$fileid}',
   PWSPATH       = 'AUX10'

EOP
}


print PKG <<EOP;

FILE
   EXITWHEN = '(INSTALL || UPDATE || RESTORE)',
   EXITIGNOREERR = 'NO',
   EXIT = 'CREATEWPSOBJECT WPProgram "Installation^ Utility" <%FOLDERID%> R
            "EXENAME=%EPFIAUX10DIR%//install.EXE;OBJECTID=<%FOLDERID%INST>;STARTUPDIR=%EPFIAUX10DIR%;"'

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

* It should be possible to run these two from the source dir,
* but I do not know how to do it... :-()

FILE
  PWS = 'edit_cfg.pl',
  SOURCE = 'DRIVE: edit_cfg.pl',
  UNPACK = 'NO',
  PWSPATH = 'FILE'

FILE
  PWS  = '${rel_configpm}0',
  DOWNLOAD = 'DELETE',
  WHEN = 'DELETE'

FILE
  PWS = 'edit_cfg.cmd',
  SOURCE = 'DRIVE: edit_cfg.cmd',
  UNPACK = 'NO',
  PWSPATH = 'FILE',
  EXITWHEN = 'INSTALL',
  * Arguments: dll, lib, bin
  EXIT = 'EXEC fg tw cmd.exe /c %EPFICURPWS% %EPFIAUX3DIR% %EPFIFILEDIR% %EPFIAUX1DIR%'

EOP

close PKG or die "close: $!";

open DSC, ">$tmpdir1/Perl.dsc" or die "open: $!";
print DSC <<EOP;
Perl is a programming language. This package makes it possible to run
perl programs on your computer.

Installation to a FAT drive is not supported (though may work). You
need to have EMX runtime installed to use this package.  
EOP

close DSC or die "close: $!";

# Calculate which directories depend on what installation paths.
# The dependencies to trace are:
# privlib => FILE
# sitelib => AUX5
# man1dir => AUX7/man1
# man3dir => AUX7/man3
# bin     => AUX2        (well, is it?)
# shell?  => AUX4        (startsh?)
# pods are not reflected in Config.pm.

@dirkeys = qw(privlib sitelib man1dir man3dir bin);
@dirs{@dirkeys} = @Config{@dirkeys};
($dirs{shell} = $Config{sh}) =~ s,/[^/]+$,,;
($dirs{emx} = $Config{libemx}) =~ s,/[^/]+$,,;

%editkeys  = ();

for $key (keys %Config) {
  my ($oldl, $l, $good) = (-1);
  # Find the longest subkey which starts key
  for $subkey (keys %dirs) {
    if (index($Config{$key}, $dirs{$subkey}) == 0 and length $dirs{$subkey} > $oldl) {
      $oldl = length $dirs{$subkey};
      $good = $subkey;
    }
  }
  if (defined $good) {
    if (defined $editkeys{$good}) {
      push @{ $editkeys{$good} }, $key;
    } else {
      $editkeys{$good} = [$key];

    }
    $change_from{$key} = $good;
  }
}
$change_from{startsh} = 'shell';

# Usage: edit_cfg.cmd dllpath perllibpath perlbinpath
open CMD, ">$tmpdir1/edit_cfg.cmd" or die "open: $!";
print CMD <<EOP;
set BEGINLIBPATH=%1
set PERLLIB_PREFIX=$Config{privlib};%2
%3\\perl.exe %2\\edit_cfg.pl %2
EOP

close CMD or die "close: $!";

open PL, ">$tmpdir1/edit_cfg.pl" or die "open: $!";

print PL <<'EOP';
#!perl -p -i0

# We expect the following arguments:
#
# privlib	- which file to edit (the directory part - new privlib)

BEGIN {
  ($perllib_new) = @ARGV;
EOP

print PL <<EOP;
  \$config_long = '$Config{archlib}';	# Hardwired during creation
  \$config_short = '$Config{privlib}';	# Hardwired during creation
EOP
;  
for $key (keys %dirs) {
  print PL <<EOP;
  \$dirs{$key} = '$dirs{$key}';	# Hardwired during creation
EOP
}
for $key (keys %change_from) {
  print PL <<EOP;
  \$change_from{$key} = '$change_from{$key}';	# Hardwired during creation
EOP
}

print PL <<'EOP';
  $config_dat = "$perllib_new/config.dat";
  open DAT, $config_dat or die "Cannot open $config_dat: $!";
  while (<DAT>) {
    $newdir{$1} = $2 if /^(\w+)\s+(.*)$/;
  }
  close DAT or die "Cannot close $config_dat: $!";
  for $key (keys %newdir) {
    $newdir{$key} =~ s,\\,/,g;
  }
  $config_rest = substr $config_long, length $config_short;
  $newconfig_long = $perllib_new . $config_rest;
  @ARGV = $newconfig_long . '/Config.pm';
  # Try to find emx location:
  if (exists $ENV{C_INCLUDE_PATH}) {
    for $dir (split ';', $ENV{C_INCLUDE_PATH}) {
      $dir =~ s,\\,/,g ;
      $dir =~ s,/[^/]+/?$,,;
      $emx = $dir, last if -f "$dir/bin/emxrev.cmd";	# Random check.
    }
  }
  unless (defined $emx) {
    for $dir (split ';', $ENV{PATH}) {
      next unless $dir =~ /^[a-z]:\\emx\\bin\\?$/i ;
      $dir =~ s,\\,/,g ;
      $dir =~ s,/[^/]+/?$,,;
      $emx = $dir, last if -f "$dir/bin/emxrev.cmd";	# Random check.
    }
  }
  $newdir{emx} = $emx if defined $emx;
}

# Called inside -p loop
if (/^(\w+)='(.*)'$/ and exists $change_from{$1} 
    and exists $newdir{$change_from{$1}}) {
  # Need to substitute
  my ($key, $val, $from, $to) 
    = ($1, $2, $dirs{$change_from{$1}}, $newdir{$change_from{$1}});
  $val =~ s/\Q$from\E/$to/g;		# g for the sake of libs - which is not edited now
  $_ = "$key='$val'\n";
}

## Called inside -p loop
#s{
#  = \'				# start of value
#  # Spaces are not allowed below:
#  \Q$from_name\E		# the leading part of the value - as string.
#  (?=
#   [\'/]			# As whole or before slash, but do not
#                                # substitute this.
#  )
# }
#{=\'$to}xo;

##   = \'				# Copy it.
##     $to			# Now substitute.
## }xo ;
EOP

close PL or die "close: $!";

#chdir $tmpdir1 or die "Cannot chdir to `$tmpdir1'";
system 'zip', '-uj', 'plINSTAL.zip', "$tmpdir1/*.pkg", "$tmpdir1/*.cmd", 
	"$tmpdir1/*.pl", "$tmpdir1/*.dsc", "$tmpdir1/*.ICF"
    and die "Cannot run zip\n";
#chdir .. or die "Cannot chdir to ..";


print STDOUT "#Installation files written to $tmpdir1.\n";
