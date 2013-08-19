PRO fitstoascii,fitsfile,wav,flux
; accepts a fits file as input -- outputs wavelength and flux
flux=READFITS(fitsfile,header)
wav=findgen(N_ELEMENTS(flux))

FOR i=0,N_ELEMENTS(header)-1 DO BEGIN
   poseq=STREGEX(header[i],'=')+1
   posslash=STREGEX(header[i],'/')
   IF posslash LT 0 THEN posslash=100
   len=posslash-poseq

   poscrval=STREGEX(header[i],'CRVAL1')
   IF (poscrval GE 0) AND (poscrval LE poseq) THEN BEGIN
      crval1=double(STRMID(header[i],poseq,len))
      ;PRINT,'CRVAL1:',crval1
   ENDIF

   poscdelt=STREGEX(header[i],'CDELT1')
   IF (poscdelt GE 0) AND (poscdelt LE poseq) THEN BEGIN
      cdelt1=double(STRMID(header[i],poseq,len))
   ;PRINT,'CDELT1:',cdelt1
   ENDIF ELSE BEGIN
      ; special case for some Phillips spectra, like sn1999ek_991024.fits
      poscdelt=STREGEX(header[i],'CD1_1')
      IF (poscdelt GE 0) AND (poscdelt LE poseq) THEN $
        cdelt1=double(STRMID(header[i],poseq,len))
   ENDELSE

   poscrpix1=STREGEX(header[i],'CRPIX1')
   IF (poscrpix1 GE 0) AND (poscrpix1 LE poseq) THEN BEGIN
      crpix1=fix(STRMID(header[i],poseq,len))
   ENDIF 
ENDFOR

IF N_ELEMENTS(crpix1) EQ 0 THEN  BEGIN
   PRINT,'Could not determine CRPIX1 from header, setting CRPIX1=1'
   crpix1=1
ENDIF

; crpix1 is a pixel value, so to convert to an idl 
; index, i=crpix1-1 

;crval1 is the wavelength value at reference pixel crpix1
;for gemini crpix1=1, but not for VLT

crval_at_first_pixel=crval1-cdelt1*(crpix1-1)
wav=cdelt1*wav+crval_at_first_pixel


; get rid of 0's at end of spectra in some spectra
w=where(flux NE 0)
wav=wav[w]
flux=flux[w]

openw,1,'fitstoasciitest.dat'
FOR j=0,N_ELEMENTS(wav)-1 DO PRINTF,1,wav[j],flux[j]
CLOSE,1
END
