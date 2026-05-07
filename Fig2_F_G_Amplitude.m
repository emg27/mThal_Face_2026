clear
close all

%% Load Case

Subject2Load = 'BP';

axisLabel = {'x','y'};
features = {'allPCALabels', 'amplitude','fallVelocity', 'meanVelocity','riseVelocity','width'};

switch Subject2Load
    case 'SEEG'

        pathNameList ={'/Volumes/rnelshare/projects/human/VOP STIM/DATA/SEEG/Patient001_20211009/DeepLabCut/SEEG-01_Kinematic Analysis/Workspace/'
            '/Volumes/rnelshare/projects/human/VOP STIM/DATA/SEEG/Patient002_20211021/DLC/SEEG-02-kinematicAnalysis/DAY 2/Workspace/'
            '/Volumes/rnelshare/projects/human/VOP STIM/DATA/SEEG/Patient005_20230501/DLC/Workspace/'};

        sList = {'1' '2' '5'}; %Subjects
        labels = {'tongue-noStim','smile-noStim','openClose-noStim','kiss-noStim', 'tongue55Hz','smile55Hz','openClose55Hz','kiss55Hz'};

        faceTasklst = { 'jawL','cheekL','mouthL','upperLip','lowerLip','chin'};

        task = {'tongue','smile','openClose','kiss'};

        stim = {'noStim','50Hz','100Hz' %SEEG1
            'noStim','50Hz','100Hz' %SEEG2
            'noStim','55Hz','100Hz'}; %SEEG5

        trialsToRemove = {32, [], [], []
                  [], 4, [], []
                  [], [], [], [11 12]};

        figFolder = '/Volumes/rnelshare/projects/human/VOP STIM/DATA/SEEG/Figures/Kinematics/boxplots/';

    case 'BP'
        pathNameList = {'/Volumes/rnelshare/projects/human/VOP STIM/DATA/Chronic_DBS/BP/20230630/kinematics/Workspace/'
            '/Volumes/rnelshare/projects/human/VOP STIM/DATA/Chronic_DBS/BP/20220914/kinematics/Workspace/'
            '/Volumes/rnelshare/projects/human/VOP STIM/DATA/Chronic_DBS/BP/20220907/DLC/Workspace/'};

        sList = {'0630' '0914' '0907'}; %Sessions
        labels = {'tongue-noStim','smile-noStim','openClose-noStim','kiss-noStim', 'tongue55Hz','smile55Hz','openClose55Hz','kiss55Hz'};
        features = {'allPCALabels', 'amplitude','fallVelocity', 'meanVelocity','riseVelocity','width'};

        faceTasklst = { 'jawL','cheekL','mouthL','upperLip','lowerLip','chin','nose','mouthR','cheekR','jawR'};
        
        task = {'tongue','smile','openClose','kiss'}; %Chronic DBS
        stim = {'noStim' '55Hz'
                'noStim' '55Hz'
                'noStim' '55Hz'};

        figFolder = '/Volumes/rnelshare/projects/human/VOP STIM/DATA/Chronic_DBS/BP/Facial Tasks/boxplots/new/';

        trialsToRemove = {[], [], [], []
                  [], [], [], []
                  [], [], [], []};
                  %[], [], [6], [6 10]};

end

%% Load Data 

taskToPlot = [1:4];
featureToPlot = 2;
markerToPlot = [1 2 3 4 5 6];
axisToPlot = [2]; % 1 X or 2 Y-axis

Data = {};

for t = 1:length(taskToPlot) %Task
    for s = 1:length(sList) %Subject/Sessions

        fileName = pathNameList{s};
        rawDat = sort({dir([fileName '*.mat']).name});
        load([fileName 'allPCAlabels.mat']); %load PCA labels indeces

        dataToPlot = [];

        for c = 1:size(stim,2) %stim
            stimIdx{t}{s,c} = find(contains(allPCAlabels{t},stim{s,c})); %Find Stim Idx from PCA Labels

            clear measurement
            
            %Load Feature
            for f = featureToPlot
                load([fileName features{f} '.mat']);

                if strcmp(features{f},'amplitude')
                    measurement = amplitude{taskToPlot(t)};

                elseif strcmp(features{f},'fallVelocity')
                    measurement = fallVelocity{taskToPlot(t)};

                elseif strcmp(features{f},'meanVelocity')
                    measurement = meanVelocity{taskToPlot(t)};

                elseif strcmp(features{f},'riseVelocity')
                    measurement = riseVelocity{taskToPlot(t)};

                elseif strcmp(features{f},'width')
                    measurement = width{taskToPlot(t)};
                end
        
                if ~isempty(trialsToRemove{s,taskToPlot(t)})
                    measurement(trialsToRemove{s,taskToPlot(t)},:) = [];
                    for tt = 1:length(trialsToRemove{s,taskToPlot(t)})
                    stimIdx{t}{s,c}(stimIdx{t}{s,c} == trialsToRemove{s,taskToPlot(t)}(tt)) = [];
                    end
                end

                for r = 1:size(stimIdx{t}{s,c},2) %reps per Stim
                    for m = 1:length(markerToPlot) % Markers
                        for n = 1:length(axisToPlot) % Axis

                            %Column Index
                            if strcmp(axisLabel{axisToPlot(n)},'x')
                                col = markerToPlot(m)*2-1;
                            elseif strcmp(axisLabel{axisToPlot(n)},'y')
                                col = markerToPlot(m)*2;
                            end

                            %MyBoxPlot Struct
                            Data{t,m}{s,c}(r,:) = measurement(stimIdx{t}{s,c}(r),col);
                        end
                    end
                end
            end
        end
    end
end

%Normalize Data to NoStim
for t = 1:size(Data,1) %Task
    for m = 1:size(Data, 2) %Markers
        for s = 1:size(Data{t,m},1) %Subject/Session

            baseline = nanmean(Data{t,m}{s,1}); %NoStim Baseline

            for c = 1:size(Data{t,m},2) %Stim
                if ~isempty(Data{t,m}{s,c})
                    for r = 1:length(Data{t,m}{s,c})

                        normDat{t,m}{s,c}(r,:) = (Data{t,m}{s,c}(r) - baseline)./baseline;
                    end
                    cleanDat{t,m}{s,c} = rmoutliers(normDat{t,m}{s,c});
                end
            end
        end

        %MyboxPLot MasterStruct
        MasterDat{t,m} = reshape(cleanDat{t,m}',1,[]); %Append Across Subjects/Sessions

        % Remove Extra Cells
        if isequal(MasterDat{t,m}{end},[])
            MasterDat{t,m}(end) = [];
        end

    end
end

%% PLot Separate Subjects/Session
close all

ColorMap = 	{"#0072BD",	"#D95319","#EDB120", "#7E2F8E","#77AC30","#4DBEEE", "#A2142F",'#EAD6D9'};

colMat = {'#edb965', '#053dad','#11190d','#edb965', '#053dad','#11190d','#edb965', '#053dad'}; %Stim Coordinate Color

%Restructure
for t = 1:size(normDat,1) %Task
    for m = 1:size(normDat,2) %Muscle
        for s = 1:size(normDat{t,m},1) %Subjects
            sDat{s}{t,m} = normDat{t,m}(s,:)';
        end
    end
end

%Plot
for f = 1:length(featureToPlot)
    for s = 1:length(sDat) %Subjects

        T(s) = figure(s); hold on
        T(s).Name = sprintf('%s%s %s %s', Subject2Load, sList{s}, features{featureToPlot(f)}, axisLabel{axisToPlot});

        for t = 1:size(sDat{s},1) %Task
            for m = 1:size(sDat{s},2) %Muscle
                figIdx = (t-1)*6 +m;
                ax(figIdx) = subplot(size(sDat{s},1),size(sDat{s},2),figIdx);

                myboxplot(sDat{s}{t,m}, 'box',colMat, 1, ax(figIdx)), hold on

                xticks(1:length(stim))
                xticklabels(stim(s,:))

                if m == 1
                    ylabel(task{t})
                end

                if t ==1
                    title(faceTasklst{m})
                end
                sgtitle(sprintf('%s%s %s %s', Subject2Load, sList{s}, features{featureToPlot(f)}, axisLabel{axisToPlot}))
            end
        end
    end
end

%% PLot All Subjects/Sessions
close all

switch Subject2Load
    case 'SEEG'
        subjectLabel = {'noStim' 'SEEG1 50Hz' 'SEEG1 100Hz','noStim' 'SEEG2 50Hz' 'SEEG2 100Hz','noStim' 'SEEG5 55Hz'};
        colMat = {'#edb965', '#053dad','#11190d','#edb965', '#053dad','#11190d','#edb965', '#053dad'}; %Stim Coordinate Color
    case 'BP'
        subjectLabel = {'noStim' '55Hz1' 'noStim' '55Hz2' 'noStim' '55Hz3'};
        colMat = {'#edb965', '#053dad','#edb965', '#053dad','#edb965', '#053dad'}; %Stim Coordinate Color
end

for f = 1:length(featureToPlot)
    F(f) = figure(f); hold on
    F(f).Name = sprintf('%s %s %s', Subject2Load, features{featureToPlot(f)}, axisLabel{axisToPlot});

    for t = 1:size(MasterDat,1) %Task
        for m = 1:size(MasterDat,2) %Muscle
            figIdx = (t-1)*6 +m;
            ax(figIdx) = subplot(size(MasterDat,1),size(MasterDat,2),figIdx);

            myboxplot(MasterDat{t,m}', 'box',colMat, 1, ax(figIdx)), hold on

            xticks(1:length(subjectLabel))
            xticklabels(subjectLabel)

            if m == 1
            ylabel(task{t})
            end

            if t ==1
            title(faceTasklst{m})
            end
        end
    end

    sgtitle(sprintf('%s %s', features{featureToPlot(f)}, axisLabel{axisToPlot}))
end

%% Save Figure

saveFigurePDF(F, [figFolder])

for g = 1:length(F)
    figName = F(g).Name;
    figPATH = fullfile(figFolder, ['/' figName]);
    saveas(F(g), figPATH, 'fig');
end