PRO fixgap,inwav,influx,inerr,outwav,outflux,outerr
;function to ensure there are no gaps in the spectrum
;anywhere there is a spectrum gap it adds wavelenth points with high error
;if there are no errors it adds poisson errors


myinwav=inwav
myinflux=influx
myinerr=inerr

;must be calculated outside the loop so it doesn't get screwed up on
;the second iteraton
maxerr=max(myinerr)

FOR i=0,1 DO BEGIN
;get wavelength interval per pixel
shifted=shift(myinwav,1)
diff=myinwav-shifted
wpp=diff[1]

max=max(diff,maxindex)

IF (max GE 3*wpp) THEN BEGIN 
   backhalf_wav=myinwav[maxindex:*]
   fronthalf_wav=myinwav[0:maxindex-1]
   backhalf_flux=myinflux[maxindex:*]
   fronthalf_flux=myinflux[0:maxindex-1]
   backhalf_err=myinerr[maxindex:*]
   fronthalf_err=myinerr[0:maxindex-1]
   
   nelements_tobefilled=fix((backhalf_wav[0]-fronthalf_wav[N_ELEMENTS(fronthalf_wav)-1])/wpp)
   remainder=(backhalf_wav[0]-fronthalf_wav[N_ELEMENTS(fronthalf_wav)-1]) MOD wpp
   IF remainder EQ 0 THEN nelements_tobefilled = nelements_tobefilled - 1

   
   tobefilled_flux=dblarr(nelements_tobefilled)
   tobefilled_err=dblarr(nelements_tobefilled)
   tobefilled_err=tobefilled_err+maxerr*100
   
   tobefilled_wav=findgen(nelements_tobefilled)+1
   tobefilled_wav=tobefilled_wav*wpp + fronthalf_wav[N_ELEMENTS(fronthalf_wav)-1]
   
   LINTERP,myinwav,myinflux,tobefilled_wav,tobefilled_flux
   outwav=[fronthalf_wav,tobefilled_wav,backhalf_wav]
   outflux=[fronthalf_flux,tobefilled_flux,backhalf_flux]
   outerr=[fronthalf_err,tobefilled_err,backhalf_err]

   ;prepare for second iteration
   myinwav=outwav
   myinflux=outflux
   myinerr=outerr
   
ENDIF ELSE BEGIN
   outwav=myinwav
   outflux=myinflux
   outerr=myinerr
ENDELSE
ENDFOR

END
