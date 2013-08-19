PRO gregatm
READCOL,'spect.atm_abscor.txt',wav,trans,format=('d,d')
unlogtrans=10^(-4*trans)
OPENW,1,'savefiles/no77.weight'
FOR i=0,N_ELEMENTS(wav)-1 DO PRINTF,1,wav[i],unlogtrans[i]
CLOSE,1
END
