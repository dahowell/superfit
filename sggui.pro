;; supergraph (gui version) by Andy Howell
;; for documentation see superfit.html

FUNCTION draw,b
WIDGET_CONTROL,b.legendxwid,GET_VALUE=legendxin     
WIDGET_CONTROL,b.legendywid,GET_VALUE=legendyin     
b.legendxval=legendxin
b.legendyval=legendyin

I=b.selected

;; define graph properties
IF (b.psflag) THEN BEGIN
   SET_PLOT,'ps'
   ;need /isolatin1 in call to device to get
   ;angstrom symbol when !P.FONT=0
   !P.FONT=0 ;uses postscript (as opposed to vector) font
   DEVICE,filename=b.psfile,/color,/isolatin1
   mycharthick=2.0
   mycharsize=1.2
   mythick=2.0
   mylegendxoffset=0.01
   mylegendyoffset=0.01
ENDIF ELSE BEGIN
   mycharthick=1.0
   mycharsize=1.5
   mythick=1.0
   mylegendxoffset=0
   mylegendyoffset=0
ENDELSE

;; need to put this stuff in to use deepcolor
;; defined on our system, but include here for portability
defsysv,'!top_color',0b
defsysv,'!top_colorx',0b
defsysv,'!top_colorps',255b
defsysv,'!colorstr',''
defsysv,'!colorstr_ps',''
defsysv,'!colorstr_x',''
deepcolor

!P.THICK=mythick
!P.CHARTHICK=mycharthick
!X.THICK=mythick
!Y.THICK=mythick
!P.BACKGROUND=colordex('white')
ang=string(197b)
normalcolor='black'

;; do the calculations/graphing
IF ((b.S[I] gt 0) and (b.S[I] lt 999)) THEN BEGIN
; need to do this here because obsinwar can't be a structure
; arrays in structures have to have a predetermined number of elements
    junk=zerostrip(b.obsinw,b.obsinf,obsinwar,obsinfar)
    junk=zerostrip(b.tempwred,b.tempinf,tempwredar,tempinfar)
    junk=zerostrip(b.galwred,b.galinf,galwredar,galinfar)
    junk=zerostrip(b.weightinw,b.weightinf,weightwar,weightfar)
    
;line cleaning stuff was here but moved to infiledo
;put in weight stuff here so the weighted binning works


;    ;make sure weights are sampled at same points as flux
;    LINTERP,weightwar,weightfar,obsinwar,weightfar
;    ;call fixgap which fixes gaps in the spectrum if any exist
;    fixgap,obsinwar,obsinfar,weightfar,obsinwar,obsinfar,weightfar


    obsf=double(binspec_weighted(obsinwar,obsinfar,b.beginwval,b.endwval,b.disp,obsw,weightwar,weightfar,weightfbinned))
    tempf=double(binspec_weighted(tempwredar,tempinfar,b.beginwval,b.endwval,b.disp,tempw))
    galf=double(binspec_weighted(galwredar,galinfar,b.beginwval,b.endwval,b.disp,galw))

    ;; need to keep reddening in unredshifted frame
    zp1= 1.0 + b.z[I]
    unredshiftedw=obsw/zp1
    redlawf=mkafromlam(unredshiftedw,b.rv)
    
    
    obsminusgal=dblarr(N_ELEMENTS(obsf))
    exttempf=dblarr(N_ELEMENTS(obsf))
    
    FOR P=0,N_ELEMENTS(obsf)-1 DO $
      obsminusgal[p]=(obsf[p]-b.ff[I]*galf[p])

    ;calculate extinction corrected template
    FOR P=0,N_ELEMENTS(obsf)-1 DO $
      exttempf[p]=b.cc[I]*tempf[p]*10^(-b.av[I]*redlawf[p]/2.5)

    ;do smoothing
    IF (b.smsubselected OR b.smorigselected) THEN BEGIN
        ;sgsmooth_obsminusgal=dblarr(N_ELEMENTS(obsf))
        sgsmooth_obsinfar=dblarr(N_ELEMENTS(obsinfar))
        sgcoeff=SAVGOL(b.npixval,b.npixval,0,b.degreeval)
        sgsmooth_obsinfar=CONVOL(obsinfar,sgcoeff,/EDGE_TRUNCATE)
        ;need to rebin smoothed observations to subtract galaxy
        ;but binning can be anything.  do not need to weight because
        ;smoothing destroys info about how to weight 
        ;in the future think about how to smooth using weight info

        galf_forsmooth=double(binspec_weighted(galwredar,galinfar,b.beginwval,b.endwval,1.0,galw_forsmooth))
        sgsmooth_obsf=double(binspec_weighted(obsinwar,sgsmooth_obsinfar,b.beginwval,$
                                     b.endwval,1.0,sgsmooth_obsw))
        sgsmooth_obsminusgal=sgsmooth_obsf-b.ff[I]*galf_forsmooth
    ENDIF


    !Y.MARGIN=[4,4]
    ;; plot z label
    zstring = 'z='+string(b.z[I], format='(f6.4)')
    reststr='Rest Wavelength ['+ang+'] at '+zstring
    ;fluxstr='Flux [erg cm!U-2!N s!U-1!N '+ang+'!U-1!N]  (arbitrary units)'
    fluxstr='F!D!Ml!X!N (normalized)'
    obswavstr='Observed Wavelength ['+ang+']'

    ;set it so that if you have 0 for
    ;minimum or max values, IDL will choose axes
    IF (b.xmin EQ 0 AND b.xmax EQ 0) THEN xstyleval=8 ELSE xstyleval=9
    IF (b.ymin EQ 0 AND b.ymax EQ 0) THEN ystyleval=0 ELSE ystyleval=1

    ;; plot axes
    plot,obsw,obsminusgal,psym=10,linestyle=0, $
         title=titlestr, xtitle=obswavstr, charthick=mycharthick,$
         xstyle=xstyleval,thick=mythick, charsize=mycharsize,$
         ytitle=fluxstr,/nodata, color=colordex(normalcolor),$
         yrange=[b.ymin,b.ymax],xrange=[b.xmin,b.xmax],ystyle=ystyleval
    AXIS,XAXIS=1,XRANGE=!X.CRANGE/zp1,XSTYLE=1,$
         charthick=mycharthick,charsize=mycharsize, color=colordex(normalcolor)

    ;put the rest frame axis on top --
    ;have to do it using xyouts to move it up some
    XYOUTS, 0.5, !y.window[1] + 2.2*!d.y_ch_size/!d.y_vsize, /NORMAL, ALIGN=0.5, reststr ,/NOCLIP,color=colordex('black'),charsize=mycharsize,charthick=mycharthick

    IF b.origcolor EQ '' THEN b.origcolor='lime green'
    IF b.smorigcolor EQ '' THEN b.origcolor='turquoise'
    IF b.subcolor EQ '' THEN b.subcolor='sky blue'
    IF b.smsubcolor EQ '' THEN b.smsubcolor='blue'
    IF b.galcolor EQ '' THEN b.galcolor='green'
    IF b.tempcolor EQ '' THEN b.tempcolor=normalcolor

    ;; plot original data
    IF (b.origselected) THEN BEGIN
       oplot,obsinwar,obsinfar+b.origoffsetval,psym=10,linestyle=0,$
         color=colordex(b.origcolor)       
       IF N_ELEMENTS(linecolors) EQ 0 THEN linecolors=colordex(b.origcolor) $
         ELSE linecolors=[linecolors,colordex(b.origcolor)]
       origtxt=b.obstxtval+' original data'
       IF N_ELEMENTS(legendtxt) EQ 0 THEN legendtxt=origtxt $
         ELSE legendtxt=[legendtxt,origtxt]
    ENDIF

    ;; plot smoothed original data
    IF (b.smorigselected) THEN BEGIN
       oplot,obsinwar,sgsmooth_obsinfar+b.smorigoffsetval,psym=10,linestyle=0,$
      color=colordex(b.smorigcolor)
       IF N_ELEMENTS(linecolors) EQ 0 THEN linecolors=colordex(b.smorigcolor) $
         ELSE linecolors=[linecolors,colordex(b.smorigcolor)]
       smorigtxt=b.obstxtval+' smoothed original data'
       IF N_ELEMENTS(legendtxt) EQ 0 THEN legendtxt=smorigtxt $
         ELSE legendtxt=[legendtxt,smorigtxt]
    ENDIF

    ;; plot subtracted (O-G)
    IF (b.subselected) THEN BEGIN
       oplot,obsw,obsminusgal+b.suboffsetval,psym=10,linestyle=0, $
      color=colordex(b.subcolor)
       IF N_ELEMENTS(linecolors) EQ 0 THEN linecolors=colordex(b.subcolor) $
         ELSE linecolors=[linecolors,colordex(b.subcolor)]
       IF N_ELEMENTS(legendtxt) EQ 0 THEN legendtxt=b.obstxtval $
         ELSE legendtxt=[legendtxt,b.obstxtval]

    ENDIF

    ;; plot smoothed subtracted (O-G)
    IF (b.smsubselected) THEN BEGIN
       oplot,sgsmooth_obsw,sgsmooth_obsminusgal+b.smsuboffsetval,psym=10,linestyle=0,$
      color=colordex(b.smsubcolor),thick=mythick+2
       IF N_ELEMENTS(linecolors) EQ 0 THEN linecolors=colordex(b.smsubcolor) $
         ELSE linecolors=[linecolors,colordex(b.smsubcolor)]
       smsubtxt=b.obstxtval+' smoothed'
       IF N_ELEMENTS(legendtxt) EQ 0 THEN legendtxt=smsubtxt $
         ELSE legendtxt=[legendtxt,smsubtxt]
    ENDIF

    ;; plot subtracted galaxy
    IF (b.galselected) THEN BEGIN
       oplot,obsw,b.ff[I]*galf+b.galoffsetval,psym=10,linestyle=0,thick=mythick+2,$
      color=colordex(b.galcolor)
       IF N_ELEMENTS(linecolors) EQ 0 THEN linecolors=colordex(b.galcolor) $
         ELSE linecolors=[linecolors,colordex(b.galcolor)]
       IF b.gfile[I] EQ 'inp' THEN galtxt='Observed host galaxy' $
          ELSE galtxt=b.gfile[I]+' galaxy'
       IF N_ELEMENTS(legendtxt) EQ 0 THEN legendtxt=galtxt $
         ELSE legendtxt=[legendtxt,galtxt]
    ENDIF

    ;; plot template
    IF (b.tempselected) THEN BEGIN
       oplot,tempw,exttempf+b.tempoffsetval,thick=mythick+1, color=colordex(b.tempcolor)
       IF N_ELEMENTS(linecolors) EQ 0 THEN linecolors=colordex(b.tempcolor) $
         ELSE linecolors=[linecolors,colordex(b.tempcolor)]
       IF N_ELEMENTS(legendtxt) EQ 0 THEN legendtxt=b.temptxtval $
         ELSE legendtxt=[legendtxt,b.temptxtval]

    ENDIF

    IF N_ELEMENTS(linecolors) GT 0 THEN BEGIN
       txtcolors=intarr(N_ELEMENTS(linecolors))
       txtcolors[*]=colordex(normalcolor)
       linestyles=intarr(N_ELEMENTS(linecolors))
       linestyles[*]=0
       linethicks=intarr(N_ELEMENTS(linecolors))
       linethicks[*]=mythick+2

       ;set linestyle=-1 to not draw a line
       original_legend,legendtxt,linestyle=linestyles,textcolors=txtcolors,$
         charsize=mycharsize,box=0,colors=linecolors,thick=linethicks,$
         charthick=mycharthick,spacing=mycharsize+0.1,pspacing=1,$
         position=[b.legendxval+mylegendxoffset,b.legendyval+mylegendyoffset],/normal,/left,/bottom
    ENDIF
    
 ENDIF
 
 IF (b.psflag) THEN BEGIN
    PRINT,'Created postscript file: ',b.psfile
    DEVICE,/close
    SET_PLOT,'x'
 ENDIF

 b.psflag=0
END


PRO redraw,ev
WIDGET_CONTROL,ev.top,GET_UVALUE=b
WIDGET_CONTROL,b.zwid,GET_VALUE=zin      
WIDGET_CONTROL,b.dispwid,GET_VALUE=dispin   
WIDGET_CONTROL,b.avwid,GET_VALUE=avin     
WIDGET_CONTROL,b.ccwid,GET_VALUE=ccin     
WIDGET_CONTROL,b.rvwid,GET_VALUE=rvin     
WIDGET_CONTROL,b.beginwwid,GET_VALUE=beginwin 
WIDGET_CONTROL,b.endwwid,GET_VALUE=endwin   
WIDGET_CONTROL,b.ffwid,GET_VALUE=ffin     
WIDGET_CONTROL,b.xminwid,GET_VALUE=xminin     
WIDGET_CONTROL,b.xmaxwid,GET_VALUE=xmaxin     
WIDGET_CONTROL,b.yminwid,GET_VALUE=yminin     
WIDGET_CONTROL,b.ymaxwid,GET_VALUE=ymaxin     
WIDGET_CONTROL,b.obstxtwid,GET_VALUE=obstxtin     
WIDGET_CONTROL,b.temptxtwid,GET_VALUE=temptxtin     
WIDGET_CONTROL,b.tempoffsetwid,GET_VALUE=tempoffsetin     
WIDGET_CONTROL,b.galoffsetwid,GET_VALUE=galoffsetin     
WIDGET_CONTROL,b.suboffsetwid,GET_VALUE=suboffsetin     
WIDGET_CONTROL,b.smsuboffsetwid,GET_VALUE=smsuboffsetin     
WIDGET_CONTROL,b.origoffsetwid,GET_VALUE=origoffsetin     
WIDGET_CONTROL,b.smorigoffsetwid,GET_VALUE=smorigoffsetin     
WIDGET_CONTROL,b.npixwid,GET_VALUE=npixin     
WIDGET_CONTROL,b.degreewid,GET_VALUE=degreein     
b.psflag=0
I=b.selected
b.z[I]=zin      
b.disp=dispin   
b.av[I]=avin     
b.cc[I]=ccin     
b.rv=rvin     
b.beginwval=beginwin 
b.endwval=endwin   
b.ff[I]=ffin       
b.xmin=xminin
b.xmax=xmaxin
b.ymin=yminin
b.ymax=ymaxin
b.tempoffsetval=tempoffsetin
b.galoffsetval=galoffsetin
b.suboffsetval=suboffsetin
b.smsuboffsetval=smsuboffsetin
b.origoffsetval=origoffsetin
b.smorigoffsetval=smorigoffsetin
b.obstxtval=obstxtin
b.temptxtval=temptxtin
b.npixval=npixin     
b.degreeval=degreein     

WIDGET_CONTROL,ev.top,SET_UVALUE=b
junk=draw(b)

END

PRO selector,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b
b.psflag=0
I=ev.index
WIDGET_CONTROL,b.zwid,SET_VALUE=b.zfile[I]
;WIDGET_CONTROL,b.dispwid,SET_VALUE=b.dispfile
WIDGET_CONTROL,b.avwid,SET_VALUE=b.avfile[I]
WIDGET_CONTROL,b.ccwid,SET_VALUE=b.ccfile[I]
WIDGET_CONTROL,b.rvwid,SET_VALUE=b.rvfile
WIDGET_CONTROL,b.ffwid,SET_VALUE=b.fffile[I]
WIDGET_CONTROL,b.xminwid,SET_VALUE=0     
WIDGET_CONTROL,b.xmaxwid,SET_VALUE=0     
WIDGET_CONTROL,b.npixwid,GET_VALUE=npixvalin
b.npixval=npixvalin
WIDGET_CONTROL,b.degreewid,GET_VALUE=degreevalin
b.degreeval=degreevalin
WIDGET_CONTROL,b.suboffsetwid,GET_VALUE=suboffsetvalin
b.suboffsetval=suboffsetvalin
WIDGET_CONTROL,b.tempoffsetwid,GET_VALUE=tempoffsetvalin
b.tempoffsetval=tempoffsetvalin
WIDGET_CONTROL,b.galoffsetwid,GET_VALUE=galoffsetvalin
b.galoffsetval=galoffsetvalin
WIDGET_CONTROL,b.origoffsetwid,GET_VALUE=origoffsetvalin
b.origoffsetval=origoffsetvalin
WIDGET_CONTROL,b.smsuboffsetwid,GET_VALUE=smsuboffsetvalin
b.smsuboffsetval=smsuboffsetvalin
WIDGET_CONTROL,b.smorigoffsetwid,GET_VALUE=smorigoffsetvalin
b.smorigoffsetval=smorigoffsetvalin

;; this stuff for stripping off the directory for the labels on the figs
tslashpos=STRPOS(b.tfile[I],'/',/REVERSE_SEARCH)
b.temptxtval=STRMID(b.tfile[I],tslashpos+1) 
b.temptxtval=namedecoder(b.temptxtval)

rank=string(I+1)
rank=STRCOMPRESS(rank,/REMOVE_ALL)
b.psfile=b.ofileroot+'.'+rank+'.ps'
b.outobsfile=b.ofileroot+'.'+rank+'.obs.sft'
b.outtempfile=b.ofileroot+'.'+rank+'.temp.sft'
b.outsubfile=b.ofileroot+'.'+rank+'.sub.sft'
b.outgalfile=b.ofileroot+'.'+rank+'.gal.sft'
b.outsgsmooth_subfile=b.ofileroot+'.'+rank+'.smsub.sft'
b.outsgsmooth_origfile=b.ofileroot+'.'+rank+'.smorig.sft'
WIDGET_CONTROL, b.psfilewid, SET_VALUE=b.psfile
WIDGET_CONTROL, b.obstxtwid, SET_VALUE=b.obstxtval
WIDGET_CONTROL, b.temptxtwid, SET_VALUE=b.temptxtval
b.xmin=0
b.xmax=0
b.selected=I

b.z[I]=b.zfile[I]
b.av[I]=b.avfile[I]
b.cc[I]=b.ccfile[I]
b.rv=b.rvfile
b.ff[I]=b.fffile[I]

WIDGET_CONTROL,/HOURGLASS
readfile, b.sf_installdir+b.tfile[I],  tempinw,  tempinf

mediantempinf=median(tempinf)
tempinfar=double(tempinf/mediantempinf)
tempinw=double(tempinw)

IF b.gfile[I] eq 'inp' THEN BEGIN
    readfile, b.gspec,  galinw,  galinf
ENDIF ELSE readfile, b.sf_installdir+'gal/'+b.gfile[I],  galinw,  galinf
mediangalinf=median(galinf)
galinfar=double(galinf/mediangalinf)                
    
zp1 = 1.0 + b.z[I]
tempwredar = zp1 * tempinw

;if input galaxy is observed galaxy, do not redshift it
IF b.gfile[I] NE 'inp' THEN galwredar= zp1 * galinw $
ELSE galwredar=galinw

  
IF tempwredar[0] gt b.beginwfile THEN b.beginwval = tempwredar[0] $
ELSE b.beginwval = b.beginwfile
IF tempwredar(N_ELEMENTS(tempwredar)-1) lt b.endwfile THEN $
  b.endwval = tempwredar(N_ELEMENTS(tempwredar)-1) $
ELSE b.endwval = b.endwfile    

; this stuff is a copy of what is in the draw section,
; but I need it here to calc waveln. per pixel
junk=zerostrip(b.obsinw,b.obsinf,obsinwar,obsinfar)
wppbflt=obsinwar[1]-obsinwar[0]
wpprflt=obsinwar[N_ELEMENTS(obsinwar)-1]-obsinwar[N_ELEMENTS(obsinwar)-2]
b.wppbval=STRING(wppbflt,FORMAT='(F6.2)')
b.wpprval=STRING(wpprflt,FORMAT='(F6.2)')

WIDGET_CONTROL,b.beginwwid,SET_VALUE=b.beginwval
WIDGET_CONTROL,b.endwwid,SET_VALUE=b.endwval
WIDGET_CONTROL,b.wppbwid,SET_VALUE=b.wppbval
WIDGET_CONTROL,b.wpprwid,SET_VALUE=b.wpprval

b.tempwred=0
b.galwred=0
b.tempinf=0
b.galinf=0
b.tempwred=tempwredar
b.galwred=galwredar
b.tempinf=tempinfar
b.galinf=galinfar

WIDGET_CONTROL, ev.top, SET_UVALUE=b
junk=draw(b)
END


PRO psbutton,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b
WIDGET_CONTROL, b.psfilewid, GET_VALUE=psfilein
b.psfile=psfilein
b.psflag=1
WIDGET_CONTROL, ev.top, SET_UVALUE=b
junk=draw(b)
END


PRO donebutton,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b 
;restore user's settings
!P.THICK=b.oldthick    
!P.CHARTHICK=b.oldcharthick
!X.THICK=b.oldxthick   
!Y.THICK=b.oldythick   
!P.COLOR=b.oldcolor
!P.BACKGROUND=b.oldbackground
;WIDGET_CONTROL, ev.top, SET_UVALUE=b 
WIDGET_CONTROL, ev.top, /DESTROY
END

PRO textoutput,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b 

;; make base widget for entering output data file names
b.textoutputbase=WIDGET_BASE(/ROW,TITLE='Choose names for output files',$
                         GROUP_LEADER=base)

outputgroup = WIDGET_BASE(b.textoutputbase, /COLUMN,/FRAME)

obsgroup = WIDGET_BASE(outputgroup, /ROW)
label = WIDGET_LABEL(obsgroup,VALUE='Observation:')
b.outobsfilewid = WIDGET_TEXT(obsgroup,/EDITABLE,XSIZE=78)

tempgroup = WIDGET_BASE(outputgroup, /ROW)
label = WIDGET_LABEL(tempgroup,VALUE='Template:   ')
b.outtempfilewid = WIDGET_TEXT(tempgroup,/EDITABLE,XSIZE=78)

subgroup = WIDGET_BASE(outputgroup, /ROW)
label = WIDGET_LABEL(subgroup,VALUE='Obs-gal:    ')
b.outsubfilewid = WIDGET_TEXT(subgroup,/EDITABLE,XSIZE=78)

galgroup = WIDGET_BASE(outputgroup, /ROW)
label = WIDGET_LABEL(galgroup,VALUE='Galaxy:     ')
b.outgalfilewid = WIDGET_TEXT(galgroup,/EDITABLE,XSIZE=78)

sgsmooth_subgroup = WIDGET_BASE(outputgroup, /ROW)
label = WIDGET_LABEL(sgsmooth_subgroup,VALUE='Smooth O-G: ')
b.outsgsmooth_subfilewid = WIDGET_TEXT(sgsmooth_subgroup,/EDITABLE,XSIZE=78)

sgsmooth_origgroup = WIDGET_BASE(outputgroup, /ROW)
label = WIDGET_LABEL(sgsmooth_origgroup,VALUE='Smooth Orig:')
b.outsgsmooth_origfilewid = WIDGET_TEXT(sgsmooth_origgroup,/EDITABLE,XSIZE=78)

outputbuttonbar =  WIDGET_BASE(outputgroup,/row)
outputbutton = WIDGET_BUTTON(outputbuttonbar, VALUE=' Generate Text Files ',event_pro='graphfiles')

; have to give the structure as a uvalue to the button, because this
; is the ev.id that the graphfiles procedure sees
WIDGET_CONTROL, outputbutton, SET_UVALUE=b
outputbutton = WIDGET_BUTTON(outputbuttonbar, VALUE=' Cancel ',event_pro='canceltextoutput')

WIDGET_CONTROL, b.textoutputbase,/REALIZE 
WIDGET_CONTROL, b.outtempfilewid, SET_VALUE=b.outtempfile
WIDGET_CONTROL, b.outsubfilewid, SET_VALUE=b.outsubfile
WIDGET_CONTROL, b.outgalfilewid, SET_VALUE=b.outgalfile
WIDGET_CONTROL, b.outobsfilewid, SET_VALUE=b.outobsfile
IF (b.smsubselected) THEN $
  WIDGET_CONTROL, b.outsgsmooth_subfilewid, SET_VALUE=b.outsgsmooth_subfile
IF (b.smorigselected) THEN $
  WIDGET_CONTROL, b.outsgsmooth_origfilewid, SET_VALUE=b.outsgsmooth_origfile
WIDGET_CONTROL, ev.top, SET_UVALUE=b 
END

PRO canceltextoutput,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b 
WIDGET_CONTROL, ev.top,/DESTROY
END


PRO galcolorbuttonpro,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b
; here ev.top is the wid of the colorselector widget: b.colorselectorbase
b.galcolor = b.colornames[ev.index]
WIDGET_CONTROL, ev.top, SET_UVALUE=b
WIDGET_CONTROL, b.base, SET_UVALUE=b 
END

PRO subcolorbuttonpro,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b
; here ev.top is the wid of the colorselector widget: b.colorselectorbase
b.subcolor = b.colornames[ev.index]
WIDGET_CONTROL, ev.top, SET_UVALUE=b
WIDGET_CONTROL, b.base, SET_UVALUE=b 
END

PRO smsubcolorbuttonpro,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b
; here ev.top is the wid of the colorselector widget: b.colorselectorbase
b.smsubcolor = b.colornames[ev.index]
WIDGET_CONTROL, ev.top, SET_UVALUE=b
WIDGET_CONTROL, b.base, SET_UVALUE=b 
END

PRO origcolorbuttonpro,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b
; here ev.top is the wid of the colorselector widget: b.colorselectorbase
b.origcolor = b.colornames[ev.index]
WIDGET_CONTROL, ev.top, SET_UVALUE=b
WIDGET_CONTROL, b.base, SET_UVALUE=b 
END

PRO smorigcolorbuttonpro,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b
; here ev.top is the wid of the colorselector widget: b.colorselectorbase
b.smorigcolor = b.colornames[ev.index]
WIDGET_CONTROL, ev.top, SET_UVALUE=b
WIDGET_CONTROL, b.base, SET_UVALUE=b 
END

PRO tempcolorbuttonpro,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b
; here ev.top is the wid of the colorselector widget: b.colorselectorbase
b.tempcolor = b.colornames[ev.index]
WIDGET_CONTROL, ev.top, SET_UVALUE=b
WIDGET_CONTROL, b.base, SET_UVALUE=b 
END

PRO acceptcolorselector,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b 
WIDGET_CONTROL, b.base, SET_UVALUE=b 
WIDGET_CONTROL, ev.top,/DESTROY
END


PRO savecolordefaults,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b 
OPENW,1,b.sf_installdir+'defaults.txt'
PRINTF,1,'galcolor: ',b.galcolor
PRINTF,1,'tempcolor: ',b.tempcolor
PRINTF,1,'origcolor: ',b.origcolor
PRINTF,1,'smorigcolor: ',b.smorigcolor
PRINTF,1,'subcolor: ',b.subcolor
PRINTF,1,'smsubcolor: ',b.smsubcolor
CLOSE,1
PRINT,'Saved default colors as: ',b.sf_installdir+'defaults.txt'
WIDGET_CONTROL, ev.top, SET_UVALUE=b 
WIDGET_CONTROL, b.base, SET_UVALUE=b 
END


PRO getdefaults,b
READCOL,b.sf_installdir+'defaults.txt',description,defcolor,format=('a,a'),/silent

;for two word colors...
skyindex=where(defcolor EQ 'sky',count)
IF count THEN defcolor[skyindex]='sky blue'
forestindex=where(defcolor EQ 'forest',count)
IF count THEN defcolor[forestindex]='forest green'
limeindex=where(defcolor EQ 'lime',count)
IF count THEN defcolor[limeindex]='lime green'

;if there isn't a value for the color listed in the defaults.txt file,
;assign a color
index=where(STRCMP(description,'gal',3),count)

IF count GT 0 THEN b.galcolor=defcolor[index] ELSE b.galcolor='green'

index=where(STRCMP(description,'tem',3),count)
IF count GT 0 THEN b.tempcolor=defcolor[index] ELSE b.tempcolor='black'
index=where(STRCMP(description,'smo',3),count)
IF count GT 0 THEN b.smorigcolor=defcolor[index] ELSE b.smorigcolor='turquoise'
index=where(STRCMP(description,'sub',3),count)
IF count GT 0 THEN b.subcolor=defcolor[index] ELSE b.galcolor='sky blue'
index=where(STRCMP(description,'ori',3),count)
IF count GT 0 THEN b.origcolor=defcolor[index] ELSE b.galcolor='lime green'
index=where(STRCMP(description,'sms',3),count)
IF count GT 0 THEN b.smsubcolor=defcolor[index] ELSE b.smsubcolor='blue'

END

PRO changetodefaults,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b 
getdefaults,b
WIDGET_CONTROL,b.subcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.subcolor)
WIDGET_CONTROL,b.tempcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.tempcolor)
WIDGET_CONTROL,b.origcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.origcolor)
WIDGET_CONTROL,b.smorigcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.smorigcolor)
WIDGET_CONTROL,b.smsubcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.smsubcolor)
WIDGET_CONTROL,b.galcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.galcolor)

;need to update both bases with the new b
WIDGET_CONTROL, ev.top, SET_UVALUE=b 
WIDGET_CONTROL, b.base, SET_UVALUE=b 
END


PRO originaldefaults,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b 
b.subcolor='sky blue'
WIDGET_CONTROL,b.subcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.subcolor)
b.tempcolor='black'
WIDGET_CONTROL,b.tempcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.tempcolor)
b.origcolor='lime green'
WIDGET_CONTROL,b.origcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.origcolor)
b.smorigcolor='turquoise'
WIDGET_CONTROL,b.smorigcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.smorigcolor)
b.smsubcolor='blue'
WIDGET_CONTROL,b.smsubcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.smsubcolor)
b.galcolor='green'
WIDGET_CONTROL,b.galcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.galcolor)
;need to update both bases with the new b
WIDGET_CONTROL, ev.top, SET_UVALUE=b 
WIDGET_CONTROL, b.base, SET_UVALUE=b 
END

FUNCTION colorselector,ev
;WIDGET_CONTROL, ev.top, SET_UVALUE=b
WIDGET_CONTROL, ev.top, GET_UVALUE=b 

;; make base widget for selecting graph colors
b.colorselectorbase=WIDGET_BASE(/COLUMN,TITLE='Graph colors',$
                         GROUP_LEADER=base)

WIDGET_CONTROL, b.colorselectorbase, SET_UVALUE=b

b.colornames= ['pink','magenta','red','peach','orange','tan',$
    'brown','yellow','forest green','green','lime green',$
     'turquoise','aquamarine','sky blue','blue','violet',$
     'purple','white','black']

dropdownsbase = WIDGET_BASE(b.colorselectorbase,/COLUMN,/FRAME)
subgroup = WIDGET_BASE(dropdownsbase,/ROW)
subtext = WIDGET_LABEL(subgroup,VALUE='Obs-gal:   ')
b.subcolorwid = WIDGET_COMBOBOX(subgroup,$
   VALUE=b.colornames,EVENT_PRO='subcolorbuttonpro')
WIDGET_CONTROL,b.subcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.subcolor)

tempgroup = WIDGET_BASE(dropdownsbase,/ROW)
temptext = WIDGET_LABEL(tempgroup,VALUE='Temp:      ')
b.tempcolorwid = WIDGET_COMBOBOX(tempgroup,$
   VALUE=b.colornames,EVENT_PRO='tempcolorbuttonpro')
WIDGET_CONTROL,b.tempcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.tempcolor)

smsubgroup = WIDGET_BASE(dropdownsbase,/ROW)
smsubtext = WIDGET_LABEL(smsubgroup,VALUE='Sm. O-G:   ')
b.smsubcolorwid = WIDGET_COMBOBOX(smsubgroup,$
   VALUE=b.colornames,EVENT_PRO='smsubcolorbuttonpro')
WIDGET_CONTROL,b.smsubcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.smsubcolor)

galgroup = WIDGET_BASE(dropdownsbase,/ROW)
galtext = WIDGET_LABEL(galgroup,VALUE='Gal:       ')
b.galcolorwid = WIDGET_COMBOBOX(galgroup,$
   VALUE=b.colornames,EVENT_PRO='galcolorbuttonpro')
WIDGET_CONTROL,b.galcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.galcolor)

origgroup = WIDGET_BASE(dropdownsbase,/ROW)
origtext = WIDGET_LABEL(origgroup,VALUE='Orig. Obs: ')
b.origcolorwid = WIDGET_COMBOBOX(origgroup,$
   VALUE=b.colornames,EVENT_PRO='origcolorbuttonpro')
WIDGET_CONTROL,b.origcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.origcolor)

smoriggroup = WIDGET_BASE(dropdownsbase,/ROW)
smorigtext = WIDGET_LABEL(smoriggroup,VALUE='Smth. Obs: ')
b.smorigcolorwid = WIDGET_COMBOBOX(smoriggroup,$
   VALUE=b.colornames,EVENT_PRO='smorigcolorbuttonpro')
WIDGET_CONTROL,b.smorigcolorwid,SET_COMBOBOX_SELECT=WHERE(b.colornames EQ b.smorigcolor)

colorbuttonbar =  WIDGET_BASE(b.colorselectorbase,/COLUMN)
setdefaultsbutton = WIDGET_BUTTON(colorbuttonbar, VALUE=' Save As My Defaults ',event_pro='savecolordefaults',/ALIGN_CENTER)

getsetdefaultsbutton = WIDGET_BUTTON(colorbuttonbar, VALUE=' Reset To My Defaults ',event_pro='changetodefaults',/ALIGN_CENTER)
originaldefaultsbutton = WIDGET_BUTTON(colorbuttonbar, VALUE=' Use Program Defaults ',event_pro='originaldefaults',/ALIGN_CENTER)
colorbuttonbar2 =  WIDGET_BASE(b.colorselectorbase,/row)
coloracceptbutton = WIDGET_BUTTON(colorbuttonbar2, VALUE=' Done ',event_pro='acceptcolorselector')
;colorcancelbutton = WIDGET_BUTTON(colorbuttonbar2, VALUE=' Cancel ',event_pro='cancelcolorselector')

;have to set the uvalue for this base, because galcolorbuttonpro, etc
;gets their uvalues from this base, not the top base
WIDGET_CONTROL, b.colorselectorbase, SET_UVALUE=b
WIDGET_CONTROL, ev.top, SET_UVALUE=b
WIDGET_CONTROL, b.colorselectorbase,/REALIZE 

END


PRO graphfiles,ev
;; this procedure generates the output text files
WIDGET_CONTROL,ev.id,GET_UVALUE=b
; above gets the uvalue from the button that called the textoutput widget
WIDGET_CONTROL, b.outtempfilewid, GET_VALUE=outtempfilein
b.outtempfile=outtempfilein
WIDGET_CONTROL, b.outsubfilewid, GET_VALUE=outsubfilein
b.outsubfile=outsubfilein
WIDGET_CONTROL, b.outgalfilewid, GET_VALUE=outgalfilein
b.outgalfile=outgalfilein
WIDGET_CONTROL, b.outobsfilewid, GET_VALUE=outobsfilein
b.outobsfile=outobsfilein
WIDGET_CONTROL, b.outsgsmooth_subfilewid, GET_VALUE=outsgsmooth_subfilein
b.outsgsmooth_subfile=outsgsmooth_subfilein
WIDGET_CONTROL, b.outsgsmooth_origfilewid, GET_VALUE=outsgsmooth_origfilein
b.outsgsmooth_origfile=outsgsmooth_origfilein

I=b.selected
IF ((b.S[I] gt 0) and (b.S[I] lt 999)) THEN BEGIN
; need to do this here because obsinwar can't be a structure
; structures have to have a predetermined number of elements
    junk=zerostrip(b.obsinw,b.obsinf,obsinwar,obsinfar)
    junk=zerostrip(b.tempwred,b.tempinf,tempwredar,tempinfar)
    junk=zerostrip(b.galwred,b.galinf,galwredar,galinfar)
    junk=zerostrip(b.weightinw,b.weightinf,weightwar,weightfar)

;    ;make sure weights are sampled at same points as flux
;    IF obsinwar NE weightwar THEN linterp,weightwar,weightfar,obsinwar,weightfar
;    ;call fixgap which fixes gaps in the spectrum if any exist
;    fixgap,obsinwar,obsinfar,weightfar,obsinwar,obsinfar,weightfar

    obsf=double(binspec_weighted(obsinwar,obsinfar,b.beginwval,b.endwval,b.disp,obsw,weightwar,weightfar,weightfbinned))
    tempf=double(binspec_weighted(tempwredar,tempinfar,b.beginwval,b.endwval,b.disp,tempw))
    galf=double(binspec_weighted(galwredar,galinfar,b.beginwval,b.endwval,b.disp,galw))
    
    ;; need to keep reddening in unredshifted frame
    zp1= 1.0 + b.z[I]
    unredshiftedw=obsw/zp1
    redlawf=mkafromlam(unredshiftedw,b.rv)    
    obsminusgal=dblarr(N_ELEMENTS(obsf))
    exttempf=dblarr(N_ELEMENTS(obsf))    
    FOR P=0,N_ELEMENTS(obsf)-1 DO $
      obsminusgal[p]=(obsf[p]-b.ff[I]*galf[p])
    FOR P=0,N_ELEMENTS(obsf)-1 DO $
      exttempf[p]=b.cc[I]*tempf[p]*10^(-b.av[I]*redlawf[p]/2.5)


    IF (b.smsubselected OR b.smorigselected) THEN BEGIN
        ;sgsmooth_obsminusgal=dblarr(N_ELEMENTS(obsf))
        sgsmooth_obsinfar=dblarr(N_ELEMENTS(obsinfar))
        sgcoeff=SAVGOL(b.npixval,b.npixval,0,b.degreeval)
        sgsmooth_obsinfar=CONVOL(obsinfar,sgcoeff,/EDGE_TRUNCATE)
        ;need to rebin smoothed observations to subtract galaxy
        ;but binning can be anything.  do not need to weight because
        ;smoothing destroys info about how to weight 
        ;in the future think about how to smooth using weight info

        galf_forsmooth=double(binspec_weighted(galwredar,galinfar,b.beginwval,b.endwval,1.0,galw_forsmooth))
        sgsmooth_obsf=double(binspec_weighted(obsinwar,sgsmooth_obsinfar,b.beginwval,$
                                     b.endwval,1.0,sgsmooth_obsw))
        sgsmooth_obsminusgal=sgsmooth_obsf-b.ff[I]*galf_forsmooth
    ENDIF

ENDIF

OPENW,13,b.outobsfile
FOR P=0,N_ELEMENTS(obsinwar)-1 DO $
  PRINTF,13,obsinwar[p],obsinfar[p]
PRINT,'Writing observation file: ',b.outobsfile
CLOSE,13

OPENW,10,b.outtempfile
FOR P=0,N_ELEMENTS(obsf)-1 DO $
  PRINTF,10,tempw[p],exttempf[p] ;;,FORMAT='(F8.2,F9.4)'
PRINT,'Writing template file: ',b.outtempfile
CLOSE,10

OPENW,11,b.outsubfile
FOR P=0,N_ELEMENTS(obsf)-1 DO $
  PRINTF,11,obsw[p],obsminusgal[p] ;;,FORMAT='(F8.2,F9.4)'
PRINT,'Writing obs - gal file: ',b.outsubfile
CLOSE,11

OPENW,12,b.outgalfile
FOR P=0,N_ELEMENTS(obsf)-1 DO $
  PRINTF,12,galw[p],b.ff[I]*galf[p]
PRINT,'Writing galaxy file: ',b.outgalfile
CLOSE,12

IF (b.smsubselected) THEN BEGIN
    OPENW,14,b.outsgsmooth_subfile
    FOR P=0,N_ELEMENTS(sgsmooth_obsw)-1 DO $
      PRINTF,14,sgsmooth_obsw[p],sgsmooth_obsminusgal[p] ;;,FORMAT='(F8.2,F9.4)'
    PRINT,'Writing SG Smoothed obs - gal file: ',b.outsgsmooth_subfile
    CLOSE,14
ENDIF

IF (b.smorigselected) THEN BEGIN
    OPENW,15,b.outsgsmooth_origfile
    FOR P=0,N_ELEMENTS(obsinwar)-1 DO $
      PRINTF,15,obsinwar[p],sgsmooth_obsinfar[p] ;;,FORMAT='(F8.2,F9.4)'
    PRINT,'Writing SG Smoothed Original Observation file: ',b.outsgsmooth_origfile
    CLOSE,15
    
ENDIF

WIDGET_CONTROL,ev.top,SET_UVALUE=b
WIDGET_CONTROL,ev.top,/DESTROY

END

FUNCTION infiledo,b
I=0
OPENR,1,b.file
line=''
WHILE (NOT EOF(1)) DO BEGIN
    READF,1,line
    IF I eq 0 then snarray = line ELSE snarray=[snarray,line]

    IF (STRCMP(line,';',1)) THEN BEGIN
        IF (STRCMP(line,';;beg',5)) THEN BEGIN
            beginar=STRSPLIT(line,'=',/EXTRACT)
            b.beginwfile=double(beginar[1])
            ;;b.beginw[I]=b.beginwfile
        ENDIF
        IF (STRCMP(line,';;end',5)) THEN BEGIN
            endar=STRSPLIT(line,'=',/EXTRACT)
            b.endwfile=double(endar[1])
            ;;b.endw[I]=b.beginwfile
        ENDIF
        IF (STRCMP(line,';;dis',5)) THEN BEGIN
            dispar=STRSPLIT(line,'=',/EXTRACT)
            b.dispfile=double(dispar[1])
            ;b.disp=b.dispfile
            b.disp=5 
        ENDIF
        IF (STRCMP(line,';;wei',5)) THEN BEGIN
            weightar=STRSPLIT(line,'=',/EXTRACT)
            ;; strcompress removes whitespace
            b.weightfile=STRCOMPRESS(weightar[1],/REMOVE_ALL)
        ENDIF
        IF (STRCMP(line,';;o',3)) THEN BEGIN
            objar=STRSPLIT(line,'=',/EXTRACT)
            b.ofile=STRCOMPRESS(objar[1],/REMOVE_ALL)
        ENDIF
        IF (STRCMP(line,';;gspec',7)) THEN BEGIN
            gspecar=STRSPLIT(line,'=',/EXTRACT)
            b.gspec=STRCOMPRESS(gspecar[1],/REMOVE_ALL)
        ENDIF
        IF (STRCMP(line,';;Rv',4)) THEN BEGIN
            rvar=STRSPLIT(line,'=',/EXTRACT)
            b.rvfile=rvar[1]
            b.rv=b.rvfile
        ENDIF
        IF (STRCMP(line,';;type',6)) THEN BEGIN
            typear=STRSPLIT(line,'=',/EXTRACT)
            ;; strcompress removes whitespace
            b.type=STRCOMPRESS(typear[1],/REMOVE_ALL)
        ENDIF
        IF (STRCMP(line,';;epoch',7)) THEN BEGIN
            epochar=STRSPLIT(line,'=',/EXTRACT)
            b.epoch=epochar[1]
        ENDIF
        IF (STRCMP(line,';;err_epoch',11)) THEN BEGIN
            err_epochar=STRSPLIT(line,'=',/EXTRACT)
            b.err_epoch=err_epochar[1]
        ENDIF
        IF (STRCMP(line,';;numberoftype',14)) THEN BEGIN
            numberoftypear=STRSPLIT(line,'=',/EXTRACT)
            b.numberoftype=numberoftypear[1]
        ENDIF
        IF (STRCMP(line,';;numtocompare',12)) THEN BEGIN
            numtocomparear=STRSPLIT(line,'=',/EXTRACT)
            b.numtocompare=numtocomparear[1]
        ENDIF
        IF (STRCMP(line,';;grow',6)) THEN BEGIN
            grow=STRSPLIT(line,'=',/EXTRACT)
            b.grow=grow[1]
        ENDIF
        IF (STRCMP(line,';;nsigma',8)) THEN BEGIN
            nsigma=STRSPLIT(line,'=',/EXTRACT)
            b.nsigma=nsigma[1]
        ENDIF
        IF (STRCMP(line,';;sigmasource',13)) THEN BEGIN
            sigmasource=STRSPLIT(line,'=',/EXTRACT)
            b.sigmasource=STRCOMPRESS(sigmasource[1],/REMOVE_ALL)
        ENDIF
        IF (STRCMP(line,';;niter',7)) THEN BEGIN
            niter=STRSPLIT(line,'=',/EXTRACT)
            b.niter=niter[1]
        ENDIF
    ENDIF ELSE BEGIN
        b.tfile[I]=STRCOMPRESS(STRMID(line,0,30),/REMOVE_ALL)
        Sscalar=STRMID(line,31,8)
        zscalar=STRMID(line,40,7)
        b.gfile[I]=STRCOMPRESS(STRMID(line,48,4),/REMOVE_ALL)
        avscalar=STRMID(line,52,7)
        ccscalar=STRMID(line,60,7)
        ffscalar=STRMID(line,68,7)
        
        b.S[I]=double(Sscalar)
        b.zfile[I]=double(zscalar)
        b.avfile[I]=double(avscalar)
        b.ccfile[I]=double(ccscalar)
        b.fffile[I]=double(ffscalar)    
        b.z[I]=double(zscalar)
        b.av[I]=double(avscalar)
        b.cc[I]=double(ccscalar)
        b.ff[I]=double(ffscalar)    
    ENDELSE
    I = I + 1
ENDWHILE
CLOSE,1

WIDGET_CONTROL,b.selectorwid,SET_VALUE=snarray
numberoftypestr=string(b.numberoftype,FORMAT='(I1)')
numtocomparestr=string(b.numtocompare,FORMAT='(I1)')
epochstr=string(b.epoch,FORMAT='(F5.1)')
err_epochstr=string(b.err_epoch,FORMAT='(F5.1)')
typestr='Type: '+b.type+'      '
fromstr=' Agreement: '+numberoftypestr+' of the top '+numtocomparestr+'.      '
weightavgstr='Epoch (weighted average): '+epochstr+' +/-'+err_epochstr
typetextval=typestr+fromstr+weightavgstr
;PRINT,'From ',numberoftype,' of the top ',numtocompare,format='(A5,I1,A12,I1)'
;PRINT,'Epoch (weighted average): ',weightedavg,format='(A26,F5.1)'


;; strip extension from observed filename

dotpos=STREGEX(b.ofile,'\.dat')
IF dotpos GT 0 THEN b.ofileroot=STRMID(b.ofile,0,dotpos) 
dotpos=STREGEX(b.ofile,'\.asc')
IF dotpos GT 0 THEN b.ofileroot=STRMID(b.ofile,0,dotpos) 
dotpos=STREGEX(b.ofile,'\.fits')
IF dotpos GT 0 THEN b.ofileroot=STRMID(b.ofile,0,dotpos) 
dotpos=STREGEX(b.ofile,'\.txt')
IF dotpos GT 0 THEN b.ofileroot=STRMID(b.ofile,0,dotpos) 

; strip directory info from observation file name
oslashpos=STRPOS(b.ofileroot,'/',/REVERSE_SEARCH)
;b.obstxtval=STRMID(b.ofile,oslashpos+1) 
b.obstxtval=STRMID(b.ofileroot,oslashpos+1) 

;b.obstxtval=b.ofileroot


WIDGET_CONTROL,b.typetextwid,SET_VALUE=typetextval
WIDGET_CONTROL,b.dispwid,SET_VALUE=b.disp
WIDGET_CONTROL,b.yminwid,SET_VALUE=0     
WIDGET_CONTROL,b.ymaxwid,SET_VALUE=0

WIDGET_CONTROL,/HOURGLASS
;; read in files
b.obsinf=0
b.obsinw=0

;clean observed spectrum with sigma clipping
;PRINT, 'Reading in error spectrum:  ',b.weightfile
;if errors are in third column then b.ofile=b.weightfile

IF (b.weightfile EQ b.ofile) THEN BEGIN
   readfile, b.ofile, obsinw, obsinf, splitpos, sigma=weightinf,/threecolflag
;   print,'all in one: ',weightinf
   weightinw=obsinw
ENDIF ELSE BEGIN
   readfile,b.ofile,obsinw,obsinf,splitpos
   readfile,b.weightfile,weightinw,weightinf,splitpos
;   print,'two files',weightinf
ENDELSE

IF b.sigmasource EQ 'input' THEN BEGIN
   IF N_ELEMENTS(weightinw) EQ N_ELEMENTS(obsinw) THEN BEGIN
   ;PRINT,'Cleaning spectrum using input error spectrum, nsigma: ',b.nsigma
      obsinf=lineclean(obsinw,obsinf,b.nsigma,b.grow,b.niter,weightinf) 
   ENDIF ELSE BEGIN 
      PRINT,"ERROR: Input spectrum and weight spectrum have different sampling."
   ENDELSE
ENDIF ELSE BEGIN 
   IF b.sigmasource EQ 'calculate' THEN BEGIN
      obsinf=lineclean(obsinw,obsinf,b.nsigma,b.grow,b.niter) 
   ;PRINT,'Cleaning spectrum using standard deviation.  nsigma: ',b.nsigma
   ENDIF
ENDELSE

medianobsinf=median(obsinf)
b.obsinf=double(obsinf/medianobsinf)
b.obsinw=double(obsinw)

medianweightinf=median(weightinf)
b.weightinf=double(weightinf/medianweightinf)
b.weightinw=double(weightinw)

END


PRO infilereturnpro,ev
;; reads in and plots data when return is pressed in text field
WIDGET_CONTROL, ev.top, GET_UVALUE=b
WIDGET_CONTROL, b.infilewid, GET_VALUE=infilebrowsenamein
;; for some strange reason this makes infilebrowsename an array, so put
;; [0] to refer to a string
b.file=infilebrowsenamein[0]
IF (b.file ne '') THEN junk=infiledo(b)
WIDGET_CONTROL, ev.top, SET_UVALUE=b
END


PRO infilebuttonpro, ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b


infilebrowsenamein = DIALOG_PICKFILE(DIALOG_PARENT=panelgroup,$
    /READ,FILTER=['*.sfo'],/MUST_EXIST,$
    PATH=b.sf_workingdir)
    
b.file = infilebrowsenamein
WIDGET_CONTROL, b.infilewid, SET_VALUE=b.file
IF (b.file ne '') THEN junk=infiledo(b)
WIDGET_CONTROL, ev.top, SET_UVALUE=b
END


FUNCTION plotpicker,ev
WIDGET_CONTROL, ev.top, GET_UVALUE=b

;; subtracted (O-G) galaxy button
IF (ev.id eq b.subbuttonwid) THEN BEGIN
    IF ev.select eq 1 THEN BEGIN
        b.subselected=1 
        WIDGET_CONTROL, b.subsensgroup, SENSITIVE=1        
    ENDIF ELSE BEGIN 
        b.subselected=0
        WIDGET_CONTROL, b.subsensgroup, SENSITIVE=0        
    ENDELSE
ENDIF

;;original data button
IF (ev.id eq b.origbuttonwid) THEN BEGIN
    IF ev.select eq 1 THEN BEGIN
        b.origselected=1 
        WIDGET_CONTROL, b.origsensgroup, SENSITIVE=1        
    ENDIF ELSE BEGIN 
        b.origselected=0
        WIDGET_CONTROL, b.origsensgroup, SENSITIVE=0        
    ENDELSE
ENDIF

;; template button
IF (ev.id eq b.tempbuttonwid) THEN BEGIN
    IF ev.select eq 1 THEN BEGIN
        b.tempselected=1 
        WIDGET_CONTROL, b.tempsensgroup, SENSITIVE=1        
    ENDIF ELSE BEGIN 
        b.tempselected=0
        WIDGET_CONTROL, b.tempsensgroup, SENSITIVE=0        
    ENDELSE
ENDIF

;; galaxy button
IF (ev.id eq b.galbuttonwid) THEN BEGIN
    IF ev.select eq 1 THEN BEGIN
        b.galselected=1 
        WIDGET_CONTROL, b.galsensgroup, SENSITIVE=1        
    ENDIF ELSE BEGIN 
        b.galselected=0
        WIDGET_CONTROL, b.galsensgroup, SENSITIVE=0        
    ENDELSE
ENDIF

;;smoothed original data button
IF (ev.id eq b.smorigbuttonwid) THEN BEGIN
    IF ev.select eq 1 THEN BEGIN
        b.smorigselected=1 
        WIDGET_CONTROL, b.smorigsensgroup, SENSITIVE=1        
        WIDGET_CONTROL, b.sgsensgroup, SENSITIVE=1        
    ENDIF ELSE BEGIN 
        b.smorigselected=0
        WIDGET_CONTROL, b.smorigsensgroup, SENSITIVE=0        
        IF (b.smsubselected eq 0) THEN $
          WIDGET_CONTROL, b.sgsensgroup, SENSITIVE=0        
    ENDELSE
ENDIF

;;smoothed subtracted data button
IF (ev.id eq b.smsubbuttonwid) THEN BEGIN
    IF ev.select eq 1 THEN BEGIN
        b.smsubselected=1 
        WIDGET_CONTROL, b.smsubsensgroup, SENSITIVE=1        
        WIDGET_CONTROL, b.sgsensgroup, SENSITIVE=1        
    ENDIF ELSE BEGIN 
        b.smsubselected=0
        WIDGET_CONTROL, b.smsubsensgroup, SENSITIVE=0        
        IF (b.smorigselected eq 0) THEN $
          WIDGET_CONTROL, b.sgsensgroup, SENSITIVE=0        
    ENDELSE
ENDIF
WIDGET_CONTROL, ev.top, SET_UVALUE=b
END


PRO sggui_event,ev
;; needs to be here for e.g. slider
END

PRO gui_event,ev
;; needs to be here for e.g. slider
END


PRO sggui,file=file,version=version

IF KEYWORD_SET(version) THEN BEGIN 
   PRINT,'sgui.pro Version 3.5 August 30, 2012.  Author: Andy Howell.'  
   PRINT,'Documentation at: http://qold.astro.utoronto.ca/~howell/superfit/superfit.htm'
   GOTO,endpoint
ENDIF

sizelimit=1000
;DEVICE, SET_FONT = '-urw-helvetica-bold-o-condensed--0-0-0-0-p-0-iso8859-1'
b={bstrname,drawwid:0l,selectorwid:0l,selectorval:0l,base:0l,$
   localbeginw:fltarr(sizelimit),localendw:fltarr(sizelimit),disp:0.0,weightfile:' ',ofile:' ',rv:0.0,$
   tfile:strarr(sizelimit),gfile:strarr(sizelimit),S:fltarr(sizelimit),z:fltarr(sizelimit),$
   av:fltarr(sizelimit),cc:fltarr(sizelimit),ff:fltarr(sizelimit),$
   infilewid:0l,file:' ',gspec:' ',$
   obsinw:dblarr(50000),obsinf:dblarr(50000),selected:0l,$
   weightinw:dblarr(50000),weightinf:dblarr(50000),$
   tempwred:dblarr(20000),tempinf:dblarr(20000),$
   galwred:dblarr(10000),galinf:dblarr(10000),$
   zwid:0l,dispwid:0l,beginwwid:0l,endwwid:0l,$
   beginwval:0.0,endwval:0.0,avwid:0l,rvwid:0l,ccwid:0l,ffwid:0l,$
   beginwfile:0.0,endwfile:0.0,dispfile:0.0,zfile:fltarr(sizelimit),rvfile:0.0,$
   avfile:fltarr(sizelimit),ccfile:fltarr(sizelimit),fffile:fltarr(sizelimit),$
   psfilewid:0l,psfile:' ',psflag:0l,$
   outgalfilewid:0l,outgalfile:' ',$
   outobsfilewid:0l,outobsfile:' ',$
   outsubfilewid:0l,outsubfile:' ',$
   outsgsmooth_subfilewid:0l,outsgsmooth_subfile:' ',$
   outsgsmooth_origfilewid:0l,outsgsmooth_origfile:' ',$
   outtempfilewid:0l,outtempfile:' ',$
   xminwid:0l,xmaxwid:0l,yminwid:0l,ymaxwid:0l,$
   ymin:0.0,ymax:0.0,xmin:0.0,xmax:0.0,$
   type:' ',numberoftype:0,numtocompare:0,epoch:0.0,err_epoch:0.0,$
   obstxtwid:0l,obstxtval:' ',$
   temptxtwid:0l,temptxtval:' ',$
   wpprwid:0l,wpprval:' ',$
   wppbwid:0l,wppbval:' ',$
   npixwid:0l,npixval:0.0,$
   degreewid:0l,degreeval:0.0,$
   subselected:0l,smsubselected:0l,$
   galselected:0l,tempselected:0l,$
   origselected:0l,smorigselected:0l,$
   subsensgroup:0l,subbuttonwid:0l,$
   smsubsensgroup:0l,smsubbuttonwid:0l,$
   origsensgroup:0l,origbuttonwid:0l,$
   smorigsensgroup:0l,smorigbuttonwid:0l,$
   tempsensgroup:0l,tempbuttonwid:0l,$
   galsensgroup:0l,galbuttonwid:0l,$
   tempoffsetwid:0l,tempoffsetval:0.0,$
   origoffsetwid:0l,origoffsetval:0.0,$
   suboffsetwid:0l,suboffsetval:0.0,$
   smsuboffsetwid:0l,smsuboffsetval:0.0,$
   smorigoffsetwid:0l,smorigoffsetval:0.0,$
   galoffsetwid:0l,galoffsetval:0.0,$
   origcolor:' ',smorigcolor:' ',$
   subcolor:' ',smsubcolor:' ',$
   galcolor:' ',tempcolor:' ',$
   colorselectorbase:0l,origcolorwid:0l,smorigcolorwid:0l,$
   subcolorwid:0l,smsubcolorwid:0l,$
   galcolorwid:0l,tempcolorwid:0l,$
   legendxwid:0l,legendxval:0.0,$
   legendywid:0l,legendyval:0.0,$
   oldthick:1,oldcharthick:1,oldxthick:1,$
   oldythick:1,oldcolor:0,oldbackground:0,$
   sgsensgroup:0l,textoutputbase:0l,$
   niter:0l,sigmasource:' ',sf_installdir:' ',sf_workingdir:' ',$
   nsigma:0.0,grow:0l,$
   typetextwid:0l,typetextval:' ',ofileroot:' ',colornames:strarr(19)$
}


b.sf_installdir=GETENV('SF_INSTALLDIR')
b.sf_workingdir=GETENV('SF_WORKINGDIR')

; add trailing slashes to the paths if necessary
IF b.sf_workingdir NE '' THEN BEGIN
;add a slash at the end of the path if there isn't one
   slashpos=STRPOS(b.sf_workingdir,'/',/REVERSE_SEARCH)
   IF (slashpos NE STRLEN(b.sf_workingdir)-1) THEN b.sf_workingdir = b.sf_workingdir + '/'
ENDIF ELSE BEGIN
   PRINT,'Using current working directory as default for browsing'  
   PRINT,'To use a different default, set the environment variable SF_WORKINGDIR'
   PRINT,''
ENDELSE

IF b.sf_installdir NE '' THEN BEGIN
;add a slash at the end of the path if there isn't one
   slashpos=STRPOS(b.sf_installdir,'/',/REVERSE_SEARCH)
   IF (slashpos NE STRLEN(b.sf_installdir)-1) THEN b.sf_installdir = b.sf_installdir + '/'
ENDIF ELSE BEGIN
   PRINT,'Environment variable SF_INSTALLDIR not set'
   PRINT,'Please set this environment variable to the directory that contains'
   PRINT,'the superfit installation.  E.g. put a line like the following in'
   PRINT,'your .bashrc or .cshrc (or other appropriate) file.'
   PRINT,'bash: export SF_INSTALLDIR=/home/howell/idl/superfit'
   PRINT,'csh: setenv SF_INSTALLDIR /home/howell/idl/superfit'
   GOTO,endpoint
ENDELSE

;save user's settings
b.oldthick=!P.THICK
b.oldcharthick=!P.CHARTHICK
b.oldxthick=!X.THICK
b.oldythick=!Y.THICK
b.oldcolor=!P.COLOR
b.oldbackground=!P.BACKGROUND



;read default colors from defaults.txt file
getdefaults,b

;; groups defined
b.base = WIDGET_BASE(/ROW,TITLE='supergraph')
panelgroup = WIDGET_BASE(b.base,/COLUMN)
infilegroup = WIDGET_BASE(panelgroup,/ROW)
label = WIDGET_LABEL(infilegroup,VALUE='Input file: ')
b.infilewid = WIDGET_TEXT(infilegroup,/EDITABLE,XSIZE=65,EVENT_PRO='infilereturnpro')

infilebutton = WIDGET_BUTTON(infilegroup, VALUE=' Browse... ',$
                          event_pro='infilebuttonpro')
selectorgroup = WIDGET_BASE(panelgroup,/COLUMN,/FRAME)
legendstr='        Supernova             S      z    gal    Av      cc      ff    gfrac sfrac'    
labbel = WIDGET_LABEL(selectorgroup,VALUE=legendstr)
b.selectorwid = WIDGET_LIST(selectorgroup,XSIZE=90,YSIZE=15,$
    EVENT_PRO='selector')

b.typetextwid=WIDGET_TEXT(panelgroup)
plotsmoothgroup = WIDGET_BASE(panelgroup,/ROW)
bigplotgroup = WIDGET_BASE(plotsmoothgroup,/COL,/FRAME)
smoothgroup = WIDGET_BASE(plotsmoothgroup,/COL,/FRAME)
plotgroup0 = WIDGET_BASE(bigplotgroup,/ROW)
plotinstructions = WIDGET_LABEL(plotgroup0,VALUE='Plots: check to show, enter offset in box: ')
colorbuttonwid = WIDGET_BUTTON(plotgroup0,VALUE=' Change Colors ',event_func='colorselector')
plotgroup1 = WIDGET_BASE(bigplotgroup,/ROW)
plotgroup2 = WIDGET_BASE(bigplotgroup,/ROW)
plotsubgroup = WIDGET_BASE(plotgroup1,/ROW)
  subbuttonbase = WIDGET_BASE(plotsubgroup,/column,/NONEXCLUSIVE,/ALIGN_CENTER)
  b.subbuttonwid = WIDGET_BUTTON(subbuttonbase,value='Obs-gal:',event_func='plotpicker')
  ;the next two lines set the initial state of the button (selected)
  WIDGET_CONTROL,b.subbuttonwid,/SET_BUTTON
  b.subselected=1
  b.subsensgroup = WIDGET_BASE(plotsubgroup,SENSITIVE=1,/ROW)
;change cw_field to widget_text?

;  b.suboffsetwid = CW_FIELD(b.subsensgroup,XSIZE=4,TITLE=' ',VALUE=0)
  b.suboffsetwid = WIDGET_TEXT(b.subsensgroup,XSIZE=4,VALUE='0',/EDITABLE,/ALL_EVENTS)
  

plotoriggroup = WIDGET_BASE(plotgroup1,/ROW)
  origbuttonbase = WIDGET_BASE(plotoriggroup,/column,/NONEXCLUSIVE,/ALIGN_CENTER)
  b.origbuttonwid = WIDGET_BUTTON(origbuttonbase,value='Orig. Obs:',event_func='plotpicker')
  b.origsensgroup = WIDGET_BASE(plotoriggroup,SENSITIVE=0,/ROW)
;  b.origoffsetwid = CW_FIELD(b.origsensgroup,XSIZE=4,TITLE="",VALUE=0)
  b.origoffsetwid = WIDGET_TEXT(b.origsensgroup,XSIZE=4,VALUE='0',/EDITABLE,/ALL_EVENTS)
plottempgroup = WIDGET_BASE(plotgroup1,/ROW)
  tempbuttonbase = WIDGET_BASE(plottempgroup,/column,/NONEXCLUSIVE,/ALIGN_CENTER)
  b.tempbuttonwid = WIDGET_BUTTON(tempbuttonbase,value='Temp:',event_func='plotpicker')
  ;the next two lines set the initial state of the button (selected)
  WIDGET_CONTROL,b.tempbuttonwid,/SET_BUTTON
  b.tempselected=1
  b.tempsensgroup = WIDGET_BASE(plottempgroup,SENSITIVE=1,/ROW)
;  b.tempoffsetwid = CW_FIELD(b.tempsensgroup,XSIZE=4,TITLE='',VALUE=0)
  b.tempoffsetwid = WIDGET_TEXT(b.tempsensgroup,XSIZE=4,VALUE='0',/EDITABLE,/ALL_EVENTS)
plotsmsubgroup = WIDGET_BASE(plotgroup2,/ROW)
  smsubbuttonbase = WIDGET_BASE(plotsmsubgroup,/column,/NONEXCLUSIVE,/ALIGN_CENTER)
  b.smsubbuttonwid = WIDGET_BUTTON(smsubbuttonbase,value='Sm. O-G:',event_func='plotpicker')
  b.smsubsensgroup = WIDGET_BASE(plotsmsubgroup,SENSITIVE=0,/ROW)
;  b.smsuboffsetwid = CW_FIELD(b.smsubsensgroup,XSIZE=4,TITLE='',VALUE=0)
  b.smsuboffsetwid = WIDGET_TEXT(b.smsubsensgroup,XSIZE=4,VALUE='0',/EDITABLE,/ALL_EVENTS)
plotsmoriggroup = WIDGET_BASE(plotgroup2,/ROW)
  smorigbuttonbase = WIDGET_BASE(plotsmoriggroup,/column,/NONEXCLUSIVE,/ALIGN_CENTER)
  b.smorigbuttonwid = WIDGET_BUTTON(smorigbuttonbase,value='Smth. Obs:',event_func='plotpicker')
  b.smorigsensgroup = WIDGET_BASE(plotsmoriggroup,SENSITIVE=0,/ROW)
;  b.smorigoffsetwid = CW_FIELD(b.smorigsensgroup,XSIZE=4,TITLE='',VALUE=0)
  b.smorigoffsetwid = WIDGET_TEXT(b.smorigsensgroup,XSIZE=4,VALUE='0',/EDITABLE,/ALL_EVENTS)
plotgalgroup = WIDGET_BASE(plotgroup2,/ROW)
  galbuttonbase = WIDGET_BASE(plotgalgroup,/column,/NONEXCLUSIVE,/ALIGN_CENTER)
  b.galbuttonwid = WIDGET_BUTTON(galbuttonbase,value='Gal: ',event_func='plotpicker')
  b.galsensgroup = WIDGET_BASE(plotgalgroup,SENSITIVE=0,/ROW)
;  b.galoffsetwid = CW_FIELD(b.galsensgroup,XSIZE=4,TITLE='',VALUE=0)
  b.galoffsetwid = WIDGET_TEXT(b.galsensgroup,XSIZE=4,VALUE='0',/EDITABLE,/ALL_EVENTS)

b.sgsensgroup = WIDGET_BASE(smoothgroup,/COL,SENSITIVE=0)
smlabel = WIDGET_LABEL(b.sgsensgroup,VALUE='Smoothing')
parlabel = WIDGET_LABEL(b.sgsensgroup,VALUE='parameters:')
b.npixwid = CW_FIELD(b.sgsensgroup,XSIZE=3,TITLE='Npix/2: ',VALUE=120)
b.degreewid = CW_FIELD(b.sgsensgroup,XSIZE=3, TITLE='Degree: ',VALUE=3)

tempgroup = WIDGET_BASE(plotgroup1,/ROW)
zrow = WIDGET_BASE(panelgroup,/ROW,/FRAME)
scalerow = WIDGET_BASE(panelgroup,/ROW,/FRAME)
thirdrow = WIDGET_BASE(panelgroup,/ROW,/FRAME)
fourthrow = WIDGET_BASE(panelgroup,/ROW,/FRAME)
b.beginwwid=CW_FIELD(zrow,XSIZE=8,TITLE="beginw: ")
b.endwwid=CW_FIELD(zrow,XSIZE=10,TITLE=" endw: ")
b.zwid=CW_FIELD(zrow,XSIZE=9,TITLE="       z: ")
b.dispwid=CW_FIELD(zrow,XSIZE=9,TITLE="   Bin (A): ")
b.rvwid=CW_FIELD(scalerow,XSIZE=8,TITLE="    Rv: ")
b.avwid=CW_FIELD(scalerow,XSIZE=10,TITLE="   Av: ")
b.ccwid=CW_FIELD(scalerow,XSIZE=9,TITLE="SN scale: ")
b.ffwid=CW_FIELD(scalerow,XSIZE=9,TITLE="Gal. scale: ")
b.xminwid=CW_FIELD(thirdrow,XSIZE=8,TITLE=" X min: ")
b.xmaxwid=CW_FIELD(thirdrow,XSIZE=10,TITLE="X max: ")
b.yminwid=CW_FIELD(thirdrow,XSIZE=9,TITLE="   Y min: ")
b.ymaxwid=CW_FIELD(thirdrow,XSIZE=9,TITLE="     Y max: ")
b.obstxtwid=CW_FIELD(fourthrow,XSIZE=23,TITLE="O str: ")
b.temptxtwid=CW_FIELD(fourthrow,XSIZE=23,TITLE="T str: ")
b.legendxwid=CW_FIELD(fourthrow,XSIZE=4,TITLE="@X:",VALUE=0.16)
b.legendywid=CW_FIELD(fourthrow,XSIZE=4,TITLE="Y:",VALUE=0.15)
psgroup = WIDGET_BASE(panelgroup, /ROW,/FRAME)
label = WIDGET_LABEL(psgroup,VALUE='PS file: ')
b.psfilewid = WIDGET_TEXT(psgroup,/EDITABLE,XSIZE=66)
button2 = WIDGET_BUTTON(psgroup, VALUE=' Generate PS ',event_pro='psbutton')

;; stuff for original sggui base
;; OK and Cancel buttons:
botbar = WIDGET_BASE(panelgroup,/row,uvalue='Botbar')
button3 = WIDGET_BUTTON(botbar, value='  Done  ',event_pro='donebutton')
button_output = WIDGET_BUTTON(botbar, value=' Text Output  ',event_pro='textoutput')
button1 = WIDGET_BUTTON(botbar, VALUE=' Redraw ',event_pro='redraw')
label2=WIDGET_LABEL(botbar,VALUE=" Obs. A / pix blue:")
b.wppbwid = WIDGET_TEXT(botbar,XSIZE=6)
label3=WIDGET_LABEL(botbar,VALUE=" Obs. A / pix red:")
b.wpprwid = WIDGET_TEXT(botbar,XSIZE=6)



IF KEYWORD_SET(file) THEN BEGIN
    b.file=file
    WIDGET_CONTROL,b.infilewid,SET_VALUE=b.file
    junk=infiledo(b)
ENDIF            

WIDGET_CONTROL, b.base, SET_UVALUE=b
WIDGET_CONTROL, b.base, /REALIZE

XMANAGER, 'gui', b.base

endpoint:
END
