FUNCTION zrange_gui,tempsavfile,w1,w2,zl,zu,zi
zindex=0
restore,tempsavfile
startwave=dblarr(N_ELEMENTS(snt))
endwave=dblarr(N_ELEMENTS(snt))
FOR I=0,N_ELEMENTS(snt)-1 DO BEGIN
    nonzeroindex=WHERE(snt(I).w ne 0,countnonzeroindex)
    startwave(I)=snt(I).w[nonzeroindex(0)]
    endwave(I)=snt(I).w[nonzeroindex(countnonzeroindex-1)]
ENDFOR

upperz=ROUND(zu/zi)
lowerz=ROUND(zl/zi)
zelements=upperz-lowerz+1
count=intarr(zelements)
zarray=fltarr(zelements)

;;PLOT,[0],[0],XRANGE=[zl,zu],YRANGE=[0,160],/NODATA

;; kludge to get it working b/c without it won't work for zl=0.4,zu=0.5,zi=0.1
zu=zu+0.00001
FOR Z=zl,zu,zi DO BEGIN
    FOR I=1,N_ELEMENTS(snt)-1 DO BEGIN
        IF ((startwave(I)*(1+Z) le w1) AND (endwave(I)*(I+Z) ge w2)) THEN BEGIN
            count(zindex)=count(zindex)+1
        ENDIF
    ENDFOR
    zarray(zindex)=Z
    zindex=zindex+1
ENDFOR

PLOT,zarray,count,color=colordex('black')


END
