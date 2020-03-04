% plotRunning
hold(runningplot, 'off')
PlotColors = {[0 1 0], [0 1 1], [1 0.5 0.3], [1 0 0]};


% Plot the Running timecourse of the last 10 trials
for t = Trial : -1 : Trial-10
    if t < 1
        continue
    end
    
    if Log.Reactionidx(t) == 1                 % Hit
        plot(runningplot, Log.RunningTiming{t}, Log.RunningVec{t}, '-', 'Color', PlotColors{1}, 'LineWidth', 0.5);
    elseif Log.Reactionidx(t) == 2             % Correct Rejection
        plot(runningplot, Log.RunningTiming{t}, Log.RunningVec{t}, '-', 'Color', PlotColors{2}, 'LineWidth', 0.5);
    elseif Log.Reactionidx(t) == 0             % Miss
        plot(runningplot, Log.RunningTiming{t}, Log.RunningVec{t}, '-', 'Color', PlotColors{3}, 'LineWidth', 0.5);
    elseif Log.Reactionidx(t) == -1            % False Alarm
        plot(runningplot, Log.RunningTiming{t}, Log.RunningVec{t}, '-', 'Color', PlotColors{4}, 'LineWidth', 0.5);
    end
    hold(runningplot, 'on')
end

% calculate the average running timecourse per condition
wanted_xdatapoints = -2:0.1:1.5; % in seconds from 2 s before stim to 1.5 after
if Par.RecordRunning
    RunningTimecourseTrial(Trial,:) = interp1(Log.RunningTiming{Trial}, Log.RunningVec{Trial}, wanted_xdatapoints);
else
    RunningTimecourseTrial(Trial,:) = NaN;
end



counter = 0;
for i = [1 2 0 -1]
    counter = counter + 1;
    wanted_trials = find(Log.Reactionidx == i);
    RunningTimecourseAVG(counter,:) = nanmean(RunningTimecourseTrial(wanted_trials,:),1);    %#ok<SAGROW>
end


for i = 4:-1:1
    % plot the average timecourse
    plot(runningplot, wanted_xdatapoints, RunningTimecourseAVG(i,:), '-', 'Color', PlotColors{i}, 'LineWidth', 2);
end

% make plot more pretty
axis(runningplot, [-1 1.5 -10 40])
box(runningplot, 'off')


