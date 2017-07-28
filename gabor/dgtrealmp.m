function [ c, fhat, info] = dgtrealmp( f, a, M, varargin)
%DGTREALMP Matching Pursuit in (multiscale) Gabor Dictionary
%   Detailed explanation goes here

definput.keyvals.tol=1e-4;
definput.keyvals.maxit=[];
definput.keyvals.relresstep=[];
definput.keyvals.printstep=[];
definput.flags.printerr = {'noerr','printerr','printdb'};
definput.flags.apprerrprec = {'errappr','errexact'};
definput.flags.verbosity = {'quiet','verbose'};
definput.flags.verbosity = {'real','complex'};
definput.keyvals.g1 = [];
definput.keyvals.g2 = [];
definput.keyvals.g3 = [];
definput.keyvals.g4 = [];
definput.keyvals.g5 = [];
definput.keyvals.g6 = [];
definput.keyvals.g7 = [];
definput.keyvals.g8 = [];
definput.keyvals.g9 = [];
definput.keyvals.g10 = [];
definput.flags.method={'mp','cyclicmp','complmp','cycliccomplmp','localomp','compllocalomp'};
definput.keyvals.cyclicmpcycles = 1;
definput.keyvals.atsellim = [];
definput.keyvals.atoms = [];
definput.keyvals.mpdebiasstep = [];
definput.keyvals.relrestol = [];
definput.keyvals.relrestoldb = -40;
[flags,kv]=ltfatarghelper({'maxit','tol'},definput,varargin);

if isempty(kv.relrestol)
    kv.relrestol = 10^(kv.relrestoldb/20);
end

convmessages = {'Achieved desired number of atoms',...
                'Achieved desired approximation error',...
                'Not achieved desired number of atoms in maxit iterations',...
                'The limit of repeated selections of one atom reached',...
                'Appr. error stalled.',...
                'localomp: The condition number is out of bounds',...
                };

Ls = size(f,1);

% Default limit for the single atom selection 
if isempty(kv.atsellim)
    if flags.do_localomp
        kv.atsellim = 400;
    else
        kv.atsellim = 400;
    end
end

% Default number of selected atoms 10% of the signal dimensionality
if isempty(kv.atoms), kv.atoms = floor(0.1*L); end
% Maximum number of iterations
if isempty(kv.maxit), kv.maxit = kv.atoms*2; end

if isempty(kv.relresstep) || kv.relresstep > kv.maxit
    kv.relresstep = kv.maxit;
end


% Parse windows
maxwins = 10;
g = cell(maxwins,1);
for ii=1:maxwins, g{ii} = kv.(sprintf('g%i',ii)); end
g = g(~cellfun(@isempty,g));
if isempty(g), g{1} = 'gauss'; end

aarr = zeros(numel(g),1); aarr(:) = a;
Marr = zeros(numel(g),1); Marr(:) = M;

 Marr(2) = M/2;
 aarr(2) = a/2;
 Marr(3) = M/4;
 aarr(3) = a/4;
 Marr(4) = M/8;
 aarr(4) = a/8;
 Marr(5) = M/16;
 aarr(5) = a/16;
 Marr(6) = M/32;
 aarr(6) = a/32;

L = dgtlength(Ls,max(aarr),max(Marr));
f = postpad(f,L);


dgtparamsrows = cellfun(@(gEl,aEl,MEl) ...
    { normalize(gabwin(gEl,a,M,L),'2'), aEl, MEl, ...
     floor(MEl/2)+1,...%MEl,... 
     L./aEl},...
      g(:), num2cell(aarr), num2cell(Marr),'UniformOutput',0);

dgtparamsfields = {'g','a','M','M2','N'};
dp = cell2struct(vertcat(dgtparamsrows{:}),dgtparamsfields,2);

%[A,B] = gabframebounds(cell2mat(g),a,M,L);
A=1;B=1;

N = L/a;
M2 = floor(M/2) + 1;

kerns = cell(numel(g),numel(g));
kmids = cell(numel(g),numel(g));
masks = cell(numel(g),numel(g));

if flags.do_mp || flags.do_localomp || flags.do_cyclicmp

    
    
    for ii = 1:numel(dp)
        for jj = 1:numel(dp)
            [kerns{ii,jj}, kmids{ii,jj}, masks{ii,jj}] = ...
                projkernels(dp(ii).g, dp(jj).g, dp(ii).a, dp(jj).a,...
                            dp(ii).M, dp(jj).M, L, kv.tol);
        end
    end

cres = arrayfun(@(pEl) dgt(f,pEl.g,pEl.a,pEl.M), dp, 'UniformOutput',0);

elseif flags.do_complmp || flags.do_cycliccomplmp || flags.do_compllocalomp ...
    gd = gabdual(cell2mat(g),a,M,L);
    gd = num2cell(gd,1);
    atnorms = zeros(numel(g));

    for ii = 1:numel(g)
        for jj = 1:numel(g)
            [kerns{ii,jj}, kmids{ii,jj}, masks{ii,jj}, atnorms(ii,jj)] = ...
                projkernels(g{ii},gd{jj},a,M,L,kv.tol);

            kerns{ii,jj} = kerns{ii,jj}./atnorms(ii,jj);
        end
    end

   % cres = cell2mat(cellfun(@(gEl) dgt(f,gEl,a,M),gd(:)','UniformOutput',0));
   cres = cell2mat(cellfun(@(gEl,nEl) 1/nEl*dgt(f,gEl,a,M),gd(:)',num2cell(diag(atnorms))','UniformOutput',0));
end

s = cellfun(@abs, cres, 'UniformOutput',0);
c = cellfun(@(cEl) zeros(size(cEl)), cres, 'UniformOutput',0);

smax = max(cellfun(@(sEl,m2El) max(max(sEl(1:m2El,:))), s,{dp.M2}.'));
%smax = 20*log10(max(max(s(1:M2,:))));
clim = [smax-120,smax];

kernwidx = cellfun(@(kEl) fftshift(fftindex(size(kEl,2))),kerns,'UniformOutput',0);
kernhidx = cellfun(@(kEl) fftshift(fftindex(size(kEl,1))),kerns,'UniformOutput',0);
bigkernwidx = cellfun(@(kEl) fftshift(fftindex(min([2*size(kEl,2)+1,N]))),kerns,'UniformOutput',0);
bigkernhidx = cellfun(@(kEl) fftshift(fftindex(min([2*size(kEl,1)+1,M]))),kerns,'UniformOutput',0);
kernno = size(kerns{1,1},3);

norm_f = norm(f);
norm_f2 = norm(f)^2;
norm_c = [norm_f^2*B, norm_f^2*A];
relres = zeros(ceil(kv.maxit/kv.relresstep),1);
relres(1) = 1; 
relresexact = relres;
suppindcount = cellfun(@(cEl) zeros(size(cEl)), cres, 'UniformOutput',0);
suppind = cellfun(@(cEl) false(size(cEl)), cres ,'UniformOutput', 0);
%suppIdx = zeros(numel(cres),2);
suppNo = 0;

apprenenergy = 0;
exitcode = 0;

tic
[maxcols,maxcolspos] = ...
    cellfun(@(sEl,m2El) max(sEl(1:m2El,:)),s,{dp.M2}.',...
    'UniformOutput',0);

iter = 0;
atNo = 0;
if flags.do_mp
    %% MATCHING PURSUIT
    while atNo < kv.atoms && iter < kv.maxit
        %% 1) Selection
        %[valrow,mcell] = cellfun(@(mEl) max(mEl,[],1),maxcols,'UniformOutput',0);
        [val,n] = cellfun(@max,maxcols); [~,wIdx] = max(val); n = n(wIdx)-1;
        m = maxcolspos{wIdx}(n+1); m=m-1;
         
        iter = iter+1;
        if suppindcount{wIdx}(m+1,n+1) == 0 && m < dp(wIdx).M2, atNo = atNo + 1; end
        if suppindcount{wIdx}(m+1,n+1) >= kv.atsellim, exitcode = 3; break; end
        suppindcount{wIdx}(m+1,n+1) = suppindcount{wIdx}(m+1,n+1) + 1;
        
        % 1b) Selected coefficient
        cval = cres{wIdx}(m+1,n+1);
        
        %% 2) Residual update
        for secondwIdx = [wIdx,1:wIdx-1,wIdx+1:numel(dp)]
            Mrat = dp(wIdx).M/dp(secondwIdx).M;
            arat = dp(secondwIdx).a/dp(wIdx).a;

            %% 1) Time direction
            nsecond = round(n/arat);
            nsecondoff = n - nsecond*arat;
            kernno = size(kerns{wIdx,secondwIdx},3);
            
            if arat >= 1
                currkern = kerns{wIdx,secondwIdx}(:,:,1+mod(n,kernno));
            elseif arat < 1
                currkern = kerns{wIdx,secondwIdx}(:,:,1+mod(nsecond,kernno));
            end

            [kernh, kernw] = size(currkern);
            mmid = kmids{wIdx,secondwIdx}(1);
            nmid = kmids{wIdx,secondwIdx}(2);
            
            currkernhidx = kernhidx{wIdx,secondwIdx};
            currkernwidx = kernwidx{wIdx,secondwIdx};
   
            if arat > 1
                previdx = nmid - nsecondoff - arat:-arat:1;
                pastidx = nmid - nsecondoff:arat:kernw;
                subidx = [previdx(end:-1:1),pastidx];
                
                if numel( find( subidx > 0) ) == 0
                    continue;
                end
                
                currkern = currkern(:,subidx);
                currkernwidx = -numel(previdx):numel(pastidx)-1;
            end
            
            idxn = mod(nsecond + currkernwidx,dp(secondwIdx).N)+1;
            
            %% 2) Frequency direction
            
            %%% Positive frequency %%%
            msecond = round(m/Mrat);
            msecondoff = m - msecond*Mrat;
            
            currkerntmp = currkern;
            
            if Mrat > 1
                %currkern2 = zeros(size(currkern));
                previdx = mmid - msecondoff -Mrat:-Mrat:1;
                pastidx = mmid - msecondoff:Mrat:kernh;
                subidx = [previdx(end:-1:1),pastidx];
                
                if numel( find( subidx > 0) ) == 0
                    continue;
                end
                
                currkerntmp = currkern(subidx,:);
                currkernhidx = -numel(previdx):numel(pastidx)-1;
            end 

            idxm = mod(msecond + currkernhidx,dp(secondwIdx).M)+1;
  
            cresfulltmp = cres{secondwIdx}(idxm,idxn);
            cresfulltmp = cresfulltmp - cval*currkerntmp;
            cres{secondwIdx}(idxm,idxn) = cresfulltmp;
            s{secondwIdx}(idxm,idxn) = abs(cresfulltmp);
            
            if m > 0
                %%% Conjugated frequency bin %%%
                mconj = dp(wIdx).M - m;
                msecond = round(mconj/Mrat);
                msecondoff = mconj - msecond*Mrat;
                
                if secondwIdx==wIdx
                     % Get the conjugated coefficient (might have been changed by subtracting the first one)
                     cval2 = cres{secondwIdx}(msecond + 1,n+1);
                end
                
                if Mrat > 1
                    %currkern2 = zeros(size(currkern));
                    previdx = mmid - msecondoff -Mrat:-Mrat:1;
                    pastidx = mmid - msecondoff:Mrat:kernh;
                    subidx = [previdx(end:-1:1),pastidx];

                    if numel( find( subidx > 0) ) == 0
                        continue;
                    end

                    currkerntmp = currkern(subidx,:);
                    currkernhidx = -numel(previdx):numel(pastidx)-1;
                end 
            
                % Update the residual
                idxm = mod(msecond + currkernhidx,dp(secondwIdx).M)+1;

                cresfulltmp = cres{secondwIdx}(idxm,idxn);
                cresfulltmp = cresfulltmp - cval2*currkerntmp;
                cres{secondwIdx}(idxm,idxn) = cresfulltmp;
                s{secondwIdx}(idxm,idxn) = abs(cresfulltmp);               
            end    
           
            % Update max in updated cols
            [maxcolupd,maxcolposupd] = max(s{secondwIdx}(1:dp(secondwIdx).M2,idxn));
            maxcols{secondwIdx}(idxn) = maxcolupd;
            maxcolspos{secondwIdx}(idxn) = maxcolposupd;
        end
        
        %% 3) Coefficient update
        cvalold = c{wIdx}(m+1,n+1);
        % A single atom can be selected more than once
        c{wIdx}(m+1,n+1) = cvalold + cval;
 
         if mod(iter,kv.printstep) == 0
             plotiter(c,cres,a,M,clim,iter,kv,flags);
         end
      
        apprenenergy = apprenenergy + abs(cval)^2;
        if m>0
           apprenenergy = apprenenergy + abs(cval2)^2;
        end
        
        if mod(iter,kv.relresstep) == 0
            relresid = ceil(iter/kv.relresstep) + 1;
           
            %fprintf('Atoms: %d\n',atNo);
            if flags.do_errappr
                relres(relresid) = sqrt((norm_f2-apprenenergy)/norm_f2);
                fprintf('Err: %.6f\n',20*log10(relres(relresid)));
                
                %relres(relresid) = printiterappr(s,M,norm_c,iter,kv,flags);
            else
                relresexact(relresid) = printiterexact(c,dp,L,Ls,f,norm_f,iter,kv,flags);
                relres(relresid) = sqrt ((norm_f2-apprenenergy)/norm_f2);
                if ~isreal(relres(relresid))
                    prd = 1;
                end
            end
            if relres(relresid) <= kv.relrestol
                exitcode = 1;
                break;
            end
            if relres(relresid-1)<relres(relresid)
                exitcode = 4;
                break;
            end            
        end
    end
elseif flags.do_localomp || flags.do_compllocalomp
    %% LOCAL ORTHOGONAL MATCHING PURSUIT
    suppind = false(size(cres));
    %suppindcount = zeros(size(cres));
    c0 = cres;

    while atNo < kv.atoms && iter <= kv.maxit
        %% 1) Selection
        [~,n] = max(maxcols); n = n-1;
        m = maxcolspos(n+1); m=m-1;
        wIdx = floor(n/N) + 1;
        nstart = (wIdx - 1)*N;
        nloc = n - nstart;

        %        [cmaxtrue] = max(max(abs(cresfull(1:M2,:))));
        %        if abs(cresfull(m+1,n+1)) ~= cmaxtrue
        %            warning('ja')
        %        end
        
        iter = iter+1;
        if suppindcount(m+1,n+1) == 0 && m < M2, atNo = atNo + 1; end
        if suppindcount(m+1,n+1) >= kv.atsellim, exitcode = 3; break; end
        suppindcount(m+1,n+1) = suppindcount(m+1,n+1) + 1;
        
%         if suppindcount(m+1,n+1) == 0, atNo = atNo + 1; end
%   
%         suppindcount(m+1,n+1) = suppindcount(m+1,n+1) + 1;
%         if suppindcount(m+1,n+1) > kv.atsellim,
%             break; 
% %            pred= 1;
% %             s(m+1,n+1) = 0;
% %             [maxcolupd,maxcolposupd] = max(s(1:M2,n+1));
% %             maxcols(n+1) = maxcolupd;
% %             maxcolspos(n+1) = maxcolposupd;
% %             continue;
%         end


        suppind(m+1,n+1) = 1;
%         if m~=0
%             suppind(M+1-m,n+1) = 1;
%         end
        %suppindcount(m+1,n+1) = suppindcount(m+1,n+1) + 1;


        %% 2) Residual update
        for secondwIdx = 1:numel(g)
            % Index range in the output
            idxn = N*(secondwIdx-1) + mod(nloc + kernwidx{wIdx,secondwIdx},N)+1;
            idxm = mod(m + kernhidx{wIdx,secondwIdx},M)+1;

            cresfulltmp = cres(idxm,idxn);
                        
            % Mask for active atoms
            suppidtmp = suppind(idxm,idxn);
            %suppidtmp(:) = 0;
            %suppidtmp(floor(end/2)+1) = 1;

            % Coefficients of active atoms
            cval = cresfulltmp(suppidtmp);
            cvaln = repmat(idxn',numel(idxm),1);
            cvaln = cvaln(suppidtmp);
            cvalm = repmat(idxm,1,numel(idxn));
            cvalm = cvalm(suppidtmp);

            G = eye(numel(cval));

            for ii = 1:numel(cval)
                currkern = kerns{wIdx,secondwIdx}(:,:,1+mod(cvaln(ii)-1,kernno));
                [kernh,kernw] = size(currkern);
                mmid = floor(kernh/2) + 1 - cvalm(ii);
                nmid = floor(kernw/2) + 1 - cvaln(ii);

                for jj = [1:ii-1,ii+1:numel(cval)]
                    muse = mmid + cvalm(jj);
                    nuse = nmid + cvaln(jj);

                    if muse >=1  && muse <= kernh && nuse>=1 && nuse <=kernw
                        G(ii,jj) = conj(currkern(muse, nuse));
                    end
                end
            end
        end

%        Gcond = cond(G);
%        if Gcond<1e-5 || Gcond > 1e5
%            warning('prd');
%             break;
%         end

        % Update the solution
        cvalinv = G\cval;

        ctmp = c(idxm,idxn);
        ctmpadd = ctmp(suppidtmp) + cvalinv;
        ctmp(suppidtmp) = ctmpadd;
        c(idxm,idxn) = ctmp;

        for ii=1:numel(cvalinv)
            idxn = mod(cvaln(ii)-1 + kernwidx{wIdx,wIdx},N)+1;
            idxm = mod(cvalm(ii)-1 + kernhidx{wIdx,wIdx},M)+1;

            currkern = kerns{wIdx,secondwIdx}(:,:,1+mod(cvaln(ii)-1,kernno));
            cres(idxm,idxn) = cres(idxm,idxn) - cvalinv(ii)*currkern;
%             if cvalm(ii)-1~=0
%                 idxm = mod(M - (cvalm(ii)-1) + kernhidx{winIdx,winIdx},M)+1;
%                 cres(idxm,idxn) = cres(idxm,idxn) - cvalinv(ii)*currkern;
%             end
       end

       idxn = mod(n + bigkernwidx{wIdx,secondwIdx},N)+1;
       idxm = mod(m + bigkernhidx{wIdx,secondwIdx},M)+1;
       s(idxm,idxn) = abs(cres(idxm,idxn));
       [maxcolupd,maxcolposupd] = max(s(:,idxn));

       maxcols(idxn) = maxcolupd;
       maxcolspos(idxn) = maxcolposupd;
       
       if mod(iter,kv.printstep) == 0
            plotiter(c,cres,a,M,clim,iter,kv,flags);
       end
       
        %resnorm = resnorm - (2*abs(cval))^2;
        
        if mod(iter,kv.relresstep) == 0
            relresid = ceil(iter/kv.relresstep) + 1;
            %err = 10*log10( resnorm/ norm_f2);
            fprintf('Atoms: %d\n',atNo);
            if flags.do_errappr
                relres(relresid) = printiterappr(s,M,norm_c,iter,kv,flags);
            else
                relres(relresid) = printiterexact(c,g,a,M,L,Ls,f,norm_f,iter,kv,flags);
            end
            if relres(relresid) <= kv.relrestol
                exitcode = 1;
                break;
            end
            if relres(relresid-1)<relres(relresid)
                exitcode = 4;
                break;
            end            
        end

   end
elseif flags.do_cyclicmp
    %% CYCLIC MATCHING PURSUIT
    while iter <= kv.maxit
        %% 1) Selection
        [~,n] = max(maxcols); n = n-1;
        m = maxcolspos(n+1); m=m-1;
        wIdx = floor(n/N) + 1;
        nloc = n - (wIdx - 1)*N;

        if suppindcount(m+1,n+1) >= kv.atsellim, break; end
        suppindcount(m+1,n+1) = suppindcount(m+1,n+1) + 1; 
        if ~suppind(m+1,n+1)
            suppNo = suppNo + 1;
            suppIdx(suppNo,:) = [m,n];
            suppind(m+1,n+1) = 1;
        end
        
        % 1b) Selected coefficient
        cval = cres(m+1,n+1);
        %% 3) Coefficient update
        cvalold = c(m+1,n+1);
        % A single atom can be selected more than once
        c(m+1,n+1) = cvalold + cval;

        %% 2) Residual update
        for secondwIdx = 1:numel(g)
            idxn = N*(secondwIdx-1) + mod(nloc + kernwidx{wIdx,secondwIdx},N)+1;
            idxm = mod(m + kernhidx{wIdx,secondwIdx},M)+1;

            currkern = kerns{wIdx,secondwIdx}(:,:,1+mod(n,kernno));

            cresfulltmp = cres(idxm,idxn);
            cresfulltmp = cresfulltmp - cval*currkern;
            cres(idxm,idxn) = cresfulltmp;

            s(idxm,idxn) = abs(cresfulltmp);
            [maxcolupd,maxcolposupd] = max(s(1:M2,idxn));

            maxcols(idxn) = maxcolupd;
            maxcolspos(idxn) = maxcolposupd;
        end
        
        for cycle = 1:kv.cyclicmpcycles
            for atId = 1:suppNo
                [m] = suppIdx(atId,1);
                [n] = suppIdx(atId,2);
                wIdx = floor(n/N) + 1;
                nloc = n - (wIdx - 1)*N;
                idxn = N*(secondwIdx-1) + mod(nloc + kernwidx{wIdx,secondwIdx},N)+1;
                idxm = mod(m + kernhidx{wIdx,secondwIdx},M)+1;
                
                cval = c(m+1,n+1);
                c(m+1,n+1) = 0;
                suppindcount(m+1,n+1) = 0;
                suppind(m+1,n+1) = 0;
                
                % Current kernel
                currkern = kerns{wIdx,secondwIdx}(:,:,1+mod(n,kernno));

                % Add back the atom to the residual
                cresfulltmp = cres(idxm,idxn);
                cresfulltmp = cresfulltmp + cval*currkern;
                cres(idxm,idxn) = cresfulltmp;
                
                % Update max
                s(idxm,idxn) = abs(cresfulltmp);
                [maxcolupd,maxcolposupd] = max(s(1:M2,idxn));

                maxcols(idxn) = maxcolupd;
                maxcolspos(idxn) = maxcolposupd;

                % Find max
                [~,n] = max(maxcols); n = n-1;
                m = maxcolspos(n+1); m = m-1;
                wIdx = floor(n/N) + 1;
                nloc = n - (wIdx - 1)*N;
                
                % Replace atom in selected atoms
                suppIdx(atId,:) = [m,n];
                suppindcount(m+1,n+1) = suppindcount(m+1,n+1) + 1;
                suppind(m+1,n+1) = 1;
                    
                cval = cres(m+1,n+1);
                cvalold = c(m+1,n+1);
                c(m+1,n+1) = cvalold + cval;
                
                % Update residual
                for secondwIdx = 1:numel(g)
                    idxn = N*(secondwIdx-1) + mod(nloc + kernwidx{wIdx,secondwIdx},N)+1;
                    idxm = mod(m + kernhidx{wIdx,secondwIdx},M)+1;

                    currkern = kerns{wIdx,secondwIdx}(:,:,1+mod(n,kernno));

                    cresfulltmp = cres(idxm,idxn);
                    cresfulltmp = cresfulltmp - cval*currkern;
                    cres(idxm,idxn) = cresfulltmp;

                    s(idxm,idxn) = abs(cresfulltmp);
                    [maxcolupd,maxcolposupd] = max(s(1:M2,idxn));

                    maxcols(idxn) = maxcolupd;
                    maxcolspos(idxn) = maxcolposupd;
                end
                
            end
        end
       
        if mod(iter,kv.printstep) == 0
            plotiter(c,cres,a,M,clim,iter,kv,flags);
        end
        if mod(iter,kv.relresstep) == 0 || iter == kv.maxit
            [fhat, relres] = printiter(c,cres,g,a,M,L,Ls,relres,f,norm_f,iter,kv,flags);
        end
        iter = iter+1;
    end    
elseif flags.do_complmp
    %% COMPLEMENTARY MATCHING PURSUIT
    while atNo < kv.atoms && iter < kv.maxit
        %% 1) Selection
        [~,n] = max(maxcols); n = n-1;
        m = maxcolspos(n+1); m=m-1;
        wIdx = floor(n/N) + 1;
        nstart = (wIdx - 1)*N;
        nloc = n - nstart;

        iter = iter+1;
        if suppindcount(m+1,n+1) == 0 && m < M2, atNo = atNo + 1; end
        if suppindcount(m+1,n+1) >= kv.atsellim, exitcode = 3; break; end
        suppindcount(m+1,n+1) = suppindcount(m+1,n+1) + 1;
        
        % 1b) Selected coefficient
        cval = cres(m+1,n+1);
        %% 3) Coefficient update
        cvalold = c(m+1,n+1);
        % A single atom can be selected more than once
        c(m+1,n+1) = cvalold + cval;

        %% 2) Residual update
        for secondwIdx = 1:numel(g)
            idxn = N*(secondwIdx-1) + mod(nloc + kernwidx{wIdx,secondwIdx},N)+1;
            idxm = mod(m + kernhidx{wIdx,secondwIdx},M)+1;

            currkern = kerns{wIdx,secondwIdx}(:,:,1+mod(n,kernno));

            cresfulltmp = cres(idxm,idxn);
            cresfulltmp = cresfulltmp - cval*currkern;
            cres(idxm,idxn) = cresfulltmp;

            s(idxm,idxn) = abs(cresfulltmp);
            
            kernh = size(currkern,1);
            mmid = floor(kernh/2) + 1;
            spillm = mmid - m;
            if m > 0 && spillm > 0
                mconj = M - m;
                idxm = mod(mconj + kernhidx{wIdx,secondwIdx},M)+1;
                cval2 = cres(mconj + 1,n+1);
                
                cresfulltmp = cres(idxm,idxn);
                cresfulltmp = cresfulltmp - cval2*currkern;
                cres(idxm,idxn) = cresfulltmp;
                s(idxm,idxn) = abs(cresfulltmp);
            end
            
            [maxcolupd,maxcolposupd] = max(s(1:M2,idxn));
            maxcols(idxn) = maxcolupd;
            maxcolspos(idxn) = maxcolposupd;
        end
       
        if mod(iter,kv.printstep) == 0
            plotiter(c,cres,a,M,clim,iter,kv,flags);
        end
       
        %resnorm = resnorm - (2*abs(cval))^2;
        
        if mod(iter,kv.relresstep) == 0
            relresid = ceil(iter/kv.relresstep) + 1;
            %err = 10*log10( resnorm/ norm_f2);
            fprintf('Atoms: %d\n',atNo);
            if flags.do_errappr
                relres(relresid) = printiterappr(s,M,norm_c,iter,kv,flags);
            else
                relres(relresid) = printiterexact(c,dp,L,Ls,f,norm_f,iter,kv,flags);
            end
            if relres(relresid) <= kv.relrestol
                exitcode = 1;
                break;
            end
            if relres(relresid-1)<relres(relresid)
                exitcode = 4;
                break;
            end            
        end


    end
end




%% Final computation
% Approximation
fhat = reccoefs(c,dp,L,Ls);
% Coefficient residual 
cres = cellfun(@(cEl,m2El) cEl(1:m2El,:),cres,{dp.M2}.','UniformOutput',0);
% Coefficient solution
c = cellfun(@(cEl,m2El) cEl(1:m2El,:),c,{dp.M2}.','UniformOutput',0);
% Approximation error
relresfinal = norm(postpad(f,Ls)-fhat)/norm_f;

t = toc;
fprintf('%.2f atoms/s\n',atNo/t);

if atNo ~= kv.atoms, exitcode = 2; end

info.cres = cres;
info.relres = relresfinal;
info.relresiter = relres;
info.iter = iter;
info.exitcode = exitcode;
info.exitmsg = convmessages{exitcode+1};
info.atoms = atNo;
info.suppindcount = cellfun(@(spEl,m2El) spEl(1:m2El,:),suppindcount,{dp.M2}.','UniformOutput',0);
info.g = g;
info.a = a;
info.M = M;
info.kerns = kerns;

for ii=1:numel(c)
    info.(sprintf('plotc%i',ii)) = @(varargin) plotdgtreal(c{ii},aarr(ii),Marr(ii),varargin{:});
end


%%%%%%%%%%%%%%%%%% Helper functions %%%%%%%%%%%%%%%%%%%%%%%
function [fhat,fhats] = reccoefs(c,dp,L,Ls)
    %N = L/a;
    fhats = zeros(Ls,numel(dp));

    for ii=1:numel(dp)
        if dp(ii).M == dp(ii).M2
            fhats(:,ii) = idgt(c{ii}(1:dp(ii).M,:),dp(ii).g,dp(ii).a,Ls);
        else
            fhats(:,ii) = idgtreal(c{ii}(1:dp(ii).M2,:),dp(ii).g,dp(ii).a,dp(ii).M,Ls);
        end
    end

    fhat = sum(fhats,2);

function [kerns,kmid,mask,kernnorm] = projkernels(g1,g2,a1,a2,M1,M2,L,tol)
    a = min([a1,a2]);
    M = max([M1,M2]);
    N = L/a;
    M2 = floor(M/2) + 1;
    
    kern = dgt(fir2long(g1,L),g2,a,M);
    kernnorm = norm(kern,'fro');

    [ksize,kmid]=findsmallkernelsize(kern(1:M2,:),tol);

    if ksize(1)>M, ksize(1) = M; end
    if ksize(2)>N, ksize(2) = N; end
    kernh = ksize(1); 
    kernw = ksize(2);

    kern = middlepad(kern,kernh);
    kernw1 = kmid(2);
    kernw2 = kernw - (kmid(2)+1);
    kern = [kern(:,1:kernw1),kern(:,end-kernw2:end)];

    kernno = lcm(M,a)/a;
    kerns = zeros([size(kern),kernno]);

    kern =  circshift(kern,kmid-1);
    
    for n=1:kernno
        kerns(:,:,n) = phasekernfi(kern,kmid,n-1,a,M);
    end

    thr = tol*max(abs(kern(:)));
    mask = abs(kerns(:,:,n)) > thr;

function [ksize,kmid]=findsmallkernelsize(kern,relthr)
    [M2,N] = size(kern);
    thr = relthr*max(abs(kern(:)));

    lastrow = 1;
    for n=1:N
        newlastrow = find(abs(kern(:,n))>thr,1,'last');
        if newlastrow > lastrow
            lastrow = newlastrow;
        end
    end
    
    lastcol1 = 1;
    lastcol2 = 1;
    for m=1:M2
        newlastcol = find(abs(kern(m,1:floor(end/2)+1))>thr,1,'last');
        if newlastcol > lastcol1
            lastcol1 = newlastcol;
        end
        newlastcol = find(abs(kern(m,end:-1:floor(end/2)))>=thr,1,'last');
        if newlastcol > lastcol2
            lastcol2 = newlastcol;
        end
    end
    %lastcol2 = floor((lastcol2/2));

    ksize = [2*lastrow-1, lastcol1 + lastcol2];
    kmid = [lastrow,lastcol1];

function kernm = phasekernfi(kern,kmid,n,a,M)
    kernh = size(kern,1);
    kmidh = kmid(1);
    midx = (-kmidh + 1:kernh - kmidh)';
    %midx = circshift(fftindex(kernh),kmidh-1);
    l = -2*pi*n*midx*a/M;
    kernm = bsxfun(@times,kern,exp(1i*l));

% M/a periodic in m
function kernm = phasekernti(kern,kmid,m,a,M)
    kernw = size(kern,2);
    kmidw = kmid(2);
    %nidx = fftindex(kernw)';
    nidx = (-kmidw + 1:kernw - kmidw);
    l = 2*pi*m*nidx*a/M;
    kernm = bsxfun(@times,kern,exp(1i*l));

function [m,n, winIdx, nstart, nloc] = findmax(maxcols,maxcolspos,N)
    [~,n] = max(maxcols); n = n-1;
    m = maxcolspos(n+1); m=m-1;
    winIdx = floor(n/N) + 1;
    nstart = (winIdx - 1)*N;
    nloc = n - nstart;

function plotiter(c,cres,a,M,clim,iter,kv,flags)
        M2 = floor(M/2) + 1;
        figure(1);clf;plotdgt(c{1},a,'clim',clim);shg;
        figure(2);clf;plotdgt(c{2},a,'clim',clim);shg;
    
function relres = printiterappr(s,M,norm_c,iter,kv,flags)
    M2 = floor(M/2) + 1;
    relrescurr = sqrt( ( sum(s(1,:).^2) + sum(sum(2*s(2:M2,:).^2)) )./norm_c );
    relres = relrescurr(2);
    spreaddb = 20*log10(relrescurr(2)) - 20*log10(relrescurr(1));
    
    if spreaddb < 1
         if flags.do_printerr || flags.do_printdb
             if flags.do_printdb
                 relrescurr = 20*log10(relrescurr);
                 fprintf('Iteration %d, RMS: %.2f dB\n',iter, relrescurr(2));
             else
                 fprintf('Iteration %d, RMS: %.2d \n',iter, relrescurr(2));
             end
        end
    else
         if flags.do_printerr || flags.do_printdb
             if flags.do_printdb
                 relrescurr = 20*log10(relrescurr);
                 fprintf('Iteration %d, RMS range: [%.2f %.2f] dB\n',...
                         iter, relrescurr(1), relrescurr(2));
             else
                 fprintf('Iteration %d, RMS range: [%.2d %.2d] \n',...
                         iter, relrescurr(1), relrescurr(2));
             end
        end        
    end
        
function relres = printiterexact(c,dp,L,Ls,f,norm_f,iter,kv,flags)
     %M2 = floor(M/2) + 1;
       
     fhatsum = reccoefs(c,dp,L,Ls);
     relrescurr = norm(postpad(f,Ls)-fhatsum)/norm_f;
     relres = relrescurr;
     
     if flags.do_printerr || flags.do_printdb
         if flags.do_printdb
              relrescurr = 20*log10(relrescurr);
              fprintf('Iteration %d, RMS: %.6f dB\n',iter, relrescurr);
         else
              fprintf('Iteration %d, RMS: %.2d %s\n',iter, relrescurr);
         end
     end
    

