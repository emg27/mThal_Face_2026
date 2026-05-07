%clearvars -except AllData Dat DatIpsi
clear
close all

load("/Users/zira/Library/CloudStorage/Dropbox/PostDoc/ElviraMarco/One-on-One/20250106/contra_ipsi_AllData_vim_updated_Nov2025.mat")
%% Plot the DCS figures FACE
contactAll = {'L MASS','L ORIS','L MYLO','R MASS','R ORIS','R MYLO','B CRICO'}; 
contactAll = {'B CRICO','L MASS','L ORIS','L MYLO'};
contactAll = {'R MASS','R ORIS','R MYLO'}; 

session = '20230615';
PATHFILE = '/Volumes/rnelshare/projects/human/VOP STIM/DATA/Intra_Op_DBS/XLTEK/'
time = linspace(0,50,600);
dt = mean(diff(time));
xLimPlt = [1 50];

testType = {'DCS(Probes)'};
stimCond = {'BL','VIM80','VOP80','VOA80'};

allCond = {'13mA'};
%saveDir = uigetdir;
for n = 1:length(contactAll)
    contact = contactAll(n)
    
    if n==1
    %% Collect the condition data indices
    % Baseline before
    setM1 = 264:294;
    stimPol{1,1} = setM1;
    
    % VIM80
    setC_n2p5B =326:356;
    stimPol{2,1} = setC_n2p5B;
    
    %VOP80
    setA_n2p5B = 357:387;
    stimPol{3,1} = setA_n2p5B;
    
    
    %VOA80
    setA_n0p5B =295:329;
    stimPol{4,1} = setA_n0p5B;
    
  
    end

        %% Here select which conditions you want to plot
     conds_todo = [1,2];
     if n==1
     for i=1:length(conds_todo)
      stimPol2{i,1}=stimPol{conds_todo(i)};  
      stimCond2{i}=stimCond{conds_todo(i)};  
     end
     stimPol=stimPol2;
     stimCond=stimCond2;
     end
%     
   

     %% Here select which conditions you want to plot
%      conds_todo = [1,4];
%      if n==1
%      for i=1:length(conds_todo)
%       stimPol2{i,1}=stimPol{conds_todo(i)};  
%       stimCond2{i}=stimCond{conds_todo(i)};  
%      end
%      stimPol=stimPol2;
%      stimCond=stimCond2;
%      end
%     
    
    %% Load the data and determine the area under the curve values
    [dat aoc] = deal(cell(size(stimPol)));
    lenVal = nan(size(stimPol));
    
    for k = 1:size(stimPol,1)
        dat{k} = XLTEK.export(session,PATHFILE,'contact',contact,'setNum',...
            compose('#%d',stimPol{k,1}),'testType',testType);
        lenVal(k) = size(dat{k},2);
    end
    
    maxArea = max(lenVal);
    % Calculate the area under the curve
    subset = 60:500;
    for k = 1:size(stimPol,1)
        aoc{k} = nan(maxArea,1);
        aoc{k}(1:lenVal(k),1) = trapz(time(subset),abs(dat{k}(subset,:)));
%            figure,plot(abs(dat{k}))
    end
    
%     [b,a]=butter(3,sr,'bandpass');
    for k = 1:size(stimPol,1)
        
        for t=1:size( dat{k},2)
            aoc{k} = nan(maxArea,1);
        signal = dat{k}(:,t)';
        signal = smooth(signal,20);
        dat{k}(:,t)= signal';
        aoc{k}(1:lenVal(k),1) = trapz(time(subset),abs(dat{k}(subset,:)));
        end
%             figure,plot(abs(dat{k}))
    end

  

    %% Plot the data
    F(n,1) = figure('Position',[100 100 800 850]); % Waveform figure
    F(n,1).Name = sprintf('%s_traces_%s_m1',session,contact{1});
    F(n,2) = figure('Position',[100 100 800 850]); % Time trace figure
    F(n,2).Name = sprintf('%s_polarity_time_%s_m1',session,contact{1});
    F(n,3) = figure('Position',[100 100 800 850]); % DCS figure
    F(n,3).Name = sprintf('%s_auc_%s_m1',session,contact{1});
    for k = 1:size(stimPol,1)
        % Plot the raw waveforms
        figure(F(n,1))
        axeD(k) = subplot(size(stimPol,1),2,2*(k-1)+1); hold on
        plot(time,(dat{k}))
        plot(time,mean(dat{k},2),'k','LineWidth',1.5)
        xlabel('Time (ms)'), ylabel('Trace')
        title(sprintf('DCS %s \n %s',contact{1},stimCond{k}))
        
        % Plot the rectified waveforms
        figure(F(n,1))
        axeR(k) = subplot(size(stimPol,1),2,2*k); hold on
        plot(time,abs(dat{k}))
        plot(time,mean(abs(dat{k}),2),'k','LineWidth',1.5)
        xlabel('Time (ms)'), ylabel('Trace')
        title(sprintf('Rectified DCS %s \n %s',contact{1},stimCond{k}))
        
        % Plot the histogram of the area under the curve
        figure(F(n,2))
        axeT(1) = subplot(size(stimPol,1),1,k); hold on
        d = dat{k}(subset,:);
        if ~isempty(d)
            plot(0:dt:dt*[length(d(:))-1],d(:))
        end
        title(sprintf('DCS through time %s \n %s',contact{1},stimCond{k}))
        xlabel('Time (ms)'), ylabel('Trace')
    end
    
    % Plot the histogram of the area under the curve
    figure(F(n,3))
    %boxplot([aoc{:}])
    myboxplot(aoc,'box')
    title(sprintf('Area under the curve: %s',contact{1}))
    xlabel('Conditions'), ylabel('Area under the curve')
     set(gca,'XTick',1:numel(stimCond))
    set(gca,'XTickLabels',stimCond,'XTickLabelRotation',30)
% 
%     figure,
%     for n=1:length(aoc)
%     plot(movmean(aoc{n},3),'*--'), hold on
%     end
%     legend(stimCond), title(contact{1},stimCond{k})

%     Dat.s20230615.vop.(contactAll{n}(end-3:end))={aoc{1},NaN,aoc{2},NaN,NaN,NaN};
        
    % Correct the trace plots TODO!
  %  matchAxis(axeR)
 %   matchAxis(axeD)
end
%saveFigurePDF(F,saveDir);


% Dat.s20230615.vop.CRICO={aoc{1},NaN,aoc{3},NaN,NaN,NaN};
% Dat.s20230615.vim.CRICO={aoc{1},NaN,aoc{2},NaN,NaN,NaN};
% Dat.s20230615.voa.CRICO={aoc{1},NaN,aoc{4},NaN,NaN,NaN};