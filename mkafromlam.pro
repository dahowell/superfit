function mkafromlam,lambdain,Rv
;; program to calculate an array of A's from an input wavelength array

lambda=dblarr(N_ELEMENTS(lambdain))
invlammicro=DBLARR(N_ELEMENTS(lambdain))
redreturn=DBLARR(N_ELEMENTS(lambdain))

FOR i=0,N_ELEMENTS(lambda)-1 DO BEGIN
    ;convert to microns, then invert to get invlammicro
    lambda[i]=lambdain[i]/10000.0
    invlammicro[i]=double(double(1.0)/lambda[i])
    IF (invlammicro[i] ge 0.3 and invlammicro[i] le 1.1) THEN BEGIN
        a=0.574 * invlammicro[i] ^ 1.61
        b=-0.527 * invlammicro[i] ^ 1.61
        redreturn[i] = a + (b/Rv)
    ENDIF

    IF (invlammicro[i] gt 1.1 and invlammicro[i] le 3.3) THEN BEGIN
        y=invlammicro[i]-1.82
        a = 1.0 + 0.17699 * y - 0.50447 * y^2 - 0.02427 * y^3 + 0.72085 * y^4 + 0.01979 * y^5 - 0.77530 * y^6 +0.32999 * y^7
        b=1.41338 * y + 2.28305 * y^2 + 1.07233 * y^3 - 5.38434 * y^4 - 0.62251 * y^5 + 5.30260 * y^6 - 2.09002 * y^7
        redreturn[i] = a + (b/Rv)
    ENDIF

    IF (invlammicro[i] gt 3.3 and invlammicro[i] lt 5.9) THEN BEGIN
        a = 1.752 - 0.316 * invlammicro[i] - 0.104 / ((invlammicro[i]-4.67)^2 +0.341)
        b = -3.090 + 1.825 * invlammicro[i] + 1.206 / ((invlammicro[i] - 4.62)^2 + 0.263)
        redreturn[i] = a + (b/Rv)
    ENDIF

    IF (invlammicro[i] ge 5.9 and invlammicro[i] le 8.0) THEN BEGIN
        Fa = -0.04473 * (invlammicro[i] - 5.9)^2 - 0.009779 * (invlammicro[i] - 5.9)^3
        Fb = 0.2130 * (invlammicro[i] - 5.9)^2 + 0.1207 * (invlammicro[i] - 5.9)^3
        a = 1.752 - 0.316 * invlammicro[i] - 0.104 / ((invlammicro[i]-4.67)^2 +0.341) + Fa
        b = -3.090 + 1.825 * invlammicro[i] + 1.206 / ((invlammicro[i] - 4.62)^2 + 0.263) + Fb
        redreturn[i] = a + (b/Rv)
    ENDIF

    IF (invlammicro[i] gt 8.0 and invlammicro[i] le 10.0) THEN BEGIN
        a = -1.073 - 0.628*(invlammicro[i] - 8.0) + 0.137*(invlammicro[i] - 8.0)^2 - 0.070 * (invlammicro[i] - 8.0)^3
        b = 13.670 + 4.257*(invlammicro[i] - 8.0) - 0.420 * (invlammicro[i]-8.0)^2 + 0.374 * (invlammicro[i] - 8.0)^3
        redreturn[i] = a + (b/Rv)
    ENDIF
ENDFOR

RETURN,redreturn
END
