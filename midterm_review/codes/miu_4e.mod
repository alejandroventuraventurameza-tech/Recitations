// miu_4e.dyn
// Dynare program for MIU model of Chapter 2
// Monetary Theory and Policy, 4th ed., by Carl E. Walsh
// The MIT Press. 2015

var Z U Y C K INV N R M I MUC PI;

varexo EPZ EPU;

parameters A B ALPHA BETA ETA DELTA GAMMA OMEGA1 OMEGA2 SIGMA_Z SIGMA_M SIGMA_V;
parameters RHOZ RHOU THETA PHI UPSILON phi NSS YK CK NKSS KSS CSS RSS ISS MSS XSS;
ALPHA = 0.36;
DELTA = 0.019;
BETA = 0.989;
ETA = 1;
THETA = 1.0138;

% THETA implies quarterly growth rate of money equal to 1.38%.
% money_demand_percapita.rpf
% GRLFM1 is growth rate (at quarterly rate) of M1.
%Statistics on Series GRLFM1
%Quarterly Data From 1985:01 To 2014:04
%Observations                   120
%Sample Mean               1.384221      Variance                   2.590167
%Standard Error            1.609400      SE of Sample Mean          0.146917

PHI = 2;
B = 9; 
% B = 9 is implied by Ireland (2009) and (M1/P)/C = 0.7811.

NSS = 1/3;

// Implied parameters
YK = (1/ALPHA)*((1/BETA) - 1 + DELTA);
CK = YK - DELTA;
NKSS = (YK)^(1/(1-ALPHA));
KSS = NSS/NKSS;
CSS = CK*KSS;
RSS = 1/BETA;
ISS = (RSS*THETA - 1);
UPSILON = ISS/(1+ISS);

// A chosen to target M1/C = 0.7811 for quarterly rates
// See MTP_Ch2_4e.m
// M1 divided by C at quarter rates: mean 1985:1-2014:1 equals 0.7811
A  = 1/(1 + UPSILON*(0.7811^B));
MSS = CSS*((A*UPSILON)/(1-A))^(-1/B);
XSS = A*(CSS^(1-B)) + (1-A)*(MSS^(1-B));
GAMMA = A*(CSS^(1-B))/XSS; 
OMEGA1 = (B - PHI)*GAMMA - B;
OMEGA2 = (B - PHI)*(1-GAMMA);

// Parameters for exogenous processes
SIGMA_Z = 0.34;
RHOZ    = 0.95;
RHOU    = 0.69;
phi     = 0; 
SIGMA_M = 1.17; % standard deviation of money growth rate. Units: Percent
%Linear Regression - Estimation by Least Squares
%Dependent Variable GRLFM1
%Quarterly Data From 1985:01 To 2014:04
%Usable Observations                       120
%Degrees of Freedom                        118
%Centered R^2                        0.4752601
%R-Bar^2                             0.4708132
%Uncentered R^2                      0.6994553
%Mean of Dependent Variable       1.3842206067
%Std Error of Dependent Variable  1.6093997316
%Standard Error of Estimate       1.1707614837
%Sum of Squared Residuals         161.74052929
%Regression F(1,118)                  106.8733
%Significance Level of F             0.0000000
%Log Likelihood                      -188.1827
%Durbin-Watson Statistic                2.1460
%
%    Variable                        Coeff      Std Error      T-Stat      Signif
%************************************************************************************
%1.  Constant                     0.4329143027 0.1410325118      3.06961  0.00266006
%2.  GRLFM1{1}                    0.6893456888 0.0666810433     10.33796  0.00000000

% Innovation variance of money growth shock set so that s.d. of money
% growth matches SIGMA_M.
SIGMA_V = ((1-RHOU^2)*(SIGMA_M)^2 - ((phi^2)/(1-RHOZ^2))*(SIGMA_Z^2))^.5;

model(linear);
    Z = RHOZ*Z(-1) + EPZ;
    U = RHOU*U(-1)+ phi*Z(-1) + EPU;
    Y = ALPHA*K(-1) + (1-ALPHA)*N + Z;
    YK*Y = CK*C + DELTA*INV;
    K = (1 - DELTA)*K(-1) + DELTA*INV;
    (1 + (ETA*NSS/(1-NSS)))*N = Y + MUC;
    R = ALPHA*YK*(Y(+1) - K);
    MUC = OMEGA1*C + OMEGA2*M;
    MUC = R + MUC(+1);
    M = C - (1/B)*((1-ISS)/ISS)*I;
    M = M(-1) + U - PI;  
    I = R + PI(+1);     
end;

steady;
check;

shocks;
var EPZ;
stderr SIGMA_Z;
var EPU;
stderr SIGMA_V;
end;

/////////////////////////////////////////
// Computing Theoretical Moments and IRF's
////////////////////////////////////////
// Baseline parameters
stoch_simul(order=1,ar=1,irf=60,graph,print);
OOPT.MODELS.MIU_1 =   oo_;
save OOPT_MIU_1;