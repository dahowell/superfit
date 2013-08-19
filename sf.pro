PRO sf, o=o, w1=w1, w2=w2, disp=disp, zl=zl, zu=zu, zi=zi, $
    weight=weight, dir=dir, gspec=gspec, Rv=Rv,galnames=galnames, $
    avmin=avmin, avmax=avmax, galscale=galscale, tempscale=tempscale, $
    results=results, tempfile=tempfile, sfracrequire=sfracrequire,$
    nsigma=nsigma,grow=grow,niter=niter,sigmasource=sigmasource,version=version,nobar=nobar
IF KEYWORD_SET(version) THEN BEGIN 
   print,"sf.pro Version 3.5 August 30, 2012.  Author: Andy Howell."
   print,"Documentation at: http://qold.astro.utoronto.ca/~howell/superfit/superfit.htm"
   GOTO,endpoint
ENDIF

filter='V'
;tryprint=' '
time=SYSTIME(1)

;figure out directories from environment variables
sf_installdir=GETENV('SF_INSTALLDIR')
PRINT ,GETENV('SF_INSTALLDIR')
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
   GOTO,endpoint
ENDELSE


;set default variables
IF N_ELEMENTS(sfracrequire) eq 0 THEN sfracrequire = 0.7
IF N_ELEMENTS(grow) eq 0 THEN grow = 0
IF N_ELEMENTS(nsigma) eq 0 THEN nsigma = 2.7
IF N_ELEMENTS(niter) eq 0 THEN niter = 5
IF N_ELEMENTS(sigmasource) eq 0 THEN sigmasource = 'none'
IF N_ELEMENTS(tempfile) eq 0 THEN tempfile = sf_installdir+'savefiles/snelt10d.idlsave' 
   PRINT ,tempfile
   PRINT ,N_ELEMENTS(tempfile)
;; restore template files created by tempsetup.pro
restore,tempfile
;;restore galaxy template files created by galsetup.pro
restore,sf_installdir+'savefiles/galtemp.idlsave'
restore,sf_installdir+'savefiles/filters.idlsave'

;; cover case of no galaxies
IF ((N_ELEMENTS(galnames) eq 0) AND (N_ELEMENTS(gspec) eq 0)) THEN BEGIN
    galnames=['E']
    galscale=3.0
ENDIF

;; need to count up number of galaxies in a.galaxy (galnames) because
;; it is a structure and must always be 12
numgalnames=0
FOR I=0,N_ELEMENTS(galnames)-1 DO $
  IF galnames(I) ne '' THEN numgalnames=numgalnames+1

FOR I=0, numgalnames-1 DO BEGIN
    dummy = where(gal.file eq galnames[I],countdum)
    IF countdum gt 0 THEN BEGIN
        IF N_ELEMENTS(galsavindex) eq 0 THEN $
          galsavindex=dummy ELSE galsavindex = [galsavindex,dummy]
    ENDIF
ENDFOR
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; test and compute values from command line arguments
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IF (N_ELEMENTS(zl) NE 0 AND N_ELEMENTS(zu) NE 0 $
        AND NOT KEYWORD_SET(zi)) THEN BEGIN
   IF (zu eq zl) THEN BEGIN
      PRINT,'Using redshift: ',zl
      zelements=1
      lowerz=1
      zi=zl
   ENDIF ELSE BEGIN
      PRINT,'No zi set, using 0.01.'
      zi=0.01
   ENDELSE
   
ENDIF  

IF ((N_ELEMENTS(zl) gt 0) AND (N_ELEMENTS(zu) gt 0) $
    AND KEYWORD_SET(zi)) THEN BEGIN
   upperz=ROUND(zu/zi)
   lowerz=ROUND(zl/zi)
   zelements=upperz-lowerz+1
ENDIF ELSE BEGIN
   IF ((N_ELEMENTS(zl) EQ 0) OR (N_ELEMENTS(zu) EQ 0)) THEN BEGIN
      PRINT,'At least one of keywords zl, zu not present, using defaults'
      upperz=0
      lowerz=0
      zelements=upperz-lowerz+1
      zi=0
      zl=0
      zu=0
   ENDIF
ENDELSE



;; if w1 or w2 not present, set them extreme so they will be superceded later 
IF KEYWORD_SET(w1) THEN beginw=w1 ELSE beginw=2000 
IF KEYWORD_SET(w2) THEN endw=w2 ELSE endw=10000
IF N_ELEMENTS(Rv) eq 0 THEN Rv=3.1
IF N_ELEMENTS(avmin) eq 0 THEN avmin=-1.0
IF N_ELEMENTS(avmax) eq 0 THEN avmax=2.0
IF N_ELEMENTS(tempscale) eq 0 THEN tempscale=3.0
IF N_ELEMENTS(galscale) eq 0 THEN galscale=3.0
IF (N_ELEMENTS(disp) eq 0) THEN disp=20
;IF (N_ELEMENTS(errorflag) eq 0) THEN errorflag=0
IF (N_ELEMENTS(weight) eq 0) THEN weight=sf_installdir+'savefiles/one.weight'


;;; if there is an input galaxy spectrum, set parameters accordingly
IF (KEYWORD_SET(gspec)) THEN BEGIN
    ;gspecout=dirgetter(gspec)
    gspecout=gspec
    readfile,gspecout,gspecinw,gspecinf,splitpos
    numgals=N_ELEMENTS(galsavindex) + 1
ENDIF ELSE numgals=N_ELEMENTS(galsavindex)

;;;;;;;;;;;;;;;;;;; observations ;;;;;;;;;;;;;;;;;;;;;;;;;;;

IF N_ELEMENTS(o) eq 0 THEN $
  PRINT,'You did not enter an observed spectrum.' $
ELSE ofile=o

PRINT, 'Reading in object spectrum:  ',ofile
readfile,ofile,obsinw,obsinf,splitpos

firsthalf=STRMID(ofile,0,splitpos)
;; if output file not specified, make one
IF (N_ELEMENTS(results) eq 0) THEN BEGIN
    results=firsthalf+'.sfo'
ENDIF 
PRINT,'Output stored in: ',results

;;;;;;;;;;; weights ;;;;;;;;;;;;;;;;;;;;;;;;;;
; if getting the weights from the 3rd column of the input file, then weight=o
; as set by sfgui

PRINT, 'Reading in error spectrum:  ',weight
IF (weight EQ o) THEN $
  READCOL, weight,  weightw, dummy, weightf,  FORMAT='d,d,d', /SILENT $
ELSE readfile,weight,weightw,weightf,splitpos

;PLOT,obsinw,obsinf,/NODATA,color=colordex('black')
;OPLOT,obsinw,obsinf,color=colordex('red')
; do clipping

IF sigmasource EQ 'input' THEN BEGIN
   IF N_ELEMENTS(weightw) EQ N_ELEMENTS(obsinw) THEN BEGIN
      PRINT,'Cleaning spectrum using input error spectrum, nsigma: ',nsigma
      obsinf=lineclean(obsinw,obsinf,nsigma,grow,niter,weightf) 
   ENDIF ELSE BEGIN 
      PRINT,"ERROR: Input spectrum and weight spectrum have different sampling."
      PRINT,"You cannot chose 'input' for sigma clippint unless you give an input spectrum.."
      GOTO,endpoint
   ENDELSE
ENDIF ELSE BEGIN 
   IF sigmasource EQ 'calculate' THEN BEGIN
      obsinf=lineclean(obsinw,obsinf,nsigma,grow,niter) 
      PRINT,'Cleaning spectrum using standard deviation.  nsigma: ',nsigma
   ENDIF
ENDELSE

;PLOT,obsinw,obsinf,color=colordex('black')

;; normalize so numbers reasonable
weightf=weightf/median(weightf) 
obsinf=obsinf/median(obsinf)

;; make weights be 1/sigma^2
weightf=1.0/(weightf*weightf)
    
;;;;;;;;;;;; test output ;;;;;;;;;;;;;;;;;;;;;;;
IF (beginw lt obsinw(0)) THEN BEGIN
    beginw=obsinw(0)
    PRINT,'Using shortest observed wavelength as begin wavelength: ',beginw
ENDIF
    
IF (endw gt obsinw(n_elements(obsinw)-1)) THEN BEGIN
    endw=obsinw(n_elements(obsinw)-1)
    PRINT,'Using longest observed wavelength as end wavelength: ',endw
ENDIF
    
;;make sure weights are sampled at same points as flux
;linterp,weightw,weightf,obsinw,weightf
;;call fixgap which fixes gaps in the spectrum if any exist
;fixgap,obsinw,obsinf,weightf,obsinw,obsinf,weightf

obsf=double(binspec_weighted(obsinw,obsinf,beginw,endw,disp,obsw,weightw,weightf,iweightf))


S=dblarr(N_ELEMENTS(snt),numgals,zelements)
verybestGS=dblarr(N_ELEMENTS(snt))
verybestzfort=dblarr(N_ELEMENTS(snt))
verybestG=strarr(N_ELEMENTS(snt))
verybestGcc=strarr(N_ELEMENTS(snt))
verybestGaa=strarr(N_ELEMENTS(snt))
verybestGgfrac=strarr(N_ELEMENTS(snt))
verybestGff=strarr(N_ELEMENTS(snt))
verybestGsfrac=strarr(N_ELEMENTS(snt))
bestzfort=0
bestG=0
bestGaa=0
bestGgfrac=0
bestGcc=0
bestGff=0
bestzgfrac=0
bestGsfrac=0

    ;;;;;;;;;;;;;;; do templates ;;;;;;;;;;;;;;;;;;;;
IF NOT KEYWORD_SET(nobar) THEN BEGIN
;   RESOLVE_ROUTINE,sf_installdir+'showprogress__define',/COMPILE_FULL_FILE
   RESOLVE_ROUTINE,'showprogress__define',/COMPILE_FULL_FILE
   progressBar = Obj_New("SHOWPROGRESS")
   progressBar->SetColor, colordex('blue')
;progressBar->SetProperty, XSize=300
   progressBar->Start
ENDIF

FOR J=0,N_ELEMENTS(snt)-1 DO BEGIN
    tfile = snt(J).file
IF KEYWORD_SET(nobar) THEN PRINT, 'Checking template:  ',tfile
    ;;readcol, tfile,  tempinw,  tempinf,  /silent
    
    ;; get rid of the 0's introduced by tempsetup:
    index=WHERE(snt(J).w ne 0,count)
    IF count NE 0 THEN BEGIN
        tempinw = snt(J).w[index]
        tempinf = snt(J).f[index]
    ENDIF
    
    mediantempinf=median(tempinf)
    tempinf=double(tempinf/mediantempinf)
    tempinw=double(tempinw)
    
    FOR H=0, numgals-1 DO BEGIN
        IF (H eq 0) THEN bestGS=999        
        ;; H is order of this loop, G is number in idl save file
        
        IF ((H eq numgals-1) AND (N_ELEMENTS(galsavindex) ne numgals)) $
          THEN BEGIN
            ;; this should be the last loop
            IF KEYWORD_SET(nobar) THEN PRINT,'Checking galaxy:  ',gspecout
            ; case where there is an input galaxy
            galinfile='inp'
            galinw=gspecinw
            galinf=gspecinf
        ENDIF ELSE BEGIN
            G=galsavindex(H)
            IF KEYWORD_SET(nobar) THEN PRINT,'Checking galaxy:  ',gal(G).file
            galinfile=gal(G).file
            gindex=WHERE(gal(G).w gt 0,gcount)
            IF gcount NE 0 THEN BEGIN
                galinw=gal(G).w[gindex]
                galinf=gal(G).f[gindex]
            ENDIF    
        ENDELSE
        
        mediangalinf=median(galinf)
        galinf=double(galinf/mediangalinf)                
        
        FOR I=0,zelements-1 DO BEGIN
            IF (I eq 0) THEN bestzS=999
            ;; do redshifts
            z = zi * (I+lowerz)
            zp1 = 1.0 + z
            tempwred = zp1 * tempinw
            
            ;redshift the galaxy spectrum only if
            ;it isn't the observed galaxy spectrum
            IF (galinfile NE 'inp') THEN galwred = zp1 * galinw $
              ELSE galwred=galinw
            
            
            ;; test to see if spectrum covers full range
            ;; if it does not, then set sflag=1
            sflag=0
            sfrac=0
            IF (tempwred(0) gt beginw) THEN BEGIN
                sbeginw = tempwred(0)
                sflag=1
            ENDIF ELSE sbeginw = beginw

            IF (tempwred(n_elements(tempwred)-1) lt endw) THEN BEGIN
                sendw = tempwred(n_elements(tempwred)-1)
                sflag=1
            ENDIF ELSE sendw = endw
            sfrac=(sendw-sbeginw)/(endw-beginw)

            IF (sfrac lt sfracrequire) THEN BEGIN
                IF KEYWORD_SET(nobar) THEN PRINT,'Warning: redshifted spectrum exceeded input limits'
                IF KEYWORD_SET(nobar) THEN PRINT,'Not fitting ',snt(J).file,' at z=',z
                S[J,H,I]=999
                GOTO,gotopoint
            ENDIF

            tempf=double(binspec_weighted(tempwred,tempinf,sbeginw,sendw,disp,tempw))
            tempw=double(tempw)
            galf=double(binspec_weighted(galwred,galinf,sbeginw,sendw,disp,galw))

            IF (sflag) THEN BEGIN
                sobsf=double(binspec_weighted(obsinw,obsinf,sbeginw,sendw,disp,sobsw,weightw,weightf,siweightf))
                IF KEYWORD_SET(nobar) THEN PRINT,'Fractional wavelength coverage: ',sfrac
                unredshiftedw=sobsw/zp1

            ENDIF ELSE BEGIN                
            ;    sfrac = 1.0
            ;    tempf=double(binspec_weighted(tempwred,tempinf,beginw,endw,disp,tempw))
            ;    tempw=double(tempw)
            ;    galf=double(binspec_weighted(galwred,galinf,beginw,endw,disp,galw))
                unredshiftedw=obsw/zp1

            ENDELSE

            ;; need to switch min and max because of the negative sign
            aamin=-avmax/2.5
            aamax=-avmin/2.5
            redlawf=mkafromlam(unredshiftedw,Rv)
            xbnd = [[aamin, 0.01, 0.0], [aamax, tempscale, galscale]]
            gbnd = [[0], [0]]
            nobj = 0
            gcomp = 'minfuncred'
            title = 'IDL: min'
            X=[0.0, 0.6, 0.6]
            
            IF (sflag) THEN $
              junk=mkcommonred(sobsf,tempf,galf,redlawf,siweightf,sobsw) $
            ELSE junk=mkcommonred(obsf,tempf,galf,redlawf,iweightf,obsw)

            CONSTRAINED_MIN, X, xbnd, gbnd, nobj, gcomp, inform, $
              REPORT = report, TITLE = title
            result = minfuncred(X)
            aa=X[0]
            cc=X[1]
            ff=X[2]
            newtempf=cc*tempf*10^(aa*redlawf)
            galterm=ff*galf
            
            ;; calculate fraction of host galaxy to total light in
            ;; a filter

            IF (sflag) THEN $
              S[J,H,I]=total((sobsf-newtempf-galterm)*siweightf*$
                             (sobsf-newtempf-galterm))/sfrac $
            ELSE S[J,H,I]=total((obsf-newtempf-galterm)*iweightf*$
                                (obsf-newtempf-galterm)) 
            
            gotopoint:
            IF (S[J,H,I] lt bestzS) THEN BEGIN
                bestzS=S[J,H,I]
                bestz=z
                bestzcc=cc
                bestzff=ff
                bestzaa=aa
                bestzsfrac=sfrac
            ENDIF
                
        ENDFOR  ;;redshift
            
        IF (bestzS lt bestGS) THEN BEGIN
            bestGS=bestzS
            bestzfort=bestz      
            bestG=galinfile
            bestGgfrac=bestzgfrac
            bestGaa=bestzaa
            bestGcc=bestzcc
            bestGff=bestzff
            bestGsfrac=bestzsfrac
        ENDIF
            
    ENDFOR  ;;galaxy
        
    verybestGS[J]=bestGS
    verybestzfort[J]=bestzfort
    verybestG[J]=bestG
    verybestGgfrac[J]=bestGgfrac
    verybestGaa[J]=bestGaa
    verybestGcc[J]=bestGcc
    verybestGff[J]=bestGff
    verybestGsfrac[J]=bestGsfrac

percent = (J+1)*100.0/double(N_ELEMENTS(snt))
IF NOT KEYWORD_SET(nobar) THEN progressBar->Update, percent
    
ENDFOR                          ;template  

IF NOT KEYWORD_SET(nobar) THEN progressBar->Destroy
IF NOT KEYWORD_SET(nobar) THEN Obj_Destroy, progressBar

;; renormalize
sortindex=sort([verybestGS])
minS=verybestGS[sortindex(0)]

;; make sure the best match isn't with itself
IF (minS le 1E-7) THEN BEGIN
    w=WHERE(verybestGS ne minS,count)
    IF (count gt 0) THEN minS=min(verybestGS(w))
ENDIF

;; compute galaxy fractions
;; read in filter info from save file


;;CASE filter OF
;;    'B': filtnum=0
;;    'V': filtnum=1
;;    'R': filtnum=2
;;    'I': filtnum=3
;;ENDCASE

;;index=WHERE(filt(filtnum).w gt 0,count)
;;IF count NE 0 THEN BEGIN
;;    filtwin = filt(filtnum).w[index]
;;    filtfin = filt(filtnum).f[index]
;;ENDIF

;; set filter to roughly rest-frame B-band
beginfilter = 0 
endfilter = 0
obssum=0.0
;; determine begin and endpoints for filter flux

;;;IF (sflag AND NOT requirefullwav) THEN BEGIN
;;IF ((sfrac ge sfracrequire) AND (sfrac ne 1.0)) THEN BEGIN
;;    FOR P=1,N_ELEMENTS(sobsw)-1 DO BEGIN
;;        IF (beginfilter eq 0) AND (sobsw[P] ge filtwin[0]) THEN beginfilter = sobsw[P]
;;        IF (endfilter eq 0) AND (sobsw[P] ge filtwin[N_ELEMENTS(filtwin)-1]) THEN $
;;          endfilter = sobsw[P-1]
;;    ENDFOR    
;;ENDIF ELSE IF (sfrac eq 1.0) THEN BEGIN
;;    FOR P=1,N_ELEMENTS(obsw)-1 DO BEGIN
;;        IF (beginfilter eq 0) AND (obsw[P] ge filtwin[0]) THEN beginfilter = obsw[P]
;;        IF (endfilter eq 0) AND (obsw[P] ge filtwin[N_ELEMENTS(filtwin)-1]) THEN $
;;          endfilter = obsw[P-1]
;;    ENDFOR    
;;ENDIF

;;;; bin filter function to match spectra
;;IF (beginfilter eq 0 or endfilter eq 0) THEN $
;;  PRINT,'Filter range extends beyond observed spectrum range' $
;;ELSE filtf=binspec_weighted(filtwin,filtfin,beginfilter,endfilter,disp,filtw)

;;;; determine indicies of obsw where filter overlaps, put into matcharray
;;counter=0

;;IF ((sfrac ge sfracrequire) AND (sfrac ne 1.0)) THEN BEGIN
;;    FOR P=0,N_ELEMENTS(filtw)-1 DO BEGIN
;;        matchindex=where(sobsw eq filtw[P],countmatch)
;;        IF (countmatch) THEN BEGIN
;;            obssum = obssum + sobsf[matchindex] * filtf[P]
;;            counter = counter+1
;;        ENDIF
;;        IF (counter eq 1) THEN matcharray=matchindex ELSE matcharray=[matcharray,matchindex] 
;;    ENDFOR
;;ENDIF ELSE IF (sfrac eq 1.0) THEN BEGIN
;;   FOR P=0,N_ELEMENTS(filtw)-1 DO BEGIN
;;        matchindex=where(obsw eq filtw[P],countmatch)
;;        IF (countmatch) THEN BEGIN
;;            obssum = obssum + obsf[matchindex] * filtf[P]
;;            counter = counter+1
;;        ENDIF
;;       IF (counter eq 1) THEN matcharray=matchindex ELSE matcharray=[matcharray,matchindex] 
;;    ENDFOR
;;ENDIF


OPENW,1,results

;; change aa to Av
verybestGav=-2.5*verybestGaa

FOR M=0,N_ELEMENTS(snt)-1 DO BEGIN
    galsum=0.0
    obssum=0.0
    IF(verybestGS[sortindex[M]] lt 999.0) THEN BEGIN
        ;; calculate galaxy fraction -- need to do it here because it
        ;; is an expensive calculation
        ;; if there is an input galaxy spectrum, use else use gal templates
        ;;galaxy = gdir+verybestG[sortindex[M]]
        
        FOR H = 0,numgals-1 DO BEGIN
            IF ((H eq numgals-1) AND (N_ELEMENTS(galsavindex) ne numgals)) $
              THEN BEGIN
                ;; this should be the last loop
                IF (verybestG[sortindex[M]] eq 'inp') THEN BEGIN
                    galinw=gspecinw
                    galinf=gspecinf
                ENDIF
            ENDIF ELSE BEGIN
                G=galsavindex(H)
                IF (gal(G).file eq verybestG[sortindex[M]]) THEN BEGIN
                    gindex=WHERE(gal(G).w gt 0,gcount)
                    IF gcount NE 0 THEN BEGIN
                        galinw=gal(G).w[gindex]
                        galinf=gal(G).f[gindex]
                    ENDIF
                ENDIF
            ENDELSE
        ENDFOR
        
        mediangalinf=median(galinf)
        galinf=double(galinf/mediangalinf)                
        galwred = (1 + verybestzfort[sortindex[M]]) * galinw
        galf=double(binspec_weighted(galwred,galinf,beginw,endw,disp,galw))    
        galterm=verybestGff[sortindex[M]]*galf
        
        
        galsum=0.0

        ;; determine redshifted start and end points for galaxy
        ;; fraction computation.  4000-5000 is roughly rest B band
        gfracwavstart = (1 + verybestzfort[sortindex[M]]) * 4000.0
        gfracwavend = (1 + verybestzfort[sortindex[M]]) * 5000.0

        ;; determine galaxy sum

        ; To determine galaxy fraction, start by calculating between
        ; gfracwavstart and gfracwavend, but if that doesn't work, 
        ; just use the whole array
        wx=where(galw ge gfracwavstart AND galw le gfracwavend,cx)
        IF cx GT 0 THEN galsum=TOTAL(galterm[wx]) ELSE galsum=TOTAL(galterm)
        ;FOR P=0,N_ELEMENTS(galterm)-1 DO BEGIN
            ;PRINT,galw[P],gfracwavstart,gfracwavend
        ;   IF ((galw[P] ge gfracwavstart) AND (galw[P] le gfracwavend)) $ 
        ;     THEN BEGIN
        ;       galsum=galsum + galterm[P]
        ;       ;PRINT,'Summing'
        ;   ENDIF
        ;ENDFOR

        ;; determine observation sum
        ;; 2 cases?  one for sobsf and one for obsf?

        IF ((verybestGsfrac[sortindex[M]] ge sfracrequire) AND (verybestGsfrac[sortindex[M]] ne 1.0)) THEN BEGIN
           wy=where(sobsw ge gfracwavstart AND sobsw le gfracwavend,cy)
           IF cy GT 0 THEN obssum=TOTAL(sobsf[wy]) ELSE obssum=TOTAL(sobsf)
            ;FOR P=0,N_ELEMENTS(sobsw)-1 DO BEGIN
            ;    IF ((sobsw[P] ge gfracwavstart) AND (sobsw[P] le gfracwavend)) $ 
            ;      THEN obssum=obssum + sobsf[P]
            ;ENDFOR
        ENDIF ELSE IF (verybestGsfrac[sortindex[M]] eq 1.0) THEN BEGIN
           wz=where(obsw ge gfracwavstart AND obsw le gfracwavend,cz)
           IF cz GT 0 THEN obssum=TOTAL(obsf[wz]) ELSE obssum=TOTAL(obsf)
           ; FOR P=0,N_ELEMENTS(obsw)-1 DO BEGIN
           ;     IF ((obsw[P] ge gfracwavstart) AND (obsw[P] le gfracwavend)) $ 
           ;       THEN obssum=obssum + obsf[P]
           ; ENDFOR
        ENDIF 
;        IF (obssum EQ 0) THEN print,sfrac

    ENDIF ELSE verybestGgfrac[sortindex[M]]=9.999
    ;PRINT,'Galsum: ',galsum
    ;PRINT,'Obssum: ',obssum
    
    IF verybestGS[sortindex[M]] eq 999 THEN BEGIN 
        verybestzfort[sortindex[M]] = 9.999 
        verybestG[sortindex[M]] = 'xxx'
        verybestGav[sortindex[M]] = -9.9999
        verybestGcc[sortindex[M]] = 9.9999
        verybestGff[sortindex[M]]= 9.9999
        verybestGgfrac[sortindex[M]] = 9.999 
        verybestGsfrac[sortindex[M]] = 9.99
    ENDIF

    IF (verybestGgfrac[sortindex[M]] lt 9) THEN BEGIN
       verybestGgfrac[sortindex[M]]=galsum/obssum   
       IF NOT FINITE(verybestGgfrac[sortindex[M]]) THEN BEGIN
          PRINT,'NaN in gfrac: galsum, obssum:',snt[sortindex[M]].file,galsum,obssum
       ENDIF
    ENDIF

    PRINTF,1,snt[sortindex[M]].file,verybestGS[sortindex[M]], $
      verybestzfort[sortindex[M]], verybestG[sortindex[M]], $
      verybestGav[sortindex[M]],verybestGcc[sortindex[M]],$
      verybestGff[sortindex[M]],verybestGgfrac[sortindex[M]],$ 
      verybestGsfrac[sortindex[M]],$
      FORMAT= '(A30,F9.3,F8.4,A4,F8.4,F8.4,F8.4,F7.3,F5.2)' 

ENDFOR

type=strarr(5)
daystr=strarr(5)
daynum=intarr(5)
daysign=intarr(5)
sig_weight=dblarr(5)
avgcount=0
numerator=0
denominator=0
numberoftype=0

numtocompare=min([5,N_ELEMENTS(sortindex)])
;; calculate weighted avg of days after max
;; and type of SN
FOR I=0,numtocompare-1 DO BEGIN
    starttypepos=STRPOS(snt[sortindex[I]].file,'sne/')
    enddatepos=STRPOS(snt[sortindex[I]].file,'.dat',/REVERSE_SEARCH)
    IF (starttypepos ne -1) THEN BEGIN
        type[I]=STRMID(snt[sortindex[I]].file,starttypepos+4,2) 
        IF (type[I] eq '99') THEN type[I] = 'Ia'
        IF (type[I] eq 'Ib') THEN type[I] = 'Ib'
        daystr[I]=STRMID(snt[sortindex[I]].file,enddatepos-4,4)
        IF (STRCMP(daystr[I],'.',1)) THEN BEGIN
            dayprefix=STRMID(daystr[I],1,1)
            daynumstr=STRMID(daystr[I],2,2)
        ENDIF ELSE BEGIN
            ;; in case the date has 3 digits, e.g. p111
            dayprefix=STRMID(daystr[I],0,1)
            daynumstr=STRMID(daystr[I],1,3)
        ENDELSE
        CASE (dayprefix) OF
            'm': daysign[I]=-1
            'p': daysign[I]=1
            'u': daysign[I]=0
        ENDCASE
        IF (type[I] eq type[0]) THEN BEGIN
            IF (daysign[I] ne 0) THEN BEGIN 
                IF daynumstr eq 'ax' THEN daynum[I]=0 $
                ELSE daynum[I]=FIX(daynumstr)
                daynum[I] = daysign[I] * daynum[I]
                sig_weight[I]=verybestGS[sortindex[I]]
                numerator=numerator + daynum[I]/sig_weight[I]
                denominator=denominator + 1.0/sig_weight[I]
            ENDIF
            numberoftype=numberoftype+1
        ENDIF
    ENDIF ELSE type='NS'  ;; Not a Supernova
ENDFOR
IF denominator ne 0 THEN weightedavg=numerator/denominator $
ELSE weightedavg=-99

w=where((type EQ type[0]) AND (daysign NE 0),count)
IF count GT 1 THEN BEGIN
   new_weighted_average=weighted_mean(daynum[w],sig_weight[w])
   wstddev=weighted_stddev(daynum[w],sig_weight[w])
ENDIF ELSE BEGIN
   new_weighted_average=weightedavg
   wstddev=2
ENDELSE

;PRINT,'Type: ',type[0]
;PRINT,'From ',numberoftype,' of the top ',numtocompare,format='(A5,I1,A12,I1)'
;PRINT,'Epoch (weighted average1): ',weightedavg,format='(A26,F6.2)'
;PRINT,'Epoch (weighted average): ',new_weighted_average,format='(A26,F6.2)'
;PRINT,'Error (weighted average): ',wstddev,format='(A26,F6.2)'

tempstr = ";;o = " + o
PRINTF,1,tempstr
PRINTF,1,';;disp = ',disp
PRINTF,1,';;zl = ',zl
PRINTF,1,';;zu = ',zu
PRINTF,1,';;zi = ',zi
PRINTF,1,';;beginw = ',beginw
PRINTF,1,';;endw = ',endw
;; do this so idl won't insert a line break
tempstr = ";;weight = " + weight
PRINTF,1,tempstr
PRINTF,1,';;Rv = ',Rv
PRINTF,1,';;avmin = ',avmin
PRINTF,1,';;avmax = ',avmax
PRINTF,1,';;tempscale = ',tempscale
PRINTF,1,';;galscale = ',galscale
tempstr = ";;results = " + results
PRINTF,1,tempstr
PRINTF,1,';;galnames = ',galnames
tempstr = ";;tempfile = " + tempfile
PRINTF,1,tempstr
IF (N_ELEMENTS(gspecout) gt 0) THEN BEGIN
    tempstr = ";;gspec = " + gspec
    PRINTF,1,tempstr
ENDIF
IF (N_ELEMENTS(w1) gt 0) THEN PRINTF,1,';;w1 = ',w1
IF (N_ELEMENTS(w2) gt 0) THEN PRINTF,1,';;w2 = ',w2
PRINTF,1,';;type = ',type[0]
PRINTF,1,';;epoch = ',new_weighted_average
PRINTF,1,';;err_epoch = ',wstddev
PRINTF,1,';;numberoftype = ',numberoftype
PRINTF,1,';;numtocompare = ',numtocompare
PRINTF,1,';;sfracrequire = ',sfracrequire
PRINTF,1,';;grow = ',grow
PRINTF,1,';;niter = ',niter
PRINTF,1,';;nsigma = ',nsigma
PRINTF,1,';;sigmasource = ',sigmasource


CLOSE,1
    
;ENDFOR
CLOSE,3
PRINT,SYSTIME(1)-time, ' Seconds'
endpoint:
END




