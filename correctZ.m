clc;
clear all;
close all;

c=dlmread('/home/sagi/idl/superfit/sne/Others/sn2007bi.p54.dat');
x2=c(:,1);
y2=c(:,2);
plot(x2,y2)
%a=[x2/1.123 y2];
%dlmwrite('/home/sagi/idl/superfit/sne/Others/ptf10nmn.p7.dat',a,'delimiter','\t','newline','pc');