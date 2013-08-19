FUNCTION weighted_stddev,vector,sigma
;function to calculate the weighted standard deviation
;input observation,sigma
wavg=weighted_mean(vector,sigma)
n=N_ELEMENTS(vector)
weight=1.0/sigma^2
numerator=total(weight*(vector-wavg)^2)
denominator=(n-1)*total(weight)/n
wstddev=sqrt(numerator/denominator)
RETURN,wstddev
END
