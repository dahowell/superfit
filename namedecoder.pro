FUNCTION namedecoder,tempname
pos=STREGEX(tempname,'\.dat')
IF pos GT 0 THEN tempname=STRMID(tempname,0,pos) 
yearpos=STREGEX(tempname,'([0-9]+)',LENGTH=yrlen)
sn=STRMID(tempname,0,yearpos)
year=STRMID(tempname,yearpos,yrlen)
remainder=STRMID(tempname,yearpos+yrlen)
sn=STRUPCASE(sn)
b=strsplit(remainder,'.',/EXTRACT)
letters=b[0]
date=b[1]
IF STRLEN(letters) EQ 1 THEN letters=STRUPCASE(letters)
datenumpos=STREGEX(date,'([0-9]+)',LENGTH=datenumlen)
datenum=STRMID(date,datenumpos,datenumlen)
prefix=STRMID(date,0,datenumpos)
firstdatechar=STRMID(datenum,0,1)
IF firstdatechar EQ '0' THEN datenum=STRMID(datenum,1,STRLEN(datenum-1))
IF prefix EQ 'p' THEN prefix = '+'
IF prefix EQ 'm' THEN prefix = '-'
IF prefix EQ 'u' THEN BEGIN
   IF datenum EQ '0' THEN BEGIN
      prefix = 'ep1'
      datenum= ''
   ENDIF ELSE prefix = 'ep1+'   
ENDIF
IF date EQ 'max' THEN BEGIN
   prefix = 'm' 
   datenum = 'ax'
ENDIF
tempname=sn+" "+year+letters+" "+prefix+datenum
RETURN,tempname
END
