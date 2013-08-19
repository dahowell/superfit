PRO galsetup

; read in all the templates for fitting program

; directory containing ascii files for templates
gdir = 'gal/'

readcol,  'savefiles/gal.list', galfiles,  format='A'

tgal = {gal, day:0,  file:' ', w:fltarr(10000),  f:fltarr(10000),  npoint:0}
gal = replicate(tgal, N_ELEMENTS(galfiles))

FOR i = 0, N_elements(galfiles)-1 DO BEGIN

    readcol,  gdir+GALFILES(I), Wt, Ft
    gal(i).file = galfiles(i)
    gal(i).w  =  wt 
    gal(i).f =  ft
    gal(i).npoint = n_elements(wt)

ENDFOR

; save them in an IDL save file
; print out what's there

wfile = where(gal.file ne ' ')

FOR i=0, n_elements(wfile)-1 DO BEGIN

print, i, gal(i).file,  format='(i4, 3x, a)'

ENDFOR

save,gal,filename='savefiles/galtemp.idlsave'

; directory containing ascii files for templates

;readcol,  'savefiles/qso.list', qsofiles,  format='A'
 
;tqso = {qso, day:0,  file:' ', w:fltarr(10000),  f:fltarr(10000),  npoint:0}
;qso = replicate(tqso, N_ELEMENTS(qsofiles))
 
;FOR i = 0, N_elements(qsofiles)-1 DO BEGIN
 
;    readcol,  QSOFILES(I), Wt, Ft
;    qso(i).file = qsofiles(i)
;    qso(i).w  =  wt 
;    qso(i).f =  ft
;    qso(i).npoint = n_elements(wt)
 
;ENDFOR
 
;; save them in an IDL save file
;; print out what's there
 
;wfile = where(qso.file ne ' ')
 
;FOR i=0, n_elements(wfile)-1 DO BEGIN
 
;print, i, qso(i).file,  format='(i4, 3x, a)'
 
;ENDFOR
 
;save,qso,filename='savefiles/qsotemp.idlsave'


;;;;;;;;;;; filters ;;;;;;;;;;;;;;;;;;
; directory containing ascii files for templates
fdir = 'filters/'

readcol,  'savefiles/filters.list', filtfiles,  format='A'

tfilt = {filt, day:0,  file:' ', w:fltarr(10000),  f:fltarr(10000),  npoint:0}
filt = replicate(tfilt, N_ELEMENTS(filtfiles))

FOR i = 0, N_elements(filtfiles)-1 DO BEGIN

    readcol,  fdir+FILTFILES(I), Wt, Ft
    filt(i).file = filtfiles(i)
    filt(i).w  =  wt 
    filt(i).f =  ft
    filt(i).npoint = n_elements(wt)

ENDFOR

; save them in an IDL save file
; print out what's there

wfile = where(filt.file ne ' ')

FOR i=0, n_elements(wfile)-1 DO BEGIN

print, i, filt(i).file,  format='(i4, 3x, a)'

ENDFOR

save,filt,filename='savefiles/filters.idlsave'

END






