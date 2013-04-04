function [h,g,a] = wfilt_dden(N)
%WFILT_DDEN  Double-DENsity DWT filters (tight frame)
%   Usage: [h,g,a] = wfilt_dden(N);
%
%   `[h,g,a]=wfilt_dden(N)` computes oversampled dyadic double-density DWT
%   filters. The redundancy is equal to 2.
%
%   References: selesnick2001double
%
%   Examples:
%   ---------
%
%   Frequency responses of the analysis filters::: 
%
%     w = fwtinit({'dden',2});
%     wtfftfreqz(w.h);
%

a= [2;2;2];
switch(N)
    case 1
% from the software package filters1.m
harr = [
  0.14301535070442  -0.01850334430500  -0.04603639605741
  0.51743439976158  -0.06694572860103  -0.16656124565526
  0.63958409200212  -0.07389654873135   0.00312998080994
  0.24429938448107   0.00042268944277   0.67756935957555
 -0.07549266151999   0.58114390323763  -0.46810169867282
 -0.05462700305610  -0.42222097104302   0
];

    case 2
% from the software package filters2.m
harr = [
  0.00069616789827  -0.00014203017443   0.00014203017443
 -0.02692519074183   0.00549320005590  -0.00549320005590
 -0.04145457368920   0.01098019299363  -0.00927404236573
  0.19056483888763  -0.13644909765612   0.07046152309968
  0.58422553883167  -0.21696226276259   0.13542356651691
  0.58422553883167   0.33707999754362  -0.64578354990472
  0.19056483888763   0.33707999754362   0.64578354990472
 -0.04145457368920  -0.21696226276259  -0.13542356651691
 -0.02692519074183  -0.13644909765612  -0.07046152309968
  0.00069616789827   0.01098019299363   0.00927404236573
  0                  0.00549320005590   0.00549320005590
  0                 -0.00014203017443  -0.00014203017443
];

    case 3
% from the paper Table 2.2.
harr = [
  0.14301535070442  -0.08558263399002  -0.43390145071794
  0.51743439976158  -0.30964087862262   0.73950431733582
  0.63958409200212   0.56730336474330  -0.17730428251781
  0.24429938448107   0.04536039941690  -0.12829858410007
 -0.07549266151999  -0.12615420862311   0
 -0.05462700305610  -0.09128604292445   0
];

    case 4
% from the paper Table 2.3.
harr = [
  0.14301535070442  -0.04961575871056  -0.06973280238342
  0.51743439976158  -0.17951150139240  -0.25229564915399
  0.63958409200212  -0.02465426871823   0.71378970545825
  0.24429938448107   0.62884602337929  -0.39176125392083
 -0.07549266151999  -0.21760444148150   0
 -0.05462700305610  -0.15746005307660   0
];

    case 5
% from the paper Table 2.4.
harr = [
  0.14301535070442  -0.01850334430500  -0.04603639605741
  0.51743439976158  -0.06694572860103  -0.16656124565526
  0.63958409200212  -0.07389654873135   0.00312998080994
  0.24429938448107   0.00042268944277   0.67756935957555
 -0.07549266151999   0.58114390323763  -0.46810169867282
 -0.05462700305610  -0.42222097104302   0
];

    case 6
% from the paper Table 2.5.
harr = [
                 0                  0                  0
  0.05857000614054  -0.01533062192062   0.00887131217814
  0.30400518363062  -0.07957295618112  -0.33001182554443
  0.60500290681752  -0.10085811812745   0.74577631077164
  0.52582892852883   0.52906821581280  -0.38690622229177
  0.09438203761968  -0.15144941570477  -0.14689062498210
 -0.14096408166391  -0.23774566907201   0.06822592840635
 -0.06179010337508  -0.05558739119206   0.04093512146217
  0.01823675069101   0.06967275075248   0
  0.01094193398389   0.04180320563276   0
];

    case 7
% from the paper Table 2.6.
harr = [
                 0                  0                  0
  0.05857000614054   0.00194831075352   0.00699621691962
  0.30400518363062   0.01011262602523   0.03631357326930
  0.60500290681752   0.02176698144741   0.04759817780411
  0.52582892852883   0.02601306210369  -0.06523665620369
  0.09438203761968  -0.01747727200822  -0.22001495718527
 -0.14096408166391  -0.18498449534896  -0.11614112361411
 -0.06179010337508  -0.19373607227976   0.64842789652539
  0.01823675069101   0.66529265123158  -0.33794312751535
  0.01094193398389  -0.32893579192449   0
];
    otherwise
        error('%s: No such Double Density DWT filter',upper(mfilename));
end;

h=mat2cell(harr.',[1,1,1],length(harr));
if(nargout>1)
    garr = harr(end:-1:1, :);
    g=mat2cell(garr.',[1,1,1],length(harr));
end