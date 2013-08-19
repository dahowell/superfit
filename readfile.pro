PRO readfile,filename,wav,flux,splitpos,sigma=sigma,threecolflag=threecolflag

splitpos=STRPOS(filename,'.fits',/REVERSE_SEARCH)
IF (splitpos NE -1) THEN fitstoascii,filename,wav,flux  $
ELSE BEGIN
   splitpos=STRPOS(filename,'.dat',/REVERSE_SEARCH)
   IF (splitpos eq -1) THEN $
     splitpos=STRPOS(filename,'.asc',/REVERSE_SEARCH)
   IF (splitpos eq -1) THEN $
     splitpos=STRPOS(filename,'.txt',/REVERSE_SEARCH)
   
   IF (N_ELEMENTS(threecolflag) EQ 0) THEN BEGIN
      READCOL, filename,  wav,  flux, FORMAT='d,d',/SILENT
;      PRINT,'twocol'
   ENDIF ELSE BEGIN
      READCOL, filename,  wav,  flux, sigma, FORMAT='d,d,d',/SILENT 
;      print,'threecol'
   ENDELSE
ENDELSE
   
END
