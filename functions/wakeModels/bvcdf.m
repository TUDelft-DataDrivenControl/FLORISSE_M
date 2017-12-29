function series0 = bvcdf(r, lab, u, nMax)
% function [series0] = bvcdf(r, lab, u, nMax)
%BVCDF computes the bivariate cumulative distribution function over a
%circular region
%   The document:
%   TECHNICAL REPORT ECOM-2625
%   TABLES OF OFFSET CIRCLE PROBABILITIES FOR A
%   NORMAL BIVARIATE ELLIPTICAL DISTRIBUTION
%   explains how to compute the integral of a bivariate normal distribution
%   by expanding the integral to a power series. The exact solution uses
%   nMax = infty but the series converges so a few terms are enough to
%   accurately approximate the integral
    
    t = .5*u^2;
    a = 4*r*r*t;
    b = r*r-1;
    s = .5*lab*lab/(r*r);
    
    series0 = 0;
    for n=0:nMax
        series1 = 0;
        series2 = 0;
        for kj = 0:n
            series1=series1+(s^kj)/factorial(kj);
            series2=series2+((-1)^kj)*((b/a)^kj)/(factorial(kj)*factorial(2*(n-kj)));
        end
        series0=series0+(factorial(2*n)/(2^(2*n)*factorial(n)))*...
        (1-exp(-s)*series1)*(a^n)*series2;
    end
    series0 = r*exp(-t)*series0;
end

