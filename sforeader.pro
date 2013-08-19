PRO sforeader,file,structure=structure,commandfile=commandfile
; procedure to read in a .sfo file, determine the settings usesd, and
; return a structure with those settings into variable structure
; can also create a command file used to rerun sf.pro
; by default the program determines the command file name from the
; sfo file name listed in the sfo file.  Alternatively you can specify
; it with the variable "commandfile".  If commandfile='none' then no
; command file is written

c={sfofilestructure,o:' ',$
disp:0.0,zl:0.0,zu:0.0,zi:0.0,$
beginw:0.0,endw:0.0,w1:0.0,w2:0.0,weight:' ',$
rv:0.0,avmin:0.0,avmax:0.0,tempscale:0.0,galscale:0.0,$
results:' ',galnames:' ',gspec:' ',tempfile:' ',$
sfracrequire:0.0,grow:0.0,niter:0.0,nsigma:0.0,sigmasource:' '$
}

nlines=FILE_LINES(file)

IF(nlines LE 0)THEN BEGIN
   isuccess=0
   RETURN
ENDIF

; open the file
OPENR,1,file,ERROR = err

IF (err NE 0) THEN BEGIN 
   PRINT,!ERROR_STATE.MSG
   isuccess=0
   CLOSE,1
   RETURN
ENDIF

sf_installdir=GETENV('SF_INSTALLDIR')
;a.sf_workingdir=GETENV('SF_WORKINGDIR')
IF sf_installdir NE '' THEN BEGIN
;add a slash at the end of the path if there isn't one
   slashpos=STRPOS(sf_installdir,'/',/REVERSE_SEARCH)
   IF (slashpos NE STRLEN(sf_installdir)-1) THEN sf_installdir = sf_installdir + '/'
ENDIF ELSE BEGIN
   PRINT,'Environment variable SF_INSTALLDIR not set'
   PRINT,'Please set this environment variable to the directory that contains'
   PRINT,'the superfit installation.  E.g. put a line like the following in'
   PRINT,'your .bashrc or .cshrc (or other appropriate) file.'
   PRINT,'bash: export SF_INSTALLDIR=/home/howell/idl/superfit'
   PRINT,'csh: setenv SF_INSTALLDIR /home/howell/idl/superfit'
ENDELSE


line=' '
; read in the header
FOR i=0,nlines-1 DO BEGIN
   READF,1,line
   splitarr=strsplit(line,'=',/EXTRACT,COUNT=numsplits)
   IF numsplits GT 1 THEN BEGIN
      ;PRINT,splitarr[0]
      CASE splitarr[0] OF
         ';;o ':c.o=strtrim(splitarr[1],2)
         ';;disp ':c.disp=strtrim(splitarr[1],2)
         ';;zl ':c.zl=strtrim(splitarr[1],2)
         ';;zu ':c.zu=strtrim(splitarr[1],2)
         ';;zi ':c.zi=strtrim(splitarr[1],2)
         ';;beginw ':c.beginw=strtrim(splitarr[1],2)
         ';;endw ':c.endw=strtrim(splitarr[1],2)
         ';;weight ':c.weight=strtrim(splitarr[1],2)
         ';;Rv ':c.rv=strtrim(splitarr[1],2)
         ';;avmin ':c.avmin=strtrim(splitarr[1],2)
         ';;avmax ':c.avmax=strtrim(splitarr[1],2)
         ';;tempscale ':c.tempscale=strtrim(splitarr[1],2)
         ';;galscale ':c.galscale=strtrim(splitarr[1],2)
         ';;results ':c.results=strtrim(splitarr[1],2)
         ';;galnames ':c.galnames=strtrim(splitarr[1],2)
         ';;gspec ':c.gspec=strtrim(splitarr[1],2)
         ';;tempfile ':BEGIN
            tempfilereadin=strtrim(splitarr[1],2)
            IF STRPOS(tempfilereadin,sf_installdir) GE 0 THEN BEGIN
               ;the install directory is already in the sfo file
               c.tempfile=tempfilereadin
            ENDIF ELSE BEGIN
               ;the install directory needs to be
               ;added to complete the path
               c.tempfile=sf_installdir+tempfilereadin
            ENDELSE
         END
         ';;w1 ':c.w1=strtrim(splitarr[1],2)
         ';;w2 ':c.w2=strtrim(splitarr[1],2)
         ';;sfracrequire ':c.sfracrequire=strtrim(splitarr[1],2)
         ';;grow ':c.grow=strtrim(splitarr[1],2)
         ';;niter ':c.niter=strtrim(splitarr[1],2)
         ';;nsigma ':c.nsigma=strtrim(splitarr[1],2)
         ';;sigmasource ':c.sigmasource=strtrim(splitarr[1],2)
         ELSE:
      ENDCASE
;      pos=STREGEX(splitarr[0],';;o')
;      IF pos GE 0 THEN 
   ENDIF
ENDFOR
CLOSE,1

galarr=strsplit(c.galnames,' ',/EXTRACT)
;turn the galaxy list galarr into a string
galaxy_string="["
FOR i=0,N_ELEMENTS(galarr)-1 DO BEGIN
   IF (c.galnames NE '') THEN galaxy_string=galaxy_string+"'"+galarr[i]+"',"
ENDFOR
;strip off the last comma
galaxy_string=STRMID(galaxy_string,0,STRLEN(galaxy_string)-1)
galaxy_string=galaxy_string+"]"

str1="sf,o='"+strtrim(c.o,2)
str2="',w1="+strtrim(c.w1,2)
str3=",w2="+strtrim(c.w2,2)
str4=",disp="+strtrim(c.disp,2)
str5=",zl="+strtrim(c.zl,2)
str6=",zu="+strtrim(c.zu,2)
str7=",zi="+strtrim(c.zi,2)
str8=",weight='"+strtrim(c.weight,2)
str9="',Rv="+strtrim(c.rv,2)
str10=",avmin="+strtrim(c.avmin,2)
str11=",avmax="+strtrim(c.avmax,2)
str12=",galscale="+strtrim(c.galscale,2)
str13=",tempscale="+strtrim(c.tempscale,2)
IF c.gspec NE ' ' THEN str14=",gspec='"+strtrim(c.gspec,2)+"'"  ELSE str14="" 
str15=",galnames="+galaxy_string
str16=",results='"+strtrim(c.results,2)
str17="',tempfile='"+strtrim(c.tempfile,2)
str18="',sfracrequire="+strtrim(c.sfracrequire,2)
str19=",sigmasource='"+strtrim(c.sigmasource,2)
str20="',niter="+strtrim(c.niter,2)
str21=",nsigma="+strtrim(c.nsigma,2)
str22=",grow="+strtrim(c.grow,2)

;have to do it this way because you can't use $ in a string
pstring=str1+str2+str3+str4+str5+str6+str7+str8+str9+str10+str11+str12+str13+str14+str15+str16+str17+str18+str19+str20+str21+str22

;; write command output file
IF N_ELEMENTS(commandfile) EQ 0 THEN BEGIN
   ;default case, produce .sfc file from .sfo filename
   sfcfilearr=strsplit(c.results,'sfo',/EXTRACT,/REGEX)
   sfcfile=sfcfilearr[0]+'sfc'
   OPENW,2,sfcfile
   PRINT,"Writing ",sfcfile
   PRINTF,2,pstring
   CLOSE,2
ENDIF ELSE BEGIN
   ;If a commandfile is specified, use it
   ;If the commandfile name is 'none' then don't write one.
   IF commandfile NE 'none' THEN BEGIN
      OPENW,2,commandfile
      PRINT,"Writing ",commandfile
      PRINTF,2,pstring
      CLOSE,2
   ENDIF
ENDELSE
 
structure=c

;PRINT,pstring

;sf,o=a.obsval,w1=a.w1val,w2=a.w2val,disp=a.dispval,$
;  zl=a.zlval,zu=a.zuval,zi=a.zival,weight=a.weight,Rv=a.rvval,$
;  avmin=a.avminval,avmax=a.avmaxval,galscale=a.galscaleval,$
;  tempscale=a.tempscaleval,gspec=a.usergalaxyval,$
;  galnames=a.galaxy,results=a.outputfile,tempfile=a.tempsavfile,$
;  sfracrequire=a.sfracrequireval,sigmasource=a.sigmasource,$
;  niter=a.niterval,nsigma=a.nsigval,grow=a.growval
 
END




















