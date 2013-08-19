FUNCTION binspec_weighted,inlam,influx,startlam,endlam,dlam,outlam,insigwav,insigma,outsigma
; function that rebins input spectrum and sigma spectrum
; performs a weighted rebinning, weighted by sigma
; in the middle of changing how the middle wavelength is assigned
IF (dlam eq 0) THEN BEGIN
   wh=where((inlam ge startlam) and (inlam le endlam))
   outlam=inlam[wh]
   return,influx[wh]
ENDIF ELSE BEGIN
    
   IF N_ELEMENTS(insigma) EQ 0 THEN BEGIN
      insigma=dblarr(N_ELEMENTS(inlam))
      insigma=insigma+1.0 ;set insigma to 1
      insigwav=inlam
      ;PRINT,'Sigma array not present, setting equal to unity.'
   ENDIF

   ;determine total number of points
   nlam=(endlam-startlam)/dlam+1
   ;create output lambda array 
   outlam=findgen(nlam)*dlam+startlam+dlam/2.0
   answer=dblarr(nlam)
   outsigma=dblarr(nlam)
    
   ;created a sorted, unique lambda array
   ;including all points in input and output lambda arrays
   interplam=[inlam,outlam]
   interplam=interplam(sort(interplam))
   interplam=interplam(uniq(interplam))
   
   ;interpolate flux at points interplam
   interpflux=interpol(influx,inlam,interplam)

   ;interpolate sigma at points interplam
   interpsigma=interpol(insigma,insigwav,interplam)
   
   FOR i=0l,nlam-1 DO BEGIN
      ;figure out where original points are, indicies assigned to w
      w=where(interplam GE outlam[i]-dlam/2.0 AND interplam LE outlam[i]+dlam/2.0)
      ;calculate weighted mean based on the sigma
      answer[i]=weighted_mean(interpflux[w],interpsigma[w])
      outsigma[i]=mean(interpsigma[w])
   ENDFOR
   
   RETURN,answer
ENDELSE
END

