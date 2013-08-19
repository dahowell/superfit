PRO fixgap,inwav,influx,inerr,outwav,outflux,outerr
;function to ensure there are no gaps in the spectrum
;anywhere there is a spectrum gap (for up to 2 gaps) it adds wavelenth
;points, interpolated fluxes, and errors with 100 times the highest error.
;anywhere there is zero flux it strips away these data points and
;treats it as a gap

;make local copies of input parameters, because they will be modified
;for second iteration of loop.  also, strip away data points with zero flux
w=where(influx NE 0)
myinwav=inwav[w]
myinflux=influx[w]
myinerr=inerr[w]

;calculate maximum error outside the loop so it doesn't get screwed up on
;the second iteraton
maxerr=max(myinerr)

; do twice because there are two gaps for gemini
FOR i=0,1 DO BEGIN
   ;calculate wavelength interval by shifting in wavelength and subtracting
   shifted=shift(myinwav,1)
   diff=myinwav-shifted

   ;get wavelength interval per pixel.  not element zero because of wraparound
   wpp=diff[1]

   ;find the gap.  maxindex corresponds to the index right after the gap
   max=max(diff,maxindex)

   ;a gap is defined as 3 times the wavelength per pixel in the blue 
   IF (max GE 3*wpp) THEN BEGIN 

      ;figure out the pieces of the arrays on either side of the gap
      fronthalf_wav=myinwav[0:maxindex-1]
      backhalf_wav=myinwav[maxindex:*]
      fronthalf_flux=myinflux[0:maxindex-1]
      backhalf_flux=myinflux[maxindex:*]
      fronthalf_err=myinerr[0:maxindex-1]
      backhalf_err=myinerr[maxindex:*]
      
      ;figure out how many array points need to be added
      nelements_tobefilled=fix((backhalf_wav[0]-fronthalf_wav[N_ELEMENTS(fronthalf_wav)-1])/wpp)

      ;don't add the last array point if the gap in an integer number of wpp
      ;because this would be a duplicate point
      remainder=(backhalf_wav[0]-fronthalf_wav[N_ELEMENTS(fronthalf_wav)-1]) MOD wpp
      IF remainder EQ 0 THEN nelements_tobefilled = nelements_tobefilled - 1
      
      ;create arrays that are to go in the gap
      tobefilled_flux=dblarr(nelements_tobefilled)
      tobefilled_err=dblarr(nelements_tobefilled)
      tobefilled_wav=findgen(nelements_tobefilled)+1

      ;the error is 100 times the maximum error
      tobefilled_err=tobefilled_err+maxerr*100
      
      ;the wavelength in the gap goes up by wpp each time
      tobefilled_wav=tobefilled_wav*wpp + fronthalf_wav[N_ELEMENTS(fronthalf_wav)-1]
      
      ;interpolate to get the flux in the gap region
      LINTERP,myinwav,myinflux,tobefilled_wav,tobefilled_flux

      ;patch arrays together again
      outwav=[fronthalf_wav,tobefilled_wav,backhalf_wav]
      outflux=[fronthalf_flux,tobefilled_flux,backhalf_flux]
      outerr=[fronthalf_err,tobefilled_err,backhalf_err]

      ;prepare for second iteration
      myinwav=outwav
      myinflux=outflux
      myinerr=outerr
   
   ENDIF ELSE BEGIN
      ;if there are no gaps: output arrays = input arrays
      outwav=myinwav
      outflux=myinflux
      outerr=myinerr
   ENDELSE
ENDFOR

END
