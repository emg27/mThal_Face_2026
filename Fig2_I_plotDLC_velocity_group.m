close all
clear

filePATH = 'P:\projects\human\VOP STIM\DATA\Chronic_DBS\BP\Facial Tasks\kinematics\';

load([filePATH 'gVelocity_new.mat'])

task = {'tongue' 'smile' 'openClose' 'kiss'};
stim = {'nostim_1' '55Hz_1' 'nostim_2' '55Hz_2' 'nostim_3' '55Hz_3'};

G = figure('Name','Group Velocity New');
for t = 1:length(task)
    ax(t) = subplot(2,2,t); hold on
    myboxplot(groupVelocity(t,:)', 'box', [],1,ax(t))
    xticks(1:length(stim))
    xticklabels(stim)
    ylabel('Percent Change')
    title(task{t})
end
sgtitle('Group Velocity New')

%% Save Figures

G = findobj('Type', 'figure');
figFolder = 'P:\projects\human\VOP STIM\DATA\Chronic_DBS\BP\Facial Tasks\kinematics';

saveFigurePDF(G, [figFolder])

for g = 1:length(G)
    figName = G(g).Name;
    figPATH = fullfile(figFolder, ['\' figName]);
    saveas(G(g), figPATH, 'fig');
end