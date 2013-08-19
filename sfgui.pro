;; superfit (gui version) by Andy Howell
;; for documentation see superfit.html

FUNCTION galtostr,I
CASE I OF
   0: RETURN,'E'
   1: RETURN,'S0'
   2: RETURN,'Sa'
   3: RETURN,'Sb'
   4: RETURN,'Sc'
   5: RETURN,'SB1'
   6: RETURN,'SB2'
   7: RETURN,'SB3'
   8: RETURN,'SB4'
   9: RETURN,'SB5'
   10: RETURN,'SB6'
ENDCASE
END

FUNCTION strtogal,str
CASE str OF
   'E': RETURN, 0
   'S0': RETURN, 1
   'Sa': RETURN, 2
   'Sb': RETURN, 3
   'Sc': RETURN, 4
   'SB1': RETURN, 5
   'SB2': RETURN, 6
   'SB3': RETURN, 7
   'SB4': RETURN, 8
   'SB5': RETURN, 9
   'SB6': RETURN, 10
ENDCASE
END

PRO okbutton, ev
WIDGET_CONTROL, ev.top, GET_UVALUE=a
WIDGET_CONTROL, a.obswid, GET_VALUE=obsin
WIDGET_CONTROL, a.zlwid, GET_VALUE=zlin
WIDGET_CONTROL, a.zuwid, GET_VALUE=zuin
WIDGET_CONTROL, a.ziwid, GET_VALUE=ziin
WIDGET_CONTROL, a.w1wid, GET_VALUE=w1in
WIDGET_CONTROL, a.w2wid, GET_VALUE=w2in
WIDGET_CONTROL, a.dispwid, GET_VALUE=dispin
WIDGET_CONTROL, a.rvwid, GET_VALUE=rvin
WIDGET_CONTROL, a.avminwid, GET_VALUE=avminin
WIDGET_CONTROL, a.avmaxwid, GET_VALUE=avmaxin
WIDGET_CONTROL, a.weightbuttonwid, GET_VALUE=weightin
WIDGET_CONTROL, a.userweightwid, GET_VALUE=userweightin
WIDGET_CONTROL, a.tempscalewid, GET_VALUE=tempscalein
WIDGET_CONTROL, a.galscalewid, GET_VALUE=galscalein
WIDGET_CONTROL, a.outputfilewid, GET_VALUE=outputfilein
galaxyin=intarr(12)
WIDGET_CONTROL, a.galaxybuttonwid, GET_VALUE=galaxyin
WIDGET_CONTROL, a.usergalaxywid, GET_VALUE=usergalaxyin
WIDGET_CONTROL, a.sfracrequirewid, GET_VALUE=sfracrequirein
WIDGET_CONTROL, a.sigmabuttonwid, GET_VALUE=sigmabuttonin
WIDGET_CONTROL, a.nsigwid, GET_VALUE=nsigin
WIDGET_CONTROL, a.growwid, GET_VALUE=growin
WIDGET_CONTROL, a.niterwid, GET_VALUE=niterin
a.obsval=obsin
a.zlval=zlin
a.zuval=zuin
a.zival=ziin
a.w1val=w1in
a.w2val=w2in
a.dispval=dispin
a.rvval=rvin
a.avminval=avminin
a.avmaxval=avmaxin
a.tempscaleval=tempscalein
a.galscaleval=galscalein
a.userweightval=userweightin
a.outputfile=outputfilein
a.usergalaxyval=usergalaxyin
a.sfracrequireval=sfracrequirein
a.nsigval=float(nsigin)
a.niterval=fix(niterin[0])
a.growval=fix(growin[0])

CASE weightin OF
    0: a.weight=a.sf_installdir+'savefiles/one.weight'
    1: a.weight=a.sf_installdir+'savefiles/no77.weight'
    2: a.weight=a.obsbrowsename
    3: a.weight=a.userweightval
ENDCASE

CASE sigmabuttonin OF
    0: a.sigmasource='input'
    1: a.sigmasource='calculate'
    2: a.sigmasource='none'
ENDCASE

galstr=' '

FOR I=0,N_ELEMENTS(galaxyin)-2 DO BEGIN
;; the above is -2 to avoid the user input button
    IF (galaxyin[I] eq 1) THEN BEGIN
        galstr=galtostr(I)
        IF N_ELEMENTS(galarray) eq 0 THEN galarray=galstr $
        ELSE galarray=[galarray,galstr]
    ENDIF
ENDFOR

;; have to treat a 1 element array differently from a multielement 
IF N_ELEMENTS(galarray) eq 0 THEN galarray = ''
IF N_ELEMENTS(galarray) eq 1 THEN a.galaxy[0] = galarray ELSE a.galaxy=galarray

WIDGET_CONTROL, ev.top, SET_UVALUE=a

WIDGET_CONTROL, ev.top, /DESTROY

;turn the galaxy list a.galaxy into a string
galaxy_string="["
FOR i=0,N_ELEMENTS(a.galaxy)-1 DO BEGIN
   IF (a.galaxy[i] NE '') THEN galaxy_string=galaxy_string+"'"+a.galaxy[i]+"',"
ENDFOR
;strip off the last comma
galaxy_string=STRMID(galaxy_string,0,STRLEN(galaxy_string)-1)
galaxy_string=galaxy_string+"]"

str1="sf,o='"+strtrim(a.obsval,2)
str2="',w1="+strtrim(a.w1val,2)
str3=",w2="+strtrim(a.w2val,2)
str4=",disp="+strtrim(a.dispval,2)
str5=",zl="+strtrim(a.zlval,2)
str6=",zu="+strtrim(a.zuval,2)
str7=",zi="+strtrim(a.zival,2)
str8=",weight='"+strtrim(a.weight,2)
str9="',Rv="+strtrim(a.rvval,2)
str10=",avmin="+strtrim(a.avminval,2)
str11=",avmax="+strtrim(a.avmaxval,2)
str12=",galscale="+strtrim(a.galscaleval,2)
str13=",tempscale="+strtrim(a.tempscaleval,2)
str14=",gspec='"+strtrim(a.usergalaxyval,2)
;do something with a.galaxy
str15="',galnames="+galaxy_string
str16=",results='"+strtrim(a.outputfile,2)
str17="',tempfile='"+strtrim(a.tempsavfile,2)
str18="',sfracrequire="+strtrim(a.sfracrequireval,2)
str19=",sigmasource='"+strtrim(a.sigmasource,2)
str20="',niter="+strtrim(a.niterval,2)
str21=",nsigma="+strtrim(a.nsigval,2)
str22=",grow="+strtrim(a.growval,2)

;have to do it this way because you can't use $ in a string
pstring=str1+str2+str3+str4+str5+str6+str7+str8+str9+str10+str11+str12+str13+str14+str15+str16+str17+str18+str19+str20+str21+str22

OPENW,2,'sf_command.txt'
PRINT,"Writing sf_command.txt"
PRINTF,2,pstring
CLOSE,2

sf,o=a.obsval,w1=a.w1val,w2=a.w2val,disp=a.dispval,$
  zl=a.zlval,zu=a.zuval,zi=a.zival,weight=a.weight,Rv=a.rvval,$
  avmin=a.avminval,avmax=a.avmaxval,galscale=a.galscaleval,$
  tempscale=a.tempscaleval,gspec=a.usergalaxyval,$
  galnames=a.galaxy,results=a.outputfile,tempfile=a.tempsavfile,$
  sfracrequire=a.sfracrequireval,sigmasource=a.sigmasource,$
  niter=a.niterval,nsigma=a.nsigval,grow=a.growval
;,errorflag=a.errorflag

;;PRINT,'sf,o=',a.obsval,',w1=',a.w1val',w2=',a.w2val


;restore user's settings
!P.THICK=a.oldthick    
!P.CHARTHICK=a.oldcharthick
!X.THICK=a.oldxthick   
!Y.THICK=a.oldythick   
!P.COLOR=a.oldcolor
!P.BACKGROUND=a.oldbackground

END

PRO cancelbutton,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=a
;restore user's settings
!P.THICK=a.oldthick    
!P.CHARTHICK=a.oldcharthick
!X.THICK=a.oldxthick   
!Y.THICK=a.oldythick   
!P.COLOR=a.oldcolor
!P.BACKGROUND=a.oldbackground
WIDGET_CONTROL, ev.top, /DESTROY
END


FUNCTION obsdo,a
;; Function to do everything that needs to be done when observation is
;; read in.  Called from obsbutton and obsreturn.

!p.background=colordex('white')

readfile,a.obsbrowsename,obsinw,obsinf,splitpos
IF splitpos GT 0 THEN $
   firsthalf=STRMID(a.obsbrowsename,0,splitpos) $
ELSE firsthalf = a.obsbrowsename 
a.outputfile=firsthalf+'.sfo'
WIDGET_CONTROL, a.outputfilewid, SET_VALUE=a.outputfile 
WIDGET_CONTROL,/HOURGLASS
PLOT,obsinw,obsinf,color=colordex('black')

WIDGET_CONTROL, a.w1wid, GET_VALUE=w1alreadythere
WIDGET_CONTROL, a.w2wid, GET_VALUE=w2alreadythere

IF w1alreadythere EQ ' ' THEN WIDGET_CONTROL, a.w1wid, SET_VALUE=obsinw(0)
IF w2alreadythere EQ ' ' THEN WIDGET_CONTROL, a.w2wid, SET_VALUE=obsinw(N_ELEMENTS(obsinw)-1)
END

PRO obsreturnpro,ev
;; reads in and plots data when return is pressed in observation text field
WIDGET_CONTROL, ev.top, GET_UVALUE=a
WIDGET_CONTROL, a.obswid, GET_VALUE=obsbrowsenamein
;; for some strange reason this makes obsbrowsename an array, so put
;; [0] to refer to a string
a.obsbrowsename=obsbrowsenamein[0]
IF (a.obsbrowsename ne '') THEN junk=obsdo(a)
WIDGET_CONTROL, ev.top, SET_UVALUE=a
END

PRO obsbuttonpro, ev
WIDGET_CONTROL, ev.top, GET_UVALUE=a
;; read in the default path directory from the file path.txt in the
;; superfit directory

filters = ['*.*','*.dat','*.fits','*.asc','*.txt','*.ascii']
obsbrowsenamein = DIALOG_PICKFILE(DIALOG_PARENT=panelgroup, /MUST_EXIST,$
                  /READ,$
                  FILTER=filters, $
                  PATH=a.sf_workingdir)
a.obsbrowsename = obsbrowsenamein
WIDGET_CONTROL, a.obswid, SET_VALUE=a.obsbrowsename
IF (a.obsbrowsename ne '') THEN junk=obsdo(a)
WIDGET_CONTROL, ev.top, SET_UVALUE=a
END

PRO galreturnpro,ev
;; reads in and plots data when return is pressed in galaxy text field
WIDGET_CONTROL, ev.top, GET_UVALUE=a
WIDGET_CONTROL, a.usergalaxywid, GET_VALUE=galbrowsename
WIDGET_CONTROL,/HOURGLASS
IF (galbrowsename[0] ne '') THEN BEGIN
   readfile,galbrowsename,plotw,plotf,splitpos
   PLOT,plotw,plotf,color=colordex('black')   
ENDIF
END

PRO weightreturnpro,ev
;; reads in and plots data when return is pressed in galaxy text field
WIDGET_CONTROL, a.userweightwid, GET_VALUE=weightbrowsename
WIDGET_CONTROL,/HOURGLASS
IF (weightbrowsename ne '') THEN BEGIN 
   readfile,weightbrowsename,plotw,plotf,splitpos
   PLOT,plotw,plotf,color=colordex('black')
ENDIF
WIDGET_CONTROL, ev.top, GET_UVALUE=a
END

PRO galbrowsepro, ev
WIDGET_CONTROL, ev.top, GET_UVALUE=a

;; read in the default path directory from the file path.txt in the
;; superfit directory

galbrowsename = DIALOG_PICKFILE(DIALOG_PARENT=galgroup, /MUST_EXIST,/READ,$
                                 FILTER=['*.dat','*.fits'],PATH=a.sf_workingdir)
WIDGET_CONTROL, a.usergalaxywid, SET_VALUE=galbrowsename 
WIDGET_CONTROL,/HOURGLASS
IF (galbrowsename ne '') THEN BEGIN
   readfile,galbrowsename,galinw,galinf,splitpos
   PLOT,galinw,galinf,color=colordex('black')
ENDIF
WIDGET_CONTROL, ev.top, SET_UVALUE=a
END

PRO weightbrowsepro, ev
WIDGET_CONTROL, ev.top, GET_UVALUE=a

weightbrowsename = DIALOG_PICKFILE(DIALOG_PARENT=weightgroup, /MUST_EXIST,$
      /READ,FILTER='',PATH=a.sf_workingdir)

WIDGET_CONTROL, a.userweightwid, SET_VALUE=weightbrowsename
WIDGET_CONTROL,/HOURGLASS
IF (weightbrowsename ne '') THEN BEGIN 
   readfile,weightbrowsename,weightinw,weightinf,splitpos
   PLOT,weightinw,weightinf,color=colordex('black')
ENDIF
WIDGET_CONTROL, ev.top, SET_UVALUE=a
END

PRO tempbuttonpro, ev
WIDGET_CONTROL, ev.top, GET_UVALUE=a
CASE ev.index OF
    0: a.tempsavfile=a.sf_installdir+'savefiles/snelt10d.idlsave'
    1: a.tempsavfile=a.sf_installdir+'savefiles/allsne.idlsave'
    2: a.tempsavfile=a.sf_installdir+'savefiles/Ia.idlsave'
    3: a.tempsavfile=a.sf_installdir+'savefiles/Ib.idlsave'
    4: a.tempsavfile=a.sf_installdir+'savefiles/Ic.idlsave'
    5: a.tempsavfile=a.sf_installdir+'savefiles/II.idlsave'
    6: a.tempsavfile=a.sf_installdir+'savefiles/Others.idlsave'
    7: a.tempsavfile=a.sf_installdir+'savefiles/2002cx.idlsave'
ENDCASE
WIDGET_CONTROL, a.zlwid, GET_VALUE=zlin
WIDGET_CONTROL, a.zuwid, GET_VALUE=zuin
WIDGET_CONTROL, a.ziwid, GET_VALUE=ziin
WIDGET_CONTROL, a.w1wid, GET_VALUE=w1in
WIDGET_CONTROL, a.w2wid, GET_VALUE=w2in
IF zlin[0] ne '' THEN a.zlval=zlin ELSE zlin=0
IF zuin[0] ne '' THEN a.zuval=zuin ELSE zuin=0
IF ziin[0] ne '' THEN a.zival=ziin ELSE ziin=0
;a.zuval=zuin
;a.zival=ziin
a.w1val=w1in
a.w2val=w2in
WIDGET_CONTROL,/HOURGLASS
IF (a.zlval eq a.zuval) THEN junk=srange_gui(a.tempsavfile,a.w1val,a.w2val,a.zlval) $
ELSE BEGIN
    IF (a.zival) eq 0 THEN a.zival=0.01
    junk=zrange_gui(a.tempsavfile,a.w1val,a.w2val,a.zlval,a.zuval,a.zival)
ENDELSE

WIDGET_CONTROL, ev.top, SET_UVALUE=a
END


FUNCTION galbuttonfunc,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=a
galaxybuttonin=intarr(12)
WIDGET_CONTROL, a.galaxybuttonwid, GET_VALUE=galaxybuttonin
IF galaxybuttonin[11] eq 1 THEN WIDGET_CONTROL, a.galaxybrowsegroup, SENSITIVE=1
IF galaxybuttonin[11] eq 0 THEN WIDGET_CONTROL, a.galaxybrowsegroup, SENSITIVE=0
WIDGET_CONTROL, ev.top, SET_UVALUE=a
END

FUNCTION weightbuttonfunc,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=a
WIDGET_CONTROL, a.weightbuttonwid, GET_VALUE=weightbuttonin
WIDGET_CONTROL, a.sigmabuttonwid, GET_VALUE=sigmabuttonin
;IF ((weightbuttonin EQ 0) OR (weightbuttonin eq 1)) AND (sigmabuttonin EQ 0) THEN $
;  WIDGET_CONTROL, a.sigmabuttonwid, SET_BUTTON=1  this doesn't work

IF weightbuttonin eq 3 THEN WIDGET_CONTROL, a.weightbrowsegroup, SENSITIVE=1
IF weightbuttonin ne 3 THEN WIDGET_CONTROL, a.weightbrowsegroup, SENSITIVE=0
WIDGET_CONTROL, ev.top, SET_UVALUE=a
END

FUNCTION sigmabuttonfunc,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=a
WIDGET_CONTROL, a.sigmabuttonwid, GET_VALUE=sigmabuttonin
IF sigmabuttonin eq 2 THEN WIDGET_CONTROL, a.numsiggroup, SENSITIVE=0 $
    ELSE WIDGET_CONTROL, a.numsiggroup, SENSITIVE=1
WIDGET_CONTROL, ev.top, SET_UVALUE=a
END

PRO redrawbutton,ev
!p.background=colordex('white')

WIDGET_CONTROL, ev.top, GET_UVALUE=a
WIDGET_CONTROL, a.sigmabuttonwid, GET_VALUE=sigmabuttonin
WIDGET_CONTROL, a.nsigwid, GET_VALUE=nsigin
WIDGET_CONTROL, a.weightbuttonwid, GET_VALUE=weightin
WIDGET_CONTROL, a.userweightwid, GET_VALUE=userweightin
WIDGET_CONTROL, a.w1wid, GET_VALUE=w1in
WIDGET_CONTROL, a.w2wid, GET_VALUE=w2in
WIDGET_CONTROL, a.growwid, GET_VALUE=growin
WIDGET_CONTROL, a.niterwid, GET_VALUE=niterin
a.w1val=w1in[0]
a.w2val=w2in[0]
a.nsigval=float(nsigin)
a.niterval=fix(niterin[0])
a.growval=fix(growin[0])
a.userweightval=userweightin

IF (sigmabuttonin EQ 1) THEN BEGIN
   ; calculate standard deviation from spectrum
   readfile,a.obsbrowsename,obsinw,obsinf,splitpos
   cleanedspectrum=lineclean(obsinw,obsinf,a.nsigval,a.growval,a.niterval)
ENDIF ELSE BEGIN 
   IF (sigmabuttonin EQ 0) THEN BEGIN
      CASE weightin OF
         2: readfile,a.obsbrowsename,obsinw,obsinf,splitpos,sigma=sigmain,/threecolflag
         3: readfile,a.userweightval,sigmaw,sigmain,splitpos
      ENDCASE
      IF (weightin NE 2) THEN readfile,a.obsbrowsename,obsinw,obsinf,splitpos
      cleanedspectrum=lineclean(obsinw,obsinf,a.nsigval,a.growval,a.niterval,sigmain)
   ENDIF ELSE BEGIN
      ; "none" chosen for sigma, sigmabutton=2
      readfile,a.obsbrowsename,obsinw,obsinf,splitpos
      cleanedspectrum=obsinf
   ENDELSE
ENDELSE

; cut off input spectrum at wavelengths less than w1
IF KEYWORD_SET(a.w1val) THEN BEGIN 
   w=where(obsinw GE a.w1val)
   obsinw=obsinw[w]
   obsinf=obsinf[w]
   IF N_ELEMENTS(cleanedspectrum) NE 0 THEN cleanedspectrum=cleanedspectrum[w]
ENDIF

; cut off input spectrum at wavelengths greater than w2
IF KEYWORD_SET(a.w2val) THEN BEGIN 
   w=where(obsinw LE a.w2val)
   obsinw=obsinw[w]
   obsinf=obsinf[w]
   IF N_ELEMENTS(cleanedspectrum) NE 0 THEN cleanedspectrum=cleanedspectrum[w]
ENDIF

IF N_ELEMENTS (cleanedspectrum) NE 0 THEN BEGIN
   PLOT,obsinw,obsinf,color=colordex('black'),/NODATA
   OPLOT,obsinw,obsinf,color=colordex('red')
   OPLOT,obsinw,cleanedspectrum,color=colordex('black')
ENDIF ELSE PLOT,obsinw,obsinf,color=colordex('black')

WIDGET_CONTROL, ev.top, SET_UVALUE=a
END

PRO sfgui_event,ev
;; needs to be here for slider
END

PRO sfgui,version=version,file=file,nogal=nogal,library=library
IF KEYWORD_SET(version) THEN BEGIN 
   print,"sfgui.pro Version 3.5 August 30, 2012.  Author: Andy Howell."
   print,"Documentation at: http://qold.astro.utoronto.ca/~howell/superfit/superfit.htm"
   GOTO,endpoint
ENDIF

a={strname,drawwid:0l,drawbuttonwid:0l,$
   weightbuttonwid:0l,weight:' ',$
   userweightwid:0l,userweightval:' ',$
   galaxybuttonwid:0l,galaxy:strarr(12),$
   tempbuttonwid:0l,tempsavfile:'',$
   outputfilewid:0l,outputfile:' ',$
   obsbrowsename:' ',$
   usergalaxywid:0l,usergalaxyval:' ',$
   galaxybrowsegroup:0l,galbrowsewid:0l,$
   weightbrowsegroup:0l,weightbrowsewid:0l,$
   obswid:0l,obsval:' ',$
   zlwid:0l, zlval:0.0,$
   zuwid:0l, zuval:0.0,$
   ziwid:0l, zival:0.0,$
   w1wid:0l, w1val:0.0,$
   w2wid:0l, w2val:0.0,$
   dispwid:0l, dispval:0.0,$
   avminwid:0l, avminval:0.0,$
   avmaxwid:0l, avmaxval:0.0,$
   rvwid:0l, rvval:0.0, $
   galscalewid:0l, galscaleval:0.0,$
   tempscalewid:0l, tempscaleval:0.0,$
   sigmabuttonwid:0l, numsiggroup:0l,$
   oldthick:1,oldcharthick:1,oldxthick:1,$
   oldythick:1,oldcolor:0,oldbackground:0,$
   nsigwid:0l,nsigval:0.0,$
   growwid:0l,growval:0.0,$
   niterval:0.0,niterwid:0l,$
   sigmasource:' ',sf_installdir:'',sf_workingdir:'',$
   sfracrequirewid:0l, sfracrequireval:0.0$
  }

;save user's settings
a.oldthick=!P.THICK
a.oldcharthick=!P.CHARTHICK
a.oldxthick=!X.THICK
a.oldythick=!Y.THICK
a.oldcolor=!P.COLOR
a.oldbackground=!P.BACKGROUND

!p.background=colordex('white')
a.sf_installdir=GETENV('SF_INSTALLDIR')
a.sf_workingdir=GETENV('SF_WORKINGDIR')

; add trailing slashes to the paths if necessary
IF a.sf_workingdir NE '' THEN BEGIN
;add a slash at the end of the path if there isn't one
   slashpos=STRPOS(a.sf_workingdir,'/',/REVERSE_SEARCH)
   IF (slashpos NE STRLEN(a.sf_workingdir)-1) THEN a.sf_workingdir = a.sf_workingdir + '/'
ENDIF ELSE BEGIN
   PRINT,'Using current working directory as default for browsing'  
   PRINT,'To use a different default, set the environment variable SF_WORKINGDIR'
   PRINT,''
ENDELSE

IF a.sf_installdir NE '' THEN BEGIN
;add a slash at the end of the path if there isn't one
   slashpos=STRPOS(a.sf_installdir,'/',/REVERSE_SEARCH)
   IF (slashpos NE STRLEN(a.sf_installdir)-1) THEN a.sf_installdir = a.sf_installdir + '/'
ENDIF ELSE BEGIN
   PRINT,'Environment variable SF_INSTALLDIR not set'
   PRINT,'Please set this environment variable to the directory that contains'
   PRINT,'the superfit installation.  E.g. put a line like the following in'
   PRINT,'your .bashrc or .cshrc (or other appropriate) file.'
   PRINT,'bash: export SF_INSTALLDIR=/home/howell/idl/superfit'
   PRINT,'csh: setenv SF_INSTALLDIR /home/howell/idl/superfit'
   GOTO,endpoint
ENDELSE


;; groups defined
base = WIDGET_BASE(/ROW,TITLE='superfit')
panelgroup = WIDGET_BASE(base,/COLUMN)
drawgroup = WIDGET_BASE(base,/COLUMN,/FRAME)
drawbuttongroup = WIDGET_BASE(drawgroup,/ROW,/FRAME)
a.drawbuttonwid = WIDGET_LABEL(drawgroup,$
     VALUE='Select a file with browse or type one and hit return to display it.')
wholeobsgroup = WIDGET_BASE(panelgroup,/COLUMN,/FRAME)
obsgroup = WIDGET_BASE(wholeobsgroup,/ROW)
label = WIDGET_LABEL(obsgroup,VALUE='Observation: ')
a.obswid = WIDGET_TEXT(obsgroup,/EDITABLE,XSIZE=45,EVENT_PRO='obsreturnpro')
obsbutton = WIDGET_BUTTON(obsgroup, VALUE=' Browse... ',$
                          event_pro='obsbuttonpro')
outputgroup = WIDGET_BASE(wholeobsgroup, /ROW)
label = WIDGET_LABEL(outputgroup,VALUE='Output file: ')
a.outputfilewid = WIDGET_TEXT(outputgroup,/EDITABLE,XSIZE=59)
clipgroup = WIDGET_BASE(panelgroup,/ROW)
wavelnrow = WIDGET_BASE(clipgroup,/COLUMN,/FRAME)
sigclipgroup = WIDGET_BASE(clipgroup,/COLUMN,/FRAME)
sigmagroup = WIDGET_BASE(sigclipgroup,/ROW)
numsigredrawgroup = WIDGET_BASE(sigclipgroup,/ROW)
a.numsiggroup = WIDGET_BASE(numsigredrawgroup,/ROW)
zrow = WIDGET_BASE(panelgroup,/ROW,/FRAME)
tempgroup = WIDGET_BASE(panelgroup,/COLUMN,/FRAME,/ALIGN_CENTER)
temprow = WIDGET_BASE(tempgroup,/ROW)
temprow1 = WIDGET_BASE(temprow,/ROW,/ALIGN_CENTER)
tempbuttontext=['SNe <= 10d',$
                'All SNe','Ia','Ib','Ic','II','Others','2002cx']
;a.tempbuttonwid = WIDGET_DROPLIST(temprow,TITLE='Templates: ',$
;   VALUE=tempbuttontext,EVENT_PRO='tempbuttonpro')
temptextwid = WIDGET_LABEL(temprow1,VALUE='Templates: ')
a.tempbuttonwid = WIDGET_COMBOBOX(temprow1,$
   VALUE=tempbuttontext,EVENT_PRO='tempbuttonpro')
;set default for tempsavfile in case no one selects it from the
;drop-down
IF N_ELEMENTS(library) EQ 0 THEN library='snelt10d'
CASE library OF
   'snelt10d'     : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=0
   'allsne'       : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=1
   'Ia'           : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=2
   'Ib'          : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=3
   'Ic'          : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=4
   'II'           : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=5
   'Others'          : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=6
   '2002cx'          : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=7
ENDCASE
a.tempsavfile=a.sf_installdir+'savefiles/'+library+'.idlsave'

;a.tempsavfile=a.sf_installdir+'savefiles/snelt10d.idlsave'
;WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=WHERE(tempbuttontext EQ 'SNe <= 10d')
;temprow2 = WIDGET_BASE(temprow,/COLUMN,/ALIGN_RIGHT)
a.dispwid = CW_FIELD(temprow, TITLE = "Binning in Angstroms: ",VALUE=20, $
                     XSIZE=5)
a.sfracrequirewid = CW_FSLIDER(tempgroup, TITLE = $
   "Required template wavelength coverage ",MINIMUM=0,MAXIMUM=1.0,VALUE=0.7,$
   /EDIT,/DRAG,XSIZE=460,FORMAT='(F13.2)')
;requirelabel = $
;  'Require templates to have full wavelength coverage'
;a.requirefullwavwid = CW_BGROUP(tempgroup, requirelabel, $
;                                 /NONEXCLUSIVE,SET_VALUE=[0])


weightgalaxygroup=WIDGET_BASE(panelgroup,/ROW)
galaxygroup = WIDGET_BASE(weightgalaxygroup,/COLUMN,/FRAME)
weightgroup = WIDGET_BASE(weightgalaxygroup,/COLUMN,/FRAME)
;galaxygroup = WIDGET_BASE(panelgroup,/COLUMN,/FRAME)
;weightgroup = WIDGET_BASE(panelgroup,/COLUMN,/FRAME)
scalegroup=WIDGET_BASE(panelgroup,/ROW)
reddeninggroup=WIDGET_BASE(panelgroup,/ROW,/FRAME)

a.zlwid = CW_FIELD(zrow, TITLE = "z lower: ", XSIZE=7)
a.zuwid = CW_FIELD(zrow, TITLE = "z upper: ", XSIZE=7)
a.ziwid = CW_FIELD(zrow, TITLE = "z increment: ", XSIZE=7)
a.w1wid = CW_FIELD(wavelnrow, TITLE = "Beg. Wavelength: ",XSIZE=9)
a.w2wid = CW_FIELD(wavelnrow, TITLE = "End  Wavelength: ",XSIZE=9)
sigmabuttonnames=['input','calculate','none']
a.sigmabuttonwid = CW_BGROUP(sigmagroup, sigmabuttonnames, COLUMN=3,$
   /EXCLUSIVE,SET_VALUE=[1],LABEL_LEFT='Sigma: ',EVENT_FUNC='sigmabuttonfunc')
a.nsigwid = CW_FIELD(a.numsiggroup, TITLE = "nsigma:",XSIZE=3,VALUE=2.7)
a.growwid = CW_FIELD(a.numsiggroup, TITLE = "grow:",XSIZE=2,VALUE=0)
a.niterwid = CW_FIELD(a.numsiggroup, TITLE = "niter:",XSIZE=2,VALUE=5)

IF KEYWORD_SET(nogal) THEN galslider=0.0 ELSE galslider=3.0
a.galscalewid = CW_FSLIDER(scalegroup, TITLE = "Maximum galaxy scaling",$
   MINIMUM=0,MAXIMUM=3.0,VALUE=galslider,/EDIT,/DRAG,XSIZE=225,/FRAME)
a.tempscalewid = CW_FSLIDER(scalegroup, TITLE = "Maximum template scaling",$
   MINIMUM=0,MAXIMUM=3.0,VALUE=3.0,/EDIT,/DRAG,XSIZE=225,/FRAME)
a.avminwid = CW_FIELD(reddeninggroup, TITLE = "Minimum Av: ", VALUE=-2, XSIZE=7)
a.avmaxwid = CW_FIELD(reddeninggroup, TITLE = "Maximum Av: ", VALUE=2, XSIZE=7)
a.rvwid = CW_FIELD(reddeninggroup, TITLE = "Rv: ", VALUE=3.1, XSIZE=5)

;; galaxies
galnames = ['E','S0','Sa','Sb','Sc','SB1','SB2','SB3','SB4','SB5','SB6',$
            'User input:']
IF KEYWORD_SET(nogal) THEN galbuttons=[1,0,0,0,0,0,0,0,0,0,0,0] ELSE galbuttons=[1,1,1,1,1,0,0,0,0,0,0,0] 
a.galaxybuttonwid = CW_BGROUP(galaxygroup, galnames, COLUMN=3,$
   EVENT_FUNCT='galbuttonfunc',/NONEXCLUSIVE,$
   LABEL_TOP='Galaxies:',SET_VALUE=galbuttons)
a.galaxybrowsegroup = WIDGET_BASE(galaxygroup,/ROW,SENSITIVE=0)
a.usergalaxywid = WIDGET_TEXT(a.galaxybrowsegroup,/EDITABLE,$
  EVENT_PRO='galreturnpro')
a.galbrowsewid = WIDGET_BUTTON(a.galaxybrowsegroup, VALUE=' Browse... ',$
  event_pro='galbrowsepro')

;; weights
weightnames = ['Unweighted','Telluric deweighted','Sigma in 3rd column', 'User input:']
a.weightbuttonwid = CW_BGROUP(weightgroup, weightnames,/EXCLUSIVE,COLUMN=1,$
 LABEL_TOP='Weights:', SET_VALUE=1,/NO_RELEASE,EVENT_FUNCT='weightbuttonfunc') 
a.weightbrowsegroup = WIDGET_BASE(weightgroup,/ROW,SENSITIVE=0)
a.userweightwid = WIDGET_TEXT(a.weightbrowsegroup,/EDITABLE, $
                              EVENT_PRO='weightreturnpro')
;errorlabel = ['Normal','Errors']
;a.errorbuttonwid = CW_BGROUP(weightgroup, errorlabel,/EXCLUSIVE,COLUMN=2,$
; LABEL_LEFT='Behavior:', SET_VALUE=0,/NO_RELEASE,EVENT_FUNCT='errorbuttonfunc') 
a.galbrowsewid = WIDGET_BUTTON(a.weightbrowsegroup, VALUE=' Browse... ',$
                          event_pro='weightbrowsepro')

a.drawwid = WIDGET_DRAW(drawgroup,XSIZE=512,YSIZE=512)
;a.textwid = WIDGET_TEXT(drawgroup,YSIZE=7)

;; OK and Cancel buttons:
botbar = WIDGET_BASE(panelgroup,/row,uvalue='Botbar')
button1 = WIDGET_BUTTON(botbar, VALUE='    OK    ', $
                        UVALUE='OKbutton',event_pro='okbutton')
button4 = WIDGET_BUTTON(botbar, value='  Cancel  ', UVALUE='CANCEL',event_pro='cancelbutton')
redrawbutton = WIDGET_BUTTON(botbar, value=' Redraw ', UVALUE='Redraw',event_pro='redrawbutton')


WIDGET_CONTROL, base, SET_UVALUE=a
WIDGET_CONTROL, base, /REALIZE

;; set up draw box -- have to do this after realize
WIDGET_CONTROL, a.drawwid, GET_VALUE = index
WSET, index

;trying to add fuctionality so that if you pass in 
; an sfo file it will read the previously run values
; into the gui
IF N_ELEMENTS(file) NE 0 THEN BEGIN
   sforeader,file,structure=c,commandfile='none'
   WIDGET_CONTROL,a.obswid,SET_VALUE=c.o
   a.obsbrowsename=c.o
   ;make an array out of galaxy names
   galarr=strsplit(c.galnames,' ',/EXTRACT)
   galbuttonarr=intarr(12)
                                
   ;press correct buttons on gui corresponding to gal names
   FOR I=0,N_ELEMENTS(galarr)-1 DO BEGIN
      buttonnum=strtogal(galarr[I])
      galbuttonarr[buttonnum]=1
   ENDFOR

   ;deal with case where there is a user input galaxy
   IF c.gspec NE ' ' THEN BEGIN
      galbuttonarr[11]=1
      WIDGET_CONTROL, a.usergalaxywid, SET_VALUE=c.gspec 
      WIDGET_CONTROL, a.galaxybrowsegroup, SENSITIVE=1
   ENDIF

   WIDGET_CONTROL,a.galaxybuttonwid,SET_VALUE=galbuttonarr

;    WIDGET_CONTROL,a.outputfilewid,SET_VALUE=c.results
   WIDGET_CONTROL,a.nsigwid,SET_VALUE=c.nsigma
   WIDGET_CONTROL,a.growwid,SET_VALUE=c.grow
   WIDGET_CONTROL,a.niterwid,SET_VALUE=c.niter    
   WIDGET_CONTROL,a.zlwid,SET_VALUE=c.zl   
   WIDGET_CONTROL,a.zuwid,SET_VALUE=c.zu   
   WIDGET_CONTROL,a.ziwid,SET_VALUE=c.zi   
   WIDGET_CONTROL,a.avminwid,SET_VALUE=c.avmin   
   WIDGET_CONTROL,a.avmaxwid,SET_VALUE=c.avmax   
   WIDGET_CONTROL,a.rvwid,SET_VALUE=c.rv   
   WIDGET_CONTROL,a.dispwid,SET_VALUE=c.disp   
   WIDGET_CONTROL,a.galscalewid,SET_VALUE=c.galscale
   WIDGET_CONTROL,a.tempscalewid,SET_VALUE=c.tempscale  
   WIDGET_CONTROL,a.sfracrequirewid,SET_VALUE=c.sfracrequire 
   CASE c.sigmasource OF
      'input': WIDGET_CONTROL,a.sigmabuttonwid,SET_VALUE=[0]
      'calculate': WIDGET_CONTROL,a.sigmabuttonwid,SET_VALUE=[1]
      'none': WIDGET_CONTROL,a.sigmabuttonwid,SET_VALUE=[2]
   ENDCASE
   
   temppatharr=strsplit(c.tempfile,'/',/EXTRACT,/REGEX)
   tempfilename=temppatharr[N_ELEMENTS(temppatharr)-1]
   a.tempsavfile=a.sf_installdir+'savefiles/'+tempfilename
   CASE tempfilename OF
      'snelt10d.idlsave'     : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=0
      'allsne.idlsave'       : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=1
      'Ia.idlsave'           : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=2
      'Ib.idlsave'          : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=3
      'Ic.idlsave'          : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=4
      'II.idlsave'           : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=5
      'Others.idlsave'          : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=6
      '2002cx.idlsave'          : WIDGET_CONTROL,a.tempbuttonwid,SET_COMBOBOX_SELECT=7
   ENDCASE

;    weightarr=strsplit(c.weightfile,'/',/EXTRACT,/REGEX)
;    weightname=weightarr[N_ELEMENTS(weightarr)-1]

   a.weight=c.weight
   CASE c.weight OF
   
      a.sf_installdir+'savefiles/one.weight': WIDGET_CONTROL,a.weightbuttonwid,SET_VALUE=[0]
      a.sf_installdir+'savefiles/no77.weight': WIDGET_CONTROL,a.weightbuttonwid,SET_VALUE=[1]
      c.o: WIDGET_CONTROL,a.weightbuttonwid,SET_VALUE=[2]
      ELSE:BEGIN
         WIDGET_CONTROL, a.weightbuttonwid,SET_VALUE=[3]
         WIDGET_CONTROL, a.weightbrowsegroup, SENSITIVE=1
         WIDGET_CONTROL, a.userweightwid, SET_VALUE=c.weight
         a.userweightval=c.weight
      ENDELSE
   ENDCASE

   WIDGET_CONTROL,a.w1wid,SET_VALUE=c.w1    
   WIDGET_CONTROL,a.w2wid,SET_VALUE=c.w2    

   WIDGET_CONTROL, base, SET_UVALUE=a
  
   junk=obsdo(a)
ENDIF            



XMANAGER, 'sfgui', base


endpoint:
END
