%% EasyOptoDetection Analysis
clear all
close all
clc

%% Load the file
Mice = {'Adele', 'Beyonce', 'Celine', 'Dion', 'Eminem', 'Fergie'};
Mousechoice = menu('Choose the Mouse',Mice);
Mousename = Mice{Mousechoice};
ExpNrs = {'1 Day', 'All Days'};
ExpNr = menu('Choose the experiments', ExpNrs); % 1 = 1 day, 2 = all days
LogfileDir = 'Z:\Lisa\FF_FB_Plasticity\Behavior_LOGs\EasyOptoDetection';
MatlabDir = pwd;
cd(LogfileDir)
if ExpNr == 1
    Filename{1}= uigetfile([Mousename '*']);
else
    Filename_temp = dir([Mousename,'*']);
    for i = 1:length(Filename_temp)
        Filename{i} = [LogfileDir '\' Filename_temp(i).name];
    end
end


for Session = 1:length(Filename)
    
    load(Filename{Session})
    cd(MatlabDir)
    
    wanted_trials = find(Log.Passives == 0);
    dprime = Calcdprime(Log.Reactionidx(wanted_trials));
    
    %% plot the Licks on Opto vs no Opto trials Opto + Visual Stim
    
    dprime_vis = Calcdprime(Log.Reactionidx(Log.Passives == 0 &  Log.Contrast > 0));
    Gotrials = find(Log.Trialtype == 1 & Log.Contrast > 0 & Log.Passives == 0);
    NoGotrials = find(Log.Trialtype == 0 & Log.Contrast > 0 & Log.Passives == 0);
    xlimits = [-500 1500];
    patchlimits = [0 xlimits(2)];
    
    figure('Position', [ 195   443   357   288])
    patch([patchlimits(1) patchlimits(2) patchlimits(2) patchlimits(1)], [0 0 length(Gotrials)+0.5 length(Gotrials)+0.5], 'k', 'FaceAlpha', 0.5, 'EdgeColor', 'none')
    hold on
    for i = 1:length(Gotrials)
        if ~isempty(Log.LickVec{Gotrials(i)})
            plot(Log.LickVec{Gotrials(i)},i, 'k.', 'Markersize', 5)
        end
    end
    for i = length(Gotrials)+1 :length(Gotrials)+length(NoGotrials)
        if ~isempty(Log.LickVec{NoGotrials(i-length(Gotrials))})
            plot(Log.LickVec{NoGotrials(i-length(Gotrials))},i, 'k.', 'Markersize', 5)
        end
    end
    plot([0 0], [0 length(Gotrials)+length(NoGotrials)], 'k-')
    xlim(xlimits)
    ylim([0 length(Gotrials)+length(NoGotrials)+0.5])
    set(gca, 'YDir', 'reverse')
    set(gca, 'TickDir', 'out')
    xlabel('Time [ms]')
    ylabel('Trial')
    if ExpNr == 2
        title([Log.Mouse ' ' Log.Date ' B' Log.Expnum ', Laserpower ' Log.Laserpower])
    else
        title('All Licks')
    end
    
    %% only plot first lick
    figure('Position', [599   438   357   288])
    patch([patchlimits(1) patchlimits(2) patchlimits(2) patchlimits(1)], [0 0 length(Gotrials)+0.5 length(Gotrials)+0.5], 'k', 'FaceAlpha', 0.5, 'EdgeColor', 'none')
    hold on
    for i = 1:length(Gotrials)
        if ~isempty(Log.LickVec{Gotrials(i)}(find(Log.LickVec{Gotrials(i)}>200,1,'first')))
            plot(Log.LickVec{Gotrials(i)}(find(Log.LickVec{Gotrials(i)}>200,1,'first')),i, 'k.', 'Markersize', 5)
        end
    end
    for i = length(Gotrials)+1 :length(Gotrials)+length(NoGotrials)
        if ~isempty(Log.LickVec{NoGotrials(i-length(Gotrials))}(find(Log.LickVec{NoGotrials(i-length(Gotrials))}>200,1,'first')))
            plot(Log.LickVec{NoGotrials(i-length(Gotrials))}(find(Log.LickVec{NoGotrials(i-length(Gotrials))}>200,1,'first')),i, 'k.', 'Markersize', 5)
        end
    end
    plot([0 0], [0 length(Gotrials)+length(NoGotrials)], 'k-')
    xlim(xlimits)
    ylim([0 length(Gotrials)+length(NoGotrials)+0.5])
    set(gca, 'YDir', 'reverse')
    set(gca, 'TickDir', 'out')
    xlabel('Time [ms]')
    ylabel('Trial')
    if ExpNr == 2
        title([Log.Mouse ' ' Log.Date ' B' Log.Expnum ', Laserpower ' Log.Laserpower])
    else
        title('First Lick')
    end
    
    
    
    
     %% plot the Licks on Opto only trials (no visual stimulus)
    
    dprime_opto = Calcdprime(Log.Reactionidx(Log.Passives == 0 &  Log.Contrast == 0)); 
    Gotrials = find(Log.Trialtype == 1 & Log.Contrast == 0 & Log.Passives == 0);
    NoGotrials = find(Log.Trialtype == 0 & Log.Contrast == 0 & Log.Passives == 0);
    xlimits = [-500 1500];
    
    figure('Position', [199   819   357   288])
    patch([patchlimits(1) patchlimits(2) patchlimits(2) patchlimits(1)], [0 0 length(Gotrials)+0.5 length(Gotrials)+0.5], 'c', 'FaceAlpha', 0.5, 'EdgeColor', 'none')
    hold on
    for i = 1:length(Gotrials)
        if ~isempty(Log.LickVec{Gotrials(i)})
            plot(Log.LickVec{Gotrials(i)},i, 'k.', 'Markersize', 5)
        end
    end
    for i = length(Gotrials)+1 :length(Gotrials)+length(NoGotrials)
        if ~isempty(Log.LickVec{NoGotrials(i-length(Gotrials))})
            plot(Log.LickVec{NoGotrials(i-length(Gotrials))},i, 'k.', 'Markersize', 5)
        end
    end
    plot([0 0], [0 length(Gotrials)+length(NoGotrials)], 'k-')
    xlim(xlimits)
    ylim([0 length(Gotrials)+length(NoGotrials)+0.5])
    set(gca, 'YDir', 'reverse')
    set(gca, 'TickDir', 'out')
    xlabel('Time [ms]')
    ylabel('Trial')
    if ExpNr == 2
        title([Log.Mouse ' ' Log.Date ' B' Log.Expnum ', Laserpower ' Log.Laserpower])
    else
        title('All Licks')
    end
    
    %% only plot first lick
    figure('Position', [602   819   357   288])
    patch([patchlimits(1) patchlimits(2) patchlimits(2) patchlimits(1)], [0 0 length(Gotrials)+0.5 length(Gotrials)+0.5], 'c', 'FaceAlpha', 0.5, 'EdgeColor', 'none')
    hold on
    for i = 1:length(Gotrials)
        if ~isempty(Log.LickVec{Gotrials(i)}(find(Log.LickVec{Gotrials(i)}>200,1,'first')))
            plot(Log.LickVec{Gotrials(i)}(find(Log.LickVec{Gotrials(i)}>200,1,'first')),i, 'k.', 'Markersize', 5)
        end
    end
    for i = length(Gotrials)+1 :length(Gotrials)+length(NoGotrials)
        if ~isempty(Log.LickVec{NoGotrials(i-length(Gotrials))}(find(Log.LickVec{NoGotrials(i-length(Gotrials))}>200,1,'first')))
            plot(Log.LickVec{NoGotrials(i-length(Gotrials))}(find(Log.LickVec{NoGotrials(i-length(Gotrials))}>200,1,'first')),i, 'k.', 'Markersize', 5)
        end
    end
    plot([0 0], [0 length(Gotrials)+length(NoGotrials)], 'k-')
    xlim(xlimits)
    ylim([0 length(Gotrials)+length(NoGotrials)+0.5])
    set(gca, 'YDir', 'reverse')
    set(gca, 'TickDir', 'out')
    xlabel('Time [ms]')
    ylabel('Trial')
    if ExpNr == 2
        title([Log.Mouse ' ' Log.Date ' B' Log.Expnum ', Laserpower ' Log.Laserpower])
    else
        title('First Lick')
    end
    
    
end
%%


%
% cd(LogfileDir)
% uiopen
% lognames = dir([Mousename,'*']);
% cd(MatlabDir)
% dates1 = [lognames.datenum];
% wanted_dates = dates1 >= time_frame_start & dates1 <= time_frame_end;
% wanted_lognames = {lognames(wanted_dates).name};
% nr_sessions = size(wanted_lognames,2);
%
% for Session = 1:nr_sessions
%
%     load([LogfileDir '\' wanted_lognames{Session}])
%     Laserpower(Session) = str2double(Log.Laserpower);
%
%     wanted_trials = find(Log.Contrast == 0 & Log.Passives == 0);
%     Trialnum(Session) = length(wanted_trials);
%     HitCounter = sum(Log.Reactionidx(wanted_trials) == 1);
%     CRCounter = sum(Log.Reactionidx(wanted_trials) == 2);
%     FACounter = sum(Log.Reactionidx(wanted_trials) == -1);
%     MissCounter = sum(Log.Reactionidx(wanted_trials) == 0);
%     Hitrate = HitCounter / (HitCounter + MissCounter);
%     FArate = FACounter / (FACounter + CRCounter);
%     if Hitrate == 0
%         Hitrate = 0.01;
%     elseif Hitrate == 1
%         Hitrate = 0.99;
%     elseif FArate == 0
%         FArate = 0.01;
%     elseif FArate == 1
%         FArate = 0.99;
%     end
%     dprime(Session) = norminv(Hitrate) - norminv(FArate);
%     clear Log
% end
%
%
% figure
% plot(Laserpower, dprime, 'o', 'MarkerFaceColor', 'b')
% set(gca, 'xdir', 'reverse' )
% set(gca, 'xlim', [0 6])
% box off
% title('Accuracy vs Laser Power')
% ylabel('d prime')
% xlabel('Laser Power [mW]')
%
%
%
% %% manual
% load('Z:\Lisa\FF_FB_Plasticity\Behavior_LOGs\EasyOptoDetection\Adele_20190326_B1.mat')
% figure
% Trial = size(Log.Contrast,2);
% plot(Log.dprime)
% hold on
% plot(1:Trial,zeros(Trial,1),'r')
% plot(1:Trial,repmat(1.5,Trial,1),'g')
% title('performance')
% ylabel('d prime')
% xlabel('trials')
% axis([1 inf -inf inf])
% box off
% Contrastplot = (Log.Contrast > 0)-2.5;
% plot(1:Trial, Contrastplot, 'k')
%
