function minfuncred,X

COMMON togaw
res=dblarr(1)

FOR I=0,N_ELEMENTS(W)-1 DO $
  res=res+W[I]*(O[I]-X[1]*T[I]*10^(X[0]*Alaw[I])-X[2]*G[I])^2

RETURN,res

END  







