FUNCTION zerostrip,structwav,structflux,arraywav,arrayflux
;; function to take wavelength and flux from structure member, 
;; strip off the zeros, and return the answer in arrays

index=WHERE(structwav gt 0,count)
IF count NE 0 THEN BEGIN
    arraywav = structwav[index]
    arrayflux = structflux[index]
ENDIF
END
