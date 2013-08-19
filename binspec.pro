function binspec,inlam,influx,startlam,endlam,dlam,outlam
; this routine is now obsolete -- use binspec_weighted
IF (dlam eq 0) THEN BEGIN
   wh=where((inlam ge startlam) and (inlam le endlam))
   outlam=inlam[wh]
   return,influx[wh]
ENDIF ELSE BEGIN
    
   ;determine total number of points
   nlam=(endlam-startlam)/dlam+1
   ;create output lambda array 
   outlam=findgen(nlam)*dlam+startlam
   answer=fltarr(nlam)
    
   ;created a sorted, unique lambda array
   ;including all points in input and output lambda arrays
   interplam=[inlam,outlam]
   interplam=interplam(sort(interplam))
   interplam=interplam(uniq(interplam))
   
   ;interpolate flux at points interplam
   interpflux=interpol(influx,inlam,interplam)
   
   for i=0l,nlam-2 do BEGIN
      ;figure out where original points are, indicies assigned to w
      w=where(interplam ge outlam[i] and interplam le outlam[i+1])
      ;integrate using integ from astrolib (but only works if npoints >=3
      if n_elements(w) eq 2 then answer[i]=0.5*(total(interpflux[w])*dlam) else $
        answer[i]=integ(interplam[w],interpflux[w],/val)
   endfor
   
   answer[nlam-1] = answer[nlam-2]
   return,answer/dlam
ENDELSE
END

