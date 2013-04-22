function [s,TA]=framemulappr(Fa,Fs,T)
%FRAMEMULAPPR  Best Approximation of a matrix by a frame multiplier
%   Usage: s=framemulappr(Fa,Fs,T);
%         [s,TA]=framemulappr(Fa,Fs,T);
%
%   Input parameters:
%          Fa   : Analysis frame
%          Fs   : Synthesis frame
%          T    : The operator represented as a matrix
%
%   Output parameters: 
%          s    : Symbol of best approximation
%          TA   : The best approximation of the matrix T
%
%   `s=framemulappr(Fa,Fs,T)` computes the symbol *s* of the frame
%   multiplier that best approximates the matrix *T* in the Frobenious norm
%   of the matrix (the Hilbert-Schmidt norm of the operator). The frame
%   multiplier uses *Fa* for analysis and *Fs* for synthesis.
%
%   Examples:::
%   
%     T = eye(2,2);
%     D = [0 1/sqrt(2) -1/sqrt(2); 1 -1/sqrt(2) -1/sqrt(2)];
%     F = frame('gen',D);
%     [coeff,TA] = framemulappr(F,F,T)
%
%

%   Literature : [1] P. Balazs; Irregular And Regular Gabor frame multipliers 
%                  with application to psychoacoustical masking 
%                  (Ph.D. thesis 2005)
%              [2] P. Balazs; Hilbert- Schmidt Operators and Frames -
%                  Classification, Best Approximation by Multipliers and 
%                  Algorithms; 
%                  International Journal of Wavelets, Multiresolution and
%                  Information Processing}, to appear, 
%                  http://arxiv.org/abs/math.FA/0611634

% Author: Peter Balazs and Peter L. Søndergaard

if nargin < 3
    error('%s: Too few input parameters.',upper(mfilename));
end;

[N M] = size(T);

Mfix=M;

% Bootstrap the code
D=framematrix(Fa,Mfix);
Ds=framematrix(Fs,Mfix);

[Nd Kd] = size(D);

% TODO: Check for for correct framelengths

% TODO: Check this error('The frames must have the same number of
% elements.');

% TODO: Possible optimization for Fa=Fs

% TODO: Express the pinv as an iterative algorithm

% Compute the lower symbol.
% The more elegant code
% 
% is slower, O(k(n^2+n^2)))
% see [Xxl]

if 1
  % Original expression
  %lowsym = diag(D'*T*D);
  
  % New expression
  lowsym = conj(diag(frana(Fa,frana(Fa,T)')));
else
    lowsym = zeros(Kd,1); %lower symbol
    for ii=1:Kd
        lowsym(ii) = D(:,ii)'*(T*D(:,ii));
    end;
end;

Gram = (Ds'*Ds).*((D'*D).');

% upper symbol:
s = Gram\lowsym;
  
% synthesis
if nargout>1
    TA = zeros(N,M);
    for ii = 1:Kd
        P = Ds(:,ii)*D(:,ii)';
        TA = TA + s(ii)*P;
    end;
end;




