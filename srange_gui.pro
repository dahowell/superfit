FUNCTION srange_gui,tempsavfile,w1,w2,z
count=0
restore,tempsavfile
startwave=dblarr(N_ELEMENTS(snt))
endwave=dblarr(N_ELEMENTS(snt))
FOR I=0,N_ELEMENTS(snt)-1 DO BEGIN
    nonzeroindex=WHERE(snt(I).w ne 0,countnonzeroindex)
    startwave(I)=snt(I).w[nonzeroindex(0)]*(1.0+z)
    endwave(I)=snt(I).w[nonzeroindex(countnonzeroindex-1)]*(1.0+z)
ENDFOR
PLOT,[0],[0],XRANGE=[1000*(1.0+z),11000*(1.0+z)],YRANGE=[260,-10],/NODATA,$
     color=colordex('black')
FOR I=1,N_ELEMENTS(snt)-1 DO BEGIN
    IF ((startwave(I) le w1) AND (endwave(I) ge w2)) THEN BEGIN
        count=count+1
        OPLOT,[startwave(I),endwave(I)],[I,I],color=colordex('green') 
    ENDIF ELSE OPLOT,[startwave(I),endwave(I)],[I,I],color=colordex('red')
ENDFOR
IF N_ELEMENTS(w1) ne 0 THEN OPLOT,[w1,w1],[0,N_ELEMENTS(snt)],color=colordex('blue')
IF N_ELEMENTS(w2) ne 0 THEN OPLOT,[w2,w2],[0,N_ELEMENTS(snt)],color=colordex('blue')
END
