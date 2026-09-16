function [gbestX,gbestfitness,gbesthistory] = PRISM(mainHandle,popsize,dimension,xmax,xmin,vmax,vmin,maxiter,Func,FuncId,VisualSwitch)
% =========================================================================
%  PRISM -- Priority-Rank Integrated Search Mechanism
%
%  Reference implementation of the algorithm described in the manuscript:
%    "PRISM: A Priority-Rank Integrated Search Mechanism for Single-Objective
%     Black-Box Optimization"
%
%  The manuscript is currently UNDER REVIEW at a peer-reviewed journal.
%  The journal name is withheld for the duration of the review process.
%  This citation record will be updated once the review concludes.
%
%  Copyright (c) 2026  Qingke Zhang
%  School of Computer Science and Artificial Intelligence
%  Shandong Normal University, Jinan 250358, China
%
%  Released under the MIT License. See the LICENSE file in the repository
%  root for the full text. If you use this code in academic work, please
%  cite the manuscript above (see also CITATION.cff).
%
%  Version : V1.0
%  Updated : 2026-09-16
%
% -------------------------------------------------------------------------
%  Input arguments
%    mainHandle    - reserved handle for an external driver (currently unused)
%    popsize       - initial population size N0
%    dimension     - problem dimensionality D
%    xmax, xmin    - upper / lower bounds on the decision variables; scalar or
%                    1-by-D vectors
%    vmax, vmin    - reserved velocity bounds (currently unused: PRISM is a
%                    position-only search and carries no velocity term)
%    maxiter       - iteration cap; MaxFEs is derived as popsize * maxiter
%    Func          - function handle of the objective, called as f(x, FuncId)
%    FuncId        - numeric identifier forwarded to Func
%    VisualSwitch  - display flag; when true, progress is printed every 10%
%                    of the evaluation budget
%
%  Output arguments
%    gbestX        - best solution found, 1-by-D
%    gbestfitness  - objective value of gbestX
%    gbesthistory  - 1-by-MaxFEs record of the best-so-far objective value
%
% -------------------------------------------------------------------------
%  Design notes
%    MaxFEs is computed as popsize * maxiter rather than hard-coded, so the
%    benchmark configuration (N0 = 40, a 10000*D function-evaluation budget)
%    is reproduced by passing maxiter = 250*D. The search itself uses no
%    velocity term: every trial is produced by clipping a position update
%    to [lb, ub].
%
%    Default parameters: p = 0.20, q = 7, r = 0.25, H = 5, epsAccept = 0.001.
%
%    Note: this file releases a snapshot of the implementation that
%    accompanies the submitted manuscript. Any code or results released
%    after the review process concludes should be treated as authoritative.
% =========================================================================
FEs = 0;
MaxFEs = popsize * maxiter;
Fitness = Func;

q = 7;
p = 0.20;
r = 0.25;
epsAccept = 0.001;
epsVal = realmin;
[lb,ub,range] = makeBounds(xmin,xmax,dimension,epsVal);
H = 5;
Mchi = 0.5 * ones(H,1);
MCR  = 0.9 * ones(H,1);
kh = 1;

chiList = [];
crList = [];
dfList = [];

N0 = popsize;
Nmin = min(N0,max(4,round(r * dimension)));
x = lb + rand(popsize,dimension).*range;
fitness = inf(popsize,1);

gbestfitness = inf;
gbestX = zeros(1,dimension);
gbesthistory = zeros(1,MaxFEs);

for i = 1:popsize
    if FEs >= MaxFEs, break; end

    fitness(i) = Fitness(x(i,:)',FuncId);
    FEs = FEs + 1;
    if fitness(i) < gbestfitness
        gbestfitness = fitness(i);
        gbestX = x(i,:);
    end
    gbesthistory(FEs) = gbestfitness;
end
while FEs < MaxFEs

    [~,ind] = sort(fitness,'ascend');
    bestID = ind(1);
    Best = x(bestID,:);
    rank = zeros(popsize,1);
    rank(ind) = 1:popsize;

    % ================= Stage 1: rank-priority learning =================
    for i = 1:popsize
        if FEs >= MaxFEs, break; end

        t = min(1,max(0,FEs/MaxFEs));

        chi = min(1.0,max(0.05,Mchi(randi(H)) + 0.05*randn));
        CR  = min(1.0,max(0.30,MCR(randi(H))  + 0.05*randn));
        elitePool = ind(2:min(q,popsize));
        if isempty(elitePool)
            elitePool = ind(1);
        end
        poorPool = ind(max(1,popsize-q+1):popsize);
        Elite = x(elitePool(randi(numel(elitePool))),:);
        Worst = x(poorPool(randi(numel(poorPool))),:);
        ids = selectID(popsize,i,2);

        Phi = zeros(4,dimension);
        nPhi = 4;

        Phi(1,:) = Best - Worst;
        Phi(2,:) = x(ids(1),:) - x(ids(2),:);
        Phi(3,:) = Best - Elite;
        Phi(4,:) = Elite - Worst;

        if popsize > 1
            rho = min(1,max(0,(rank(i)-1)/(popsize-1)));
        else
            rho = 0;
        end

        K = max(1,min(nPhi,ceil(1 + 3*(1-t)*rho)));
        Omega = randperm(nPhi,K);

        s = zeros(1,K);
        for k = 1:K
            s(k) = norm(Phi(Omega(k),:)) + epsVal;
        end
        step = zeros(1,dimension);
        total = sum(s) + epsVal;

        for k = 1:K
            step = step + (s(k)/total) * chi * Phi(Omega(k),:);
        end

        oldx = x(i,:);
        oldfit = fitness(i);

        newx = oldx;
        jrand = randi(dimension);
        mask = rand(1,dimension) < CR;
        mask(jrand) = true;

        newx(mask) = oldx(mask) + step(mask);
        newx = clip(newx,lb,ub);
        newfit = Fitness(newx',FuncId);
        FEs = FEs + 1;
        if newfit < oldfit
            df = oldfit - newfit;
            x(i,:) = newx;
            fitness(i) = newfit;

            chiList = [chiList; chi]; 
            crList  = [crList;  CR];  
            dfList  = [dfList;  df];  

        elseif rand < epsAccept && i ~= bestID
            x(i,:) = newx;
            fitness(i) = newfit;
        end

        if numel(chiList) >= H
            w = dfList / (sum(dfList) + epsVal);

            Mchi(kh) = sum(w.*chiList.^2)/(sum(w.*chiList)+epsVal);
            MCR(kh)  = sum(w.*crList.^2)/(sum(w.*crList)+epsVal);

            Mchi(kh) = min(1.0,max(0.05,Mchi(kh)));
            MCR(kh)  = min(1.0,max(0.30,MCR(kh)));

            kh = mod(kh,H) + 1;
            chiList = [];
            crList = [];
            dfList = [];
        end
        if fitness(i) < gbestfitness
            gbestfitness = fitness(i);
            gbestX = x(i,:);
        end
        gbesthistory(FEs) = gbestfitness;
    end
    if FEs >= MaxFEs, break; end
    % ================= Stage 2: stratified reflection =================
    [~,ind] = sort(fitness,'ascend');
    bestID = ind(1);

    rank = zeros(popsize,1);
    rank(ind) = 1:popsize;

    topN = min(popsize,max(2,round(p * popsize)));
    half = floor(popsize/2);

    tutorPool = ind(1:min(q,popsize));
    eliteSet = ind(1:topN);

    radius = mean(sqrt(sum((x(eliteSet,:) - gbestX).^2,2))) / dimension;
    radius = max(1e-10,radius);

    center = mean(x(ind(1:min(q,popsize)),:),1);

    t = min(1,max(0,FEs/MaxFEs));
    localFlag = radius < 0.01;

    zeta = min(0.10,max(0.01,0.01 + 0.09*(1-t)));
    ns = 0.05 * (1-t);
    for i = 1:popsize
        if FEs >= MaxFEs, break; end

        ri = rank(i);
        oldx = x(i,:);
        oldfit = fitness(i);

        if ri <= topN && localFlag
            newx = oldx + radius*(gbestX-oldx) + 0.3*radius*range.*randn(1,dimension);
            newx = clip(newx,lb,ub);
            [x(i,:),fitness(i),FEs] = tryEval( ...
                oldx,newx,oldfit,Fitness,FuncId,FEs,i==bestID,epsAccept);
        else
            if ri <= topN
                phi = 0.10 + 0.10*(1-t);
                useTutor = true;
            elseif ri <= half
                phi = min(0.50,max(1/dimension,(ri-topN)/(half-topN+epsVal)*0.30));
                useTutor = true;
            else
                phi = min(0.50,max(min(3,dimension)/dimension,(ri-half)/(popsize-half+epsVal)*0.50));
                useTutor = false;
            end
            mask = rand(1,dimension) < phi;
            if any(mask)
                newx = oldx;

                if useTutor
                    tutor = x(tutorPool(randi(numel(tutorPool))),:);
                    newx(mask) = oldx(mask) + ...
                        (tutor(mask)-oldx(mask)).*rand(1,sum(mask));
                else
                    dir = center - oldx;
                    newx(mask) = oldx(mask) + ...
                        rand*dir(mask) + ns*range(mask).*randn(1,sum(mask));
                end
                reset = mask & (rand(1,dimension) < zeta);
                if any(reset)
                    newx(reset) = lb(reset) + range(reset).*rand(1,sum(reset));
                end
                newx = clip(newx,lb,ub);
                [x(i,:),fitness(i),FEs] = tryEval( ...
                    oldx,newx,oldfit,Fitness,FuncId,FEs,i==bestID,epsAccept);
            end
        end
        if fitness(i) < gbestfitness
            gbestfitness = fitness(i);
            gbestX = x(i,:);
        end
        if FEs <= MaxFEs
            gbesthistory(FEs) = gbestfitness;
        end
    end
    % ================= Adaptive population reduction =================
    newN = round(N0 - (N0-Nmin)*(FEs/MaxFEs));
    newN = max(Nmin,min(N0,newN));
    if popsize > newN
        [~,idx] = sort(fitness,'ascend');
        del = idx(end-(popsize-newN)+1:end);
        x(del,:) = [];
        fitness(del) = [];
        popsize = numel(fitness);
    end
    if nargin >= 11 && VisualSwitch
        if mod(FEs,max(1,floor(MaxFEs/10))) == 0
            fprintf('PRISM | FEs=%d/%d | Pop=%d | Best=%.16e\n',FEs,MaxFEs,popsize,gbestfitness);
        end
    end
end
if FEs < MaxFEs
    gbesthistory(FEs+1:MaxFEs) = gbestfitness;
elseif FEs > MaxFEs
    gbesthistory = gbesthistory(1:MaxFEs);
end
end
function [x,fit,FEs] = tryEval(oldx,newx,oldfit,Fitness,FuncId,FEs,protected,epsAccept)
newfit = Fitness(newx',FuncId);
FEs = FEs + 1;
if newfit < oldfit || (~protected && rand < epsAccept)
    x = newx;
    fit = newfit;
else
    x = oldx;
    fit = oldfit;
end
end
function x = clip(x,lb,ub)
x = min(max(x,lb),ub);
end
function r = selectID(N,i,count)
if N <= 1
    r = ones(1,count);
    return;
end
pool = 1:N;
pool(pool == i) = [];
if isempty(pool)
    r = ones(1,count);
elseif numel(pool) >= count
    r = pool(randperm(numel(pool),count));
else
    r = pool(randi(numel(pool),1,count));
end
end
function [lb,ub,range] = makeBounds(xmin,xmax,D,epsVal)
if isscalar(xmin)
    lb = repmat(xmin,1,D);
else
    lb = reshape(xmin,1,D);
end
if isscalar(xmax)
    ub = repmat(xmax,1,D);
else
    ub = reshape(xmax,1,D);
end
range = ub - lb;
range(range == 0) = epsVal;
end
