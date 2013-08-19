PRO sntempsetup
; read in all the templates for fitting program

;; requires a file  named 'savefiles/tempset.list' which lists the
;; root name for each set of templates

; list of template sets
tempsetlist = 'savefiles/tempset.list'
; directory containing ascii files for templates
readcol, tempsetlist, temprootname, format='A'

FOR J = 0,N_ELEMENTS(temprootname)-1 DO BEGIN
    readcol, temprootname[J]+'.list', sntfiles,  format='A'
    tsnt = {snt, day:0,  file:' ', w:fltarr(10000),  f:fltarr(10000),  npoint:0}
    snt = replicate(tsnt, N_ELEMENTS(sntfiles))
    
    FOR i = 0, N_elements(sntfiles)-1 DO BEGIN
        
        readcol,  SNTFILES(I), Wt, Ft
        snt(i).file = sntfiles(i)
        snt(i).w  =  wt 
        snt(i).f =  ft
        snt(i).npoint = n_elements(wt)
        
    ENDFOR
    
; save them in an IDL save file
; print out what's there
    
    wfile = where(snt.file ne ' ')
    
    FOR i=0, n_elements(wfile)-1 DO BEGIN
        
        print, i, snt(i).file,  format='(i4, 3x, a)'
        
    ENDFOR    
    save,snt,filename=temprootname[J]+'.idlsave'
    
ENDFOR

END












