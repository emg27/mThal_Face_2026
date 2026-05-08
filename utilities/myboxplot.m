function myboxplot(data,PlotType,ColorMap,plotStats,ax,plotDataPts,plotOpts)

% INPUT
%data is A column cell, each row is a 'condition'. Inside each cell, data
%are organized as a column. data{1,1} is the column vector with the first
%group, data{2,1} is the column vector with the second group and so on!

%If yu have a color map put it (cell of hex), otherwise there is one here.
% If you give a colormap, it can be either in hex (Cell) or rgb, then you
% will need to give a matrix of n_groupsx3, where each row is the rgb
% triplet for that group

if nargin<3 || isempty(ColorMap)
   ColorMap = {'#EAD6D9','#EAD6D9','#CEA1A8','#C0878F','#B26C75','#A0545F','#783F48','#5E3138','#432328','#26262C',...
       '#727283','#878797','#9D9DAA','#BEBEC6','#D3D3D9','#E2DCDE','#D1C7CA','#BFB0B5','#AC9AA0','#9A848B','#917880'};    
end

if length(data)<5 && nargin<3
    ColorMap = {'#C0878F','#A0545F','#26262C',...
       '#727283','#878797','#E2DCDE','#D1C7CA','#BFB0B5','#AC9AA0','#9A848B','#917880'};  
end

if nargin<4 || isempty(plotStats)
    plotStats = 1;
end

%if nargin==3 
    if ~iscell(ColorMap) %If the color map is given in rgb and not hex
        for c=1:size(ColorMap,1)
        ColorMap2{c}= rgb2hex(ColorMap(c,:));     
        end
         ColorMap=ColorMap2;
    end
  
%end

if isempty(PlotType)
    PlotType='box';
end

if nargin<5 || isempty(ax)
    figure
else
    axes(ax)
end

if nargin<6 || isempty(plotDataPts)
    plotDataPts = 1;
end

if nargin<7
    plotOpts = [];
end
%% Add Nan so each cell has the same legnth and we can use the boxplot and violinplot function

n_groups = length(data);
trials=zeros(n_groups,1);
for n=1:(n_groups)
    trials(n,1) = numel(data{n,1});
end
max_trials = max(trials);

for n=1:(n_groups)
    if numel(data{n,1})<max_trials
        data{n,1}=[data{n,1};NaN(max_trials-numel(data{n,1}),1)];
    end
end

%% Plot the dat
switch PlotType
    case 'bar'
        for i = 1:n_groups
            b=bar(i,mean([data{i}],'omitnan'),'FaceColor', ColorMap{i},'EdgeColor',[0,0,0]); hold on,
            b.BarWidth = 0.4; n_trial=size(data{i}(~isnan(data{i})),1);
            er = errorbar(i, mean([data{i}],'omitnan'), std([data{i}]/sqrt(n_trial),'omitnan'), '.');
            er.Color = [0 0 0]; hold on,
            scatter_data(:,i)=b.BarWidth*(rand(1,size(data{i,1},1)))+i-b.BarWidth/2;
            hold on, plot(scatter_data(:,i),data{i,1},'o','MarkerFaceColor',ColorMap{i},'MarkerEdgeColor','k','MarkerSize',6.5), hold on
        end

    case 'violin'            
          v=violinplot_internal([data{:}]); hold on, 
       
        for i = 1:n_groups
            v(1,i).ViolinColor = hex2rgb(ColorMap{i});
        end

    case 'box'
% %         boxplot([data{:}]), hold on
% %         for i=1:n_groups
% %         scatter_data(:,i)=0.2*(rand(1,size(data{i,1},1)))+i-0.2/2;
% %         hold on, plot(scatter_data(:,i),data{i,1},'o','MarkerFaceColor',ColorMap{i},'MarkerEdgeColor','k','MarkerSize',6.5), hold on
% %         end

        for i = 1:n_groups
            b=boxchart(i*ones(1,length([data{i}])),([data{i}]),'BoxFaceColor', ColorMap{i}); hold on, %if it plots point not in the colormap its outliers
            
            % Determine whether or not you want to plot the individual data
            % plots
            if plotDataPts
                scatter_data(:,i)=0.3*(rand(1,size(data{i,1},1)))+i-0.3/2;
                hold on, plot(scatter_data(:,i),data{i,1},'o','MarkerFaceColor',ColorMap{i},'MarkerEdgeColor','k','MarkerSize',6.5), hold on
            end

            % Modify b plotting using a cell if there are 7 input
            if ~isempty(plotOpts)
                set(b,plotOpts{:})
            end
        end

end
%% Add statistical analysis with bootstrapping
% 
%Bootstrap parameters
multcompare = n_groups-1;


% Find multcomparison
actual_group=0;
for n=1:(n_groups)
    if (sum(isnan(data{n,1})))==length(data{n,1}) %this I dont count
        actual_group = actual_group+0;
    else
        actual_group = actual_group+1;
    end
end

possible_comparison=0;
for n=1:actual_group-1
possible_comparison = possible_comparison +  (actual_group-n);
end
multcompare = possible_comparison;
multcompare =1;
%disp(multcompare)

if multcompare ==1
    disp('No multiple comparison correction!')
end

nRep = 10000;

%Here is to set where to plot the bars for statistics
YLimits = get(gca, 'YLim'); range=diff(YLimits);
ylim([YLimits(1) YLimits(2)+range/3]);

YLimits = get(gca, 'YLim');
Up_value = YLimits(2);
Down_value = max(max([data{:}]));
range = Up_value - Down_value;

possible_comparison = 0;
for n=1:n_groups-1
possible_comparison = possible_comparison +  (n_groups-n);
end
y_level_change = range/(possible_comparison+1);
ylevel = Down_value+y_level_change : y_level_change : Down_value+(possible_comparison)*y_level_change;
comparison = 0;

for fir=1:n_groups
    for sec=fir+1:n_groups
        comparison = comparison +1;
        group1 = data{fir};group2 = data{sec};

        % One asterisk?
        [ci95, rejectNull]=bootstrapCompMeans(group1(~isnan(group1)),group2(~isnan(group2)),nRep,0.05,multcompare);
        if rejectNull
            % Two asterisk?
            asterisco = 1;
            [ci95, rejectNull]=bootstrapCompMeans(group1(~isnan(group1)),group2(~isnan(group2)),nRep,0.01,multcompare);
            if rejectNull
                % Three asterisk?
                [ci95, rejectNull]=bootstrapCompMeans(group1(~isnan(group1)),group2(~isnan(group2)),nRep,0.001,multcompare);
                if rejectNull
                    p='***';
                    % Now I need to plot the bar and the asterisks
                    if ~((sum(isnan(group1)))==length(group1) || (sum(isnan(group2)))==length(group2))
                    hold on, plot(fir:sec,ones(1,sec-fir+1)*ylevel(comparison),'k','LineWidth',1.1),
                    hold on, text(fir,ylevel(comparison)+y_level_change/5,p)
                    end
                else
                    p='**';
                    if ~(sum(isnan(group1))==length(group1) || sum(isnan(group2))==length(group2))
                    % Now I need to plot the bar and the asterisks
                    hold on, plot(fir:sec,ones(1,sec-fir+1)*ylevel(comparison),'k','LineWidth',1.1),
                    hold on, text(fir,ylevel(comparison)+y_level_change/5,p)
                    end
                end
            else
                p='*';
                if ~(sum(isnan(group1))==length(group1) || sum(isnan(group2))==length(group2))
                % Now I need to plot the bar and the asterisks
                hold on, plot(fir:sec,ones(1,sec-fir+1)*ylevel(comparison),'k','LineWidth',1.1),
                hold on, text(fir,ylevel(comparison)+y_level_change/5,p)
                end
            end
        else
            p='n.s.';
            asterisco = 0;
            if plotDataPts
            hold on, plot(fir:sec,ones(1,sec-fir+1)*ylevel(comparison),'k','LineWidth',1.1),
            hold on, text(fir,ylevel(comparison)+y_level_change/5,p)
            end
        end

%         % Now I need to plot the bar and the asterisks
%         hold on, plot(fir:sec,ones(1,sec-fir+1)*ylevel(comparison),'k','LineWidth',1.1),
%         hold on, text(fir,ylevel(comparison)+y_level_change/5,p)
    end
end
end
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 


%% Functions

function [ rgb ] = hex2rgb(hex,range)
% hex2rgb converts hex color values to rgb arrays on the range 0 to 1. 
% 
% 
% * * * * * * * * * * * * * * * * * * * * 
% SYNTAX:
% rgb = hex2rgb(hex) returns rgb color values in an n x 3 array. Values are
%                    scaled from 0 to 1 by default. 
%                    
% rgb = hex2rgb(hex,256) returns RGB values scaled from 0 to 255. 
% 
% 
% * * * * * * * * * * * * * * * * * * * * 
% EXAMPLES: 
% 
% myrgbvalue = hex2rgb('#334D66')
%    = 0.2000    0.3020    0.4000
% 
% 
% myrgbvalue = hex2rgb('334D66')  % <-the # sign is optional 
%    = 0.2000    0.3020    0.4000
% 
%
% myRGBvalue = hex2rgb('#334D66',256)
%    = 51    77   102
% 
% 
% myhexvalues = ['#334D66';'#8099B3';'#CC9933';'#3333E6'];
% myrgbvalues = hex2rgb(myhexvalues)
%    =   0.2000    0.3020    0.4000
%        0.5020    0.6000    0.7020
%        0.8000    0.6000    0.2000
%        0.2000    0.2000    0.9020
% 
% 
% myhexvalues = ['#334D66';'#8099B3';'#CC9933';'#3333E6'];
% myRGBvalues = hex2rgb(myhexvalues,256)
%    =   51    77   102
%       128   153   179
%       204   153    51
%        51    51   230
% 
% HexValsAsACharacterArray = {'#334D66';'#8099B3';'#CC9933';'#3333E6'}; 
% rgbvals = hex2rgb(HexValsAsACharacterArray)
% 
% * * * * * * * * * * * * * * * * * * * * 
% Chad A. Greene, April 2014
%
% Updated August 2014: Functionality remains exactly the same, but it's a
% little more efficient and more robust. Thanks to Stephen Cobeldick for
% the improvement tips. In this update, the documentation now shows that
% the range may be set to 256. This is more intuitive than the previous
% style, which scaled values from 0 to 255 with range set to 255.  Now you
% can enter 256 or 255 for the range, and the answer will be the same--rgb
% values scaled from 0 to 255. Function now also accepts character arrays
% as input. 
% 
% * * * * * * * * * * * * * * * * * * * * 
% See also rgb2hex, dec2hex, hex2num, and ColorSpec. 
% 
%% Input checks:
assert(nargin>0&nargin<3,'hex2rgb function must have one or two inputs.') 
if nargin==2
    assert(isscalar(range)==1,'Range must be a scalar, either "1" to scale from 0 to 1 or "256" to scale from 0 to 255.')
end
%% Tweak inputs if necessary: 
if iscell(hex)
    assert(isvector(hex)==1,'Unexpected dimensions of input hex values.')
    
    % In case cell array elements are separated by a comma instead of a
    % semicolon, reshape hex:
    if isrow(hex)
        hex = hex'; 
    end
    
    % If input is cell, convert to matrix: 
    hex = cell2mat(hex);
end
if strcmpi(hex(1,1),'#')
    hex(:,1) = [];
end
if nargin == 1
    range = 1; 
end
%% Convert from hex to rgb: 
switch range
    case 1
        rgb = reshape(sscanf(hex.','%2x'),3,[]).'/255;
    case {255,256}
        rgb = reshape(sscanf(hex.','%2x'),3,[]).';
    
    otherwise
        error('Range must be either "1" to scale from 0 to 1 or "256" to scale from 0 to 255.')
end
end

function [ hex ] = rgb2hex(rgb)
% rgb2hex converts rgb color values to hex color format. 
% 
% This function assumes rgb values are in [r g b] format on the 0 to 1
% scale.  If, however, any value r, g, or b exceed 1, the function assumes
% [r g b] are scaled between 0 and 255. 
% 
% * * * * * * * * * * * * * * * * * * * * 
% SYNTAX:
% hex = rgb2hex(rgb) returns the hexadecimal color value of the n x 3 rgb
%                    values. rgb can be an array. 
% 
% * * * * * * * * * * * * * * * * * * * * 
% EXAMPLES: 
% 
% myhexvalue = rgb2hex([0 1 0])
%    = #00FF00
% 
% myhexvalue = rgb2hex([0 255 0])
%    = #00FF00
% 
% myrgbvalues = [.2 .3 .4;
%                .5 .6 .7; 
%                .8 .6 .2;
%                .2 .2 .9];
% myhexvalues = rgb2hex(myrgbvalues) 
%    = #334D66
%      #8099B3
%      #CC9933
%      #3333E6
% 
% * * * * * * * * * * * * * * * * * * * * 
% Chad A. Greene, April 2014
% 
% Updated August 2014: Functionality remains exactly the same, but it's a
% little more efficient and more robust. Thanks to Stephen Cobeldick for
% his suggestions. 
% 
% * * * * * * * * * * * * * * * * * * * * 
% See also hex2rgb, dec2hex, hex2num, and ColorSpec. 
%% Check inputs: 
assert(nargin==1,'This function requires an RGB input.') 
assert(isnumeric(rgb)==1,'Function input must be numeric.') 
sizergb = size(rgb); 
assert(sizergb(2)==3,'rgb value must have three components in the form [r g b].')
assert(max(rgb(:))<=255& min(rgb(:))>=0,'rgb values must be on a scale of 0 to 1 or 0 to 255')
%% If no value in RGB exceeds unity, scale from 0 to 255: 
if max(rgb(:))<=1
    rgb = round(rgb*255); 
else
    rgb = round(rgb); 
end
%% Convert (Thanks to Stephen Cobeldick for this clever, efficient solution):
hex(:,2:7) = reshape(sprintf('%02X',rgb.'),6,[]).'; 
hex(:,1) = '#';
end


