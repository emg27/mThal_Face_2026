function [axObj,axLim] = matchAxis(graphObj,varargin)
%% Match the axis limits of multiple axis and figures
% Enables you to automatically match the axis limits of different figures
% and axes.

% Optional arguments
setLimits = [];
viewRot = [];
scale = 1;
setX = 1;
setY = 1;
setZ = 1;
setR = 1;
equalAx = 0;
setTheta = 1;

assignopts(who, varargin);

% Iterate through the different graph objects
nObj = length(graphObj(:));
axLim = struct('xLim',[],'yLim',[],'zLim',[],'rLim',[],'thetaLim',[]); % Collect all the axis limits
axObj = []; % Collect a list of the relevant axis
for n = 1:nObj
    tempLim = struct('xLim',[],'yLim',[],'zLim',[],'rLim',[],'thetaLim',[]);
    
    % Check if the input object is a figure or an axis
    if ismember(graphObj(n).Type,'figure') % If the graphic object is a
        %figure, recursively call the function on its children objects in
        %order to find all the axes objects and axis limits.
        [childAx,childLim] = matchAxis(graphObj(n).Children,...
            'setLimits',setLimits,'viewRot',viewRot,varargin{:});
        axLim = [axLim; childLim];
        axObj = [axObj; childAx];
    elseif ismember(graphObj(n).Type,'axes')
        tempLim.xLim = graphObj(n).XLim;
        tempLim.yLim = graphObj(n).YLim;
        tempLim.zLim = graphObj(n).ZLim;
        axLim = [axLim; tempLim];
        axObj = [axObj; graphObj(n)];
    elseif ismember(graphObj(n).Type,'polaraxes')
        tempLim.thetaLim = graphObj(n).ThetaLim;
        tempLim.RLim = graphObj(n).RLim;
        axLim = [axLim; tempLim];
        axObj = [axObj; graphObj(n)];
    end
end

% Set the axes limits, if setLimit is empty than automatically find the max
% and min axes.
if isempty(setLimits)
    setLimits = struct('xLim',[],'yLim',[],'zLim',[],'rLim',[],...
        'thetaLim',[]);
    setLimits.xLim = [min([axLim.xLim]) max([axLim.xLim])];
    setLimits.yLim = [min([axLim.yLim]) max([axLim.yLim])];
    setLimits.zLim = [min([axLim.zLim]) max([axLim.zLim])];
    setLimits.rLim = [min([axLim.rLim]) max([axLim.rLim])];
    setLimits.thetaLim = [min([axLim.thetaLim]) max([axLim.thetaLim])];
    
end

% Make the axis square
if equalAx
    [dist idx] = max([diff(setLimits.xLim),diff(setLimits.yLim),...
        diff(setLimits.zLim)]);
    dist = 0.5*dist;
    
    setLimits.xLim = mean(setLimits.xLim) + [-dist dist];
    setLimits.yLim = mean(setLimits.yLim) + [-dist dist];
    setLimits.zLim = mean(setLimits.zLim) + [-dist dist];
end

for n = 1:length(axObj)
    if ismember(axObj(n).Type,'axes')
        if setX
            axObj(n).XLim = setLimits.xLim;
        end
        if setY
            axObj(n).YLim = setLimits.yLim;
        end
        if setZ
            axObj(n).ZLim = setLimits.zLim;
        end
    elseif ismember(axObj(n).type,'polaraxes')
        if setTheta
            axObj(n).ThetaLim = setLimits.thetaLim;
        end
        if setR
            axObj(n).RLim = setLimits.rLim;
        end
    end
    
    % Set the view point
    if ~isempty(viewRot)
        axObj(n).View = viewRot;
    end
end
end