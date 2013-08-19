This is superfit, version 3.5.  It requires IDL and the astrolib package.

IDL requirements:
It was tested under IDL 6.4.1.  It should work under IDL 8.1 as well.  

To check the version, do 
IDL> sfgui,/version
This works for sf.pro and sggui.pro too.

Installation:
I recommend renaming your current superfit directory to something like
'old_superfit' (but make sure it is something not in your IDL path)
and then copying the contents of this directory into the same
directory you had your old installation.  That way you won't have to
update things in idl starup files or add things to your IDL path.  Do
make sure you don't have a conflicting version of colordex.pro
somewhere outside the superfit directory (if you've never heard of
colordex.pro, don't worry about this).  You can use the idl program
which.pro (included) to check which one you are using, e.g.
IDL> which,'colordex'

Changes: 

- Updated library (thanks largely to Sagi Ben-Ami, and some to
Christopher White).  Sagi has called his version with this library
SuperSuperfit, but I'd like not to use that name to avoid confusion.
I have altered the updated libraries they provided, cropping some spectra
and fixing epochs and redshifts of others.

- New in this library:  SLSNe, 2002cx-likes, SN 2007bi, SN 2002bj, etc.

- SNe Ib/c now split into SN Ib and SN Ic.  New categories:  Others, 2002cx.

- Fixed a bug where at high redshift some fits were giving underflow
(divide by zero) errors.

- Fixed a bug where postscript plots had incorrect colors.

- Redshift is now given to 4 decimal places

- You can now import templates with up to 20,000 lines (this is easy to increase if necessary)

- New feature: You can start sfgui with a switch: /nogal .  This
unchecks all but one host galaxy and sets the maximum galaxy
contribution to zero.

- New feature: You can start sfgui with a keyword, 'library' to
preselect the SN template library so you don't have to select it from
the dropdown menu.  The choices are:
'Ia','Ib','Ic',II','Others','allsne', '2002cx' and 'snelt10d' for supernovae
less than or equal to 10 days after max.
e.g. sfgui,library='Ia'

- Should now work with IDL 8.1

Old Installation instructions:
You need astrolib for IDL installed.

- My program is intended as a tool to help human classifiers.
I wouldn't trust what it does on its own.

- The automatic date determination, in particular, could be vastly improved.

You can all the files and documentation you'll need here:
http://qold.astro.utoronto.ca/howell/superfit/superfit.htm
login: superfit
password: $uperfit

You might need to put some things in whatever startup file you have that runs
when IDL is started.  Those are outlined in the email message below.
I have attached my idl startup file.

