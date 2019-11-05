%% EasyOptoDetection Analysis
clear all
close all
clc

%%
Mice = {'Adele', 'Beyonce', 'Celine', 'Dion', 'Eminem', 'Fergie', 'George', 'Harrison'};
Mousechoice = menu('Choose the Mouse',Mice);
Mousename = Mice{Mousechoice};
time_frame_start = datenum(2019,01,01);
time_frame_end = today+1;

LogfileDir = 'Z:\Lisa\FF_FB_Plasticity\Behavior_LOGs\EasyOptoDetection';
MatlabDir = pwd;

cd(LogfileDir)
lognames = dir([Mousename,'*']);
cd(MatlabDir)
dates1 = [lognames.datenum];
same_day = find(diff(dates1)<0.8)+1;
wanted_dates = dates1 >= time_frame_start & dates1 <= time_frame_end;
wanted_lognames = {lognames(wanted_dates).name};
nr_sessions = size(wanted_lognames,2);

for Session = 1:nr_sessions
    
    load([LogfileDir '\' wanted_lognames{Session}])
    
    if ~isfield(Log, 'Contrast') || ~isfield(Log, 'Reactionidx')
        Trialnum(Session) = NaN;
        Response{Session} = [];
        dprime(Session) = NaN;
        LaserColor{Session} = 'unknown';
        continue
    end
    
    if ~isfield(Log, 'LaserColor')
        Log.LaserColor = 'Green';
    end
    Laserpower(Session) = str2double(Log.Laserpower);
    Laserpower_string{Session} = Log.Laserpower;
    LaserColor{Session} = Log.LaserColor;
    Logname{Session} = Log.Logfile_name;
    
    wanted_trials = find(Log.Contrast == 0 & Log.Passives == 0);
    if wanted_trials
        Trialnum(Session) = length(wanted_trials);
        Response{Session} = Log.Reactionidx(wanted_trials);
        dprime(Session) = Calcdprime(Response{Session});
    else
        Trialnum(Session) = NaN;
        Response{Session} = [];
        dprime(Session) = NaN;
    end
    
    clear Log
end



%% plot the learning progress of this mouse
Responses_learning = [];
Contrasts_learning = [];
Trialnum_learning = [];
for Session = 1:nr_sessions
    load([LogfileDir '\' wanted_lognames{Session}])
    if ~isfield(Log, 'Contrast') || ~isfield(Log, 'Reactionidx')
        continue
    end
    wanted_trials = find(Log.Passives == 0 );
    Responses_learning = [Responses_learning Log.Reactionidx(wanted_trials)];
    Contrasts_learning = [Contrasts_learning Log.Contrast(wanted_trials)];
    if sum(Session == same_day)
        Trialnum_learning(end) = Trialnum_learning(end)+length(wanted_trials);
    else
        Trialnum_learning = [Trialnum_learning length(wanted_trials)];
    end
    clear Log
end
Trialnum_learning = cumsum(Trialnum_learning);

%% Calculate the d-prime with sliding window
windowsize = 200;
wanted_Responses = Responses_learning(Contrasts_learning>=0.01);
for i = 1:length(wanted_Responses)
    if i <= windowsize/2
        dprime_learning(i) = Calcdprime(wanted_Responses(1:i+windowsize-1));
    elseif i > length(wanted_Responses)-windowsize
        dprime_learning(i) = Calcdprime(wanted_Responses(i-windowsize/2:end));
    else
        dprime_learning(i) = Calcdprime(wanted_Responses(i-windowsize/2:i+windowsize/2-1));
    end
end

%% plot the dprime until the first time the contrast was 0
try
maxplot = find(Contrasts_learning == 0, 1, 'first')-1;
figure
surface([1:maxplot;1:maxplot],[dprime_learning(1:maxplot);dprime_learning(1:maxplot)],[zeros(size(dprime_learning(1:maxplot)));zeros(size(dprime_learning(1:maxplot)))],[Contrasts_learning(1:maxplot).*100;Contrasts_learning(1:maxplot).*100],'facecol','no','edgecol','interp','linew',2);
c = colorbar;
c.Ticks = unique(Contrasts_learning(1:maxplot).*100);
c.Label.String = 'Contrast';
colormap(flipud(gray))
axis tight
hold on
for i = 1:length(Trialnum_learning)
    plot([Trialnum_learning(i) Trialnum_learning(i)], get(gca, 'YLim'), 'k--')
end
xlim([0 maxplot])
box off
set(gca, 'TickDir', 'out')
plot([0 maxplot],[0 0],'r')
plot([0 maxplot],[1.5 1.5],'g')
xlabel('Trials')
ylabel('dprime')
catch
end






%% look at accuracy at different laser powers
if length(unique(LaserColor)) > 1
    %pick the Color you want to analyse
    usedColors = unique(LaserColor);
    Colorchoice = menu('Choose the Color',usedColors);
    Color = usedColors{Colorchoice};
    %only look at the Sessions with this Laser Color
    PickedSess = strcmp(LaserColor, Color);
    Laserpower = Laserpower(PickedSess);
    Laserpower_string = Laserpower_string(PickedSess);
    LaserColor = LaserColor(PickedSess);
    Trialnum = Trialnum(PickedSess);
    Response = Response(PickedSess);
    dprime = dprime(PickedSess);
    Logname = Logname(PickedSess);
else
    Color = LaserColor{1};
end
%plot in the correct Color
if strcmp(Color, 'Blue')
    plotting_color = [0 0.6 0.9];
elseif strcmp(Color, 'Green')
    plotting_color = [0 0.5 0];
elseif strcmp(Color, 'Red')
    plotting_color = [0.5 0 0];
else
    plotting_color = [0.5 0.5 0.5];
    disp('unknown color')
end

Laserpower(strcmp(Laserpower_string, 'max')) = 400;


%% group all the trials together based on Laserpower

% all the used Laserpowers
usedPowers = unique(Laserpower);

% go through Laserpowers, combine all sessions and calc d-prime
for i = 1:length(usedPowers)
    wanted_sessions = find(Laserpower == usedPowers(i));
    Response_usedPowers{i} = [Response{wanted_sessions}];
    Trialnum_usedPowers(i) = length(Response_usedPowers{i});
    dprime_usedPowers(i) = Calcdprime(Response_usedPowers{i});
end


%% Bootstrap to get Errobars
for i = 1:length(usedPowers)
    %1000 times
    for b = 1:1000
        %pick reactions
        tempResp = [];
        for t = 1:length(Response_usedPowers{i})
            tempResp(t) = Response_usedPowers{i}(randi(length(Response_usedPowers{i}), 1));
        end
        bootstr_dprime(i,b) = Calcdprime(tempResp);
    end
    
end
mean_bootstr_dprime = mean(bootstr_dprime,2);
sem_dprime = std(bootstr_dprime,0,2);

%plot it
figure('Position', [356   800   269   194])
errorbar(usedPowers, mean_bootstr_dprime,sem_dprime, 'o', 'MarkerFaceColor', plotting_color, 'Color', plotting_color)
set(gca, 'xlim', [-0.5 max(usedPowers)+1])
box off
title('Accuracy vs Laser Power')
ylabel('d prime')
xlabel('Laser Power [mW]')

%% fit a logistic function to the Behavior
wanted_powers = ~isnan(dprime_usedPowers);
x = usedPowers(wanted_powers)';
y = round(dprime_usedPowers./max(dprime_usedPowers).*Trialnum_usedPowers);
y(y<0)=0;
y = y(wanted_powers)';
n = Trialnum_usedPowers(wanted_powers)';
paramsFree = [1 0 1 1];  %1: free parameter, 0: fixed parameter
PF = @PAL_Logistic;  %Alternatives: PAL_Gumbel, PAL_Weibull, PAL_CumulativeNormal, PAL_HyperbolicSecant
searchGrid.alpha = [0:.1:5];       % xrange
searchGrid.beta = 0:.1:100;        % slope
searchGrid.gamma = [0:.001:.01];    % chance
searchGrid.lambda = [0:.01:.1];    % lapse
guesslimits = [-0.01 0.01];
lapselimits = [0 0.5];
plotting_xrange = 0.01:.001:max(usedPowers)+1;
plotting_yrange = [min([-0.5 min(dprime_usedPowers)-0.1]) max([2 max(dprime_usedPowers)+0.1])];


[paramsValues] = PAL_PFML_Fit(x,y, ...
    n,searchGrid,paramsFree,PF,'guessLimits', guesslimits,'lapseLimits',lapselimits);
mod = PAL_Logistic(paramsValues,plotting_xrange);

%now put everything back to the unnormalized level
mod_recovered = mod.* max(dprime_usedPowers(wanted_powers));


figure('Position', [65   799   274   188]);
plot(x,dprime_usedPowers(wanted_powers),'o', 'MarkerFaceColor', plotting_color,'MarkerEdgeColor','none')
%hold on;errorbar(x, dprime_usedPowers(wanted_powers),sem_dprime(wanted_powers), 'o', 'MarkerFaceColor', plotting_color)
set(gca, 'XScale', 'log')
set(gca, 'TickDir', 'out')
hold on;
plot(plotting_xrange,mod_recovered, 'Color', plotting_color)
axis tight
ylim(plotting_yrange)
xlim([plotting_xrange(1) plotting_xrange(end)])
box off
ylabel('d-prime')
xlabel('Laser Power [mW]')
xticks([0; x])

fprintf('the threshod is %g \n', paramsValues(1))




%% Control mice: plot when laser light was outside of the brain and then the session afterwards
if sum(strcmp(Mousename, {'Eminem', 'Fergie'}))
    
    plot_ind_data_points = 1;
    min_yrange = [-.5 1];
    % split up in blocks
    Blocksize = 100;
    outResponses = cell2mat(Response(strcmp(Laserpower_string, 'out')));
    dprime_out = [];
    for i = 1:floor(length(outResponses)/Blocksize)
        dprime_out(i) = Calcdprime(outResponses((i-1)*Blocksize+1:(i-1)*Blocksize+Blocksize));
    end
    
    maxResponses = cell2mat(Response(strcmp(Laserpower_string, 'max')));
    if isempty(maxResponses)
        maxResponses = cell2mat(Response(Laserpower == max(Laserpower)));
        
    end
    dprime_max = [];
    for i = 1:floor(length(maxResponses)/Blocksize)
        dprime_max(i) = Calcdprime(maxResponses((i-1)*Blocksize+1:(i-1)*Blocksize+Blocksize));
    end
    
    % Take Blocks and Calculate performance that way
    figure('Position', [29   274   193   321])
    errorbar(1 , mean(dprime_out), std(dprime_out)/sqrt(length(dprime_out)) , 'Color','k' )
    hold on
    errorbar(2, mean(dprime_max), std(dprime_max)/sqrt(length(dprime_max)) , 'Color','k' )
    bar([1 2], [mean(dprime_out) mean(dprime_max)], 'FaceColor',plotting_color , 'EdgeColor', 'none' )
    if plot_ind_data_points
        plot(1,dprime_out, 'k*', 'MarkerSize', 5)
        plot(2,dprime_max, 'k*', 'MarkerSize', 5)
    end
    box off
    xticks([1 2 ])
    set(gca, 'TickDir', 'out')
    xticklabels({'out', 'max'})
    YRange = get(gca, 'YLim');
    ylim([min([YRange(1) min_yrange(1)]) max([YRange(2) min_yrange(2)])])
    ylabel('d-prime')
    title(sprintf('Blocksize = %i',Blocksize))
    
    % Plot it by Sessions
    figure('Position', [240   272   193   321])
    if sum(strcmp(Laserpower_string, 'max'))
        errorbar(1 , mean(dprime(strcmp(Laserpower_string, 'out'))), std(dprime(strcmp(Laserpower_string, 'out')))/sqrt(length(dprime(strcmp(Laserpower_string, 'out')))) , 'Color','k' )
        hold on
        errorbar(2, mean(dprime(strcmp(Laserpower_string, 'max'))), std(dprime(strcmp(Laserpower_string, 'max')))/sqrt(length(dprime(strcmp(Laserpower_string, 'max')))) , 'Color','k' )
        bar([1 2], [mean(dprime(strcmp(Laserpower_string, 'out'))) mean(dprime(strcmp(Laserpower_string, 'max')))], 'FaceColor',plotting_color , 'EdgeColor', 'none' )
        if plot_ind_data_points
            plot(1,dprime(strcmp(Laserpower_string, 'out')), 'k*', 'MarkerSize', 5)
            plot(2,dprime(strcmp(Laserpower_string, 'max')), 'k*', 'MarkerSize', 5)
        end
    else
        hold off
        errorbar(1 , mean(dprime(strcmp(Laserpower_string, 'out'))), std(dprime(strcmp(Laserpower_string, 'out')))/sqrt(length(dprime(strcmp(Laserpower_string, 'out')))) , 'Color','k' )
        hold on
        errorbar(2, mean(dprime(Laserpower == max(Laserpower))), std(dprime(Laserpower == max(Laserpower)))/sqrt(length(dprime(Laserpower == max(Laserpower)))) , 'Color','k' )
        bar([1 2], [mean(dprime(strcmp(Laserpower_string, 'out'))) mean(dprime(Laserpower == max(Laserpower)))], 'FaceColor',plotting_color , 'EdgeColor', 'none' )
        if plot_ind_data_points
            plot(1,dprime(strcmp(Laserpower_string, 'out')), 'k*', 'MarkerSize', 5)
            plot(2,dprime(Laserpower == max(Laserpower)), 'k*', 'MarkerSize', 5)
        end
    end
    box off
    set(gca, 'TickDir', 'out')
    xticks([1 2])
    xticklabels({'out', 'max'})
    YRange = get(gca, 'YLim');
    ylim([min([YRange(1) min_yrange(1)]) max([YRange(2) min_yrange(2)])])
    ylabel('d-prime')
    title('Sessions')
    
    
    % also plot the 'learning progress' (which isn't there) for the max sessions
    windowsize = 50;
    for i = 1:length(maxResponses)
        if i <= windowsize/2
            dprime_max_all(i) = Calcdprime(maxResponses(1:i+windowsize-1));
        elseif i > length(maxResponses)-windowsize
            dprime_max_all(i) = Calcdprime(maxResponses(i-windowsize/2:end));
        else
            dprime_max_all(i) = Calcdprime(maxResponses(i-windowsize/2:i+windowsize/2-1));
        end
    end
    Trialnum_max = cumsum(Trialnum(strcmp(Laserpower_string, 'max')));
    figure('Position', [873   315   312   221])
    plot(dprime_max_all, 'Color', plotting_color)
    ylim([min([-0.5 min(dprime_max_all)]) max([2 max(dprime_max_all)])])
    hold on
    %for i = 1:length(Trialnum_max)
    %    plot([Trialnum_max(i) Trialnum_max(i)], get(gca, 'YLim'), 'k--')
    %end
    box off
    set(gca, 'TickDir', 'out')
    plot([0 length(dprime_max_all)],[0 0],'r')
    plot([0 length(dprime_max_all)],[1.5 1.5],'g')
    xlabel('Trials')
    ylabel('dprime')
    
    nomaskResponses = cell2mat(Response(strcmp(Laserpower_string, 'max, no mask')));
    dprime_nomask = [];
    for i = 1:floor(length(nomaskResponses)/Blocksize)
        dprime_nomask(i) = Calcdprime(nomaskResponses((i-1)*Blocksize+1:(i-1)*Blocksize+Blocksize));
    end
    
    % plot by intervals of Blocksize
    figure('Position', [451   271   193   321])
    errorbar(1 , mean(dprime_nomask), std(dprime_nomask)/sqrt(length(dprime_nomask)) , 'Color','k' )
    hold on
    errorbar(2, mean(dprime_max), std(dprime_max)/sqrt(length(dprime_max)) , 'Color','k' )
    bar([1 2], [mean(dprime_nomask) mean(dprime_max)], 'FaceColor',plotting_color , 'EdgeColor', 'none' )
    if plot_ind_data_points
        plot(1,dprime_nomask, 'k*', 'MarkerSize', 5)
        plot(2,dprime_max, 'k*', 'MarkerSize', 5)
    end
    box off
    set(gca, 'TickDir', 'out')
    xticks([1 2])
    xticklabels({'no mask', 'max'})
    YRange = get(gca, 'YLim');
    ylim([min([YRange(1) min_yrange(1)]) max([YRange(2) min_yrange(2)])])
    ylabel('d-prime')
    title(sprintf('Blocksize = %i',Blocksize))
    
    
    % plot by Sessions
    figure('Position', [661   273   193   321])
    if sum(strcmp(Laserpower_string, 'max'))
        errorbar(1 , mean(dprime(strcmp(Laserpower_string, 'max, no mask'))), std(dprime(strcmp(Laserpower_string, 'max, no mask')))/sqrt(length(dprime(strcmp(Laserpower_string, 'max, no mask')))) , 'Color','k' )
        hold on
        errorbar(2, mean(dprime(strcmp(Laserpower_string, 'max'))), std(dprime(strcmp(Laserpower_string, 'max')))/sqrt(length(dprime(strcmp(Laserpower_string, 'max')))) , 'Color','k' )
        bar([1 2], [mean(dprime(strcmp(Laserpower_string, 'max, no mask'))) mean(dprime(strcmp(Laserpower_string, 'max')))], 'FaceColor',plotting_color , 'EdgeColor', 'none' )
        if plot_ind_data_points
            plot(1,dprime(strcmp(Laserpower_string, 'max, no mask')), 'k.', 'MarkerSize', 10)
            plot(2,dprime(strcmp(Laserpower_string, 'max')), 'k.', 'MarkerSize', 10)
        end
    else
        hold off
        errorbar(1 , mean(dprime(strcmp(Laserpower_string, 'max, no mask'))), std(dprime(strcmp(Laserpower_string, 'max, no mask')))/sqrt(length(dprime(strcmp(Laserpower_string, 'max, no mask')))) , 'Color','k' )
        hold on
        errorbar(2, mean(dprime(Laserpower == max(Laserpower))), std(dprime(Laserpower == max(Laserpower)))/sqrt(length(dprime(Laserpower == max(Laserpower)))) , 'Color','k' )
        bar([1 2], [mean(dprime(strcmp(Laserpower_string, 'max, no mask'))) mean(dprime(Laserpower == max(Laserpower)))], 'FaceColor',plotting_color , 'EdgeColor', 'none' )
        if plot_ind_data_points
            plot(1,dprime(strcmp(Laserpower_string, 'max, no mask')), 'k*', 'MarkerSize', 5)
            plot(2,dprime(Laserpower == max(Laserpower)), 'k*', 'MarkerSize', 5)
        end
    end
    box off
    set(gca, 'TickDir', 'out')
    xticks([1 2])
    xticklabels({'no mask', 'max'})
    YRange = get(gca, 'YLim');
    ylim([min([YRange(1) min_yrange(1)]) max([YRange(2) min_yrange(2)])])
    ylabel('d-prime')
    title('Sessions')
    
    
    %% plot the Fit for the continuous mask
    
    % identify the continuous mask sessions
    contmask_sess = find(~cellfun(@isempty, strfind(Laserpower_string, 'continuous mask')));
    % get the Laserpower of these sessions
    Laserpower_contmask = cellfun(@str2num, cellfun(@(x)regexp(x, '\d?\.?\d+','Match'), Laserpower_string(contmask_sess)));
    
    
    % all the used Laserpowers
    usedPowers_contmask = unique(Laserpower_contmask);
    
    % go through Laserpowers, combine all sessions and calc d-prime
    for i = 1:length(usedPowers_contmask)
        wanted_sessions = find(Laserpower_contmask == usedPowers_contmask(i));
        Response_usedPowers_contmask{i} = [Response{contmask_sess(wanted_sessions)}]; %#ok<SAGROW>
        Trialnum_usedPowers_contmask(i) = length(Response_usedPowers_contmask{i}); %#ok<SAGROW>
        dprime_usedPowers_contmask(i) = Calcdprime(Response_usedPowers_contmask{i}); %#ok<SAGROW>
    end
    
    x = usedPowers_contmask;
    y = round(dprime_usedPowers_contmask./max(dprime_usedPowers_contmask).*Trialnum_usedPowers_contmask);
    y(y<0)=0;
    n = Trialnum_usedPowers_contmask;
    searchGrid.alpha = [0:1:100];       % xrange
    [paramsValues_contmask] = PAL_PFML_Fit(x,y, ...
        n,searchGrid,paramsFree,PF,'guessLimits', guesslimits,'lapseLimits',lapselimits);
    mod_contmask = PAL_Logistic(paramsValues_contmask,plotting_xrange);
    
    %now put everything back to the unnormalized level
    mod_recovered_contmask = mod_contmask.* max(dprime_usedPowers_contmask);

    figure('Position', [1199         391         274         193]);
    plot(x,dprime_usedPowers_contmask,'o', 'MarkerFaceColor', plotting_color,'MarkerEdgeColor','none')
    set(gca, 'XScale', 'log')
    set(gca, 'TickDir', 'out')
    hold on;
    plot(plotting_xrange,mod_recovered_contmask, 'Color', plotting_color)
    axis tight
    ylim([min([min(plotting_yrange) min(dprime_usedPowers_contmask)]) max([max(plotting_yrange) max(dprime_usedPowers_contmask)])] )
    xlim([plotting_xrange(1) plotting_xrange(end)])
    box off
    ylabel('d-prime')
    xlabel('Laser Power [mW]')
    xticks([0 x])
    title('continuous mask')
    
    fprintf('the threshod is %g when using a continuous mask\n', paramsValues_contmask(1))
    
    
    
    %% plot the Fit for the other mask
    
    % identify the continuous mask sessions
    othermask_sess = find(~cellfun(@isempty, strfind(Laserpower_string, 'other mask')));
    % get the Laserpower of these sessions
    Laserpower_othermask = cellfun(@str2num, cellfun(@(x)regexp(x, '\d?\.?\d+','Match'), Laserpower_string(othermask_sess)));

    % all the used Laserpowers
    usedPowers_othermask = unique(Laserpower_othermask);
    
    % go through Laserpowers, combine all sessions and calc d-prime
    for i = 1:length(usedPowers_othermask)
        wanted_sessions = find(Laserpower_othermask == usedPowers_othermask(i));
        Response_usedPowers_othermask{i} = [Response{othermask_sess(wanted_sessions)}]; %#ok<SAGROW>
        Trialnum_usedPowers_othermask(i) = length(Response_usedPowers_othermask{i}); %#ok<SAGROW>
        dprime_usedPowers_othermask(i) = Calcdprime(Response_usedPowers_othermask{i}); %#ok<SAGROW>
    end
    
    x = usedPowers_othermask;
    y = round(dprime_usedPowers_othermask./max(dprime_usedPowers_othermask).*Trialnum_usedPowers_othermask);
    y(y<0)=0;
    n = Trialnum_usedPowers_othermask;
    searchGrid.alpha = [0:1:100];       % xrange
    [paramsValues_othermask] = PAL_PFML_Fit(x,y, ...
        n,searchGrid,paramsFree,PF,'guessLimits', guesslimits,'lapseLimits',lapselimits);
    mod_othermask = PAL_Logistic(paramsValues_othermask,plotting_xrange);
    
    %now put everything back to the unnormalized level
    mod_recovered_othermask = mod_othermask.* max(dprime_usedPowers_othermask);

    figure('Position', [1487         391         274         193]);
    plot(x,dprime_usedPowers_othermask,'o', 'MarkerFaceColor', plotting_color,'MarkerEdgeColor','none')
    set(gca, 'XScale', 'log')
    set(gca, 'TickDir', 'out')
    hold on;
    plot(plotting_xrange,mod_recovered_othermask, 'Color', plotting_color)
    axis tight
    ylim([min([min(plotting_yrange) min(dprime_usedPowers_othermask)]) max([max(plotting_yrange) max(dprime_usedPowers_othermask)])] )
    xlim([plotting_xrange(1) plotting_xrange(end)])
    box off
    ylabel('d-prime')
    xlabel('Laser Power [mW]')
    xticks([0 x])
    title('other mask')
    
    fprintf('the threshod is %g when using the other mask\n', paramsValues_othermask(1))
    
    
end