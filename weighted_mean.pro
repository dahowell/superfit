FUNCTION weighted_mean,vector,sigma
wmean=total(vector/sigma^2)/total(1./sigma^2)
return,wmean
END
