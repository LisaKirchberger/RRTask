%% copy all files for Pilot Protocol NIN19.18.01
clear all
clc

% Saving location
Save_Location = fullfile('Z:\Lisa\FF_FB_Plasticity\Behavior_LOGs\EasyOptoDetection');
Copy_Location = fullfile('D:\Dropbox\19.18.01 Behavior Pilot\Logs');
Matlabpath = pwd;
Log.Mouse = 'Test';
addpath('D:\GitHub\EasyOptoDetection\Dependencies')
run checkMouse

% for each Mouse that was part of this study go through Log files and copy the missing ones
myMice = correctNames191801;

for mouseNum = 1:size(myMice,2)
    
    currMouse = char(myMice(mouseNum));
    % all already backed up files
    cd(Copy_Location)
    lognames_saved = dir([currMouse '*']);
    lognames_saved = {lognames_saved.name};
    
    % copy only the not yet backed up files
    cd(Save_Location)
    lognames_all = dir([currMouse '*']);
    lognames_all = {lognames_all.name};
    missing_files = lognames_all(~ismember(lognames_all, lognames_saved));
    for i = 1 : length(missing_files)
        copyfile(missing_files{i}, Copy_Location)
    end
    
    cd(Matlabpath)
    
    disp('done')
end


%% copy all files for Pilot Protocol NIN19.18.03
clear all
clc

% Saving location
Save_Location = fullfile('Z:\Lisa\FF_FB_Plasticity\Behavior_LOGs\EasyOptoDetection');
Copy_Location = fullfile('D:\Dropbox\19.18.03 FF Plasticity\Logfiles');
Matlabpath = pwd;
Log.Mouse = 'Test';
addpath('D:\GitHub\EasyOptoDetection\Dependencies')
run checkMouse

% for each Mouse that was part of this study go through Log files and copy the missing ones
myMice = correctNames191803;

for mouseNum = 1:size(myMice,2)
    
    currMouse = char(myMice(mouseNum));
    % all already backed up files
    cd(Copy_Location)
    lognames_saved = dir([currMouse '*']);
    lognames_saved = {lognames_saved.name};
    
    % copy only the not yet backed up files
    cd(Save_Location)
    lognames_all = dir([currMouse '*']);
    lognames_all = {lognames_all.name};
    missing_files = lognames_all(~ismember(lognames_all, lognames_saved));
    for i = 1 : length(missing_files)
        copyfile(missing_files{i}, Copy_Location, 'f')
    end
    
    cd(Matlabpath)
    
    disp('done')
end
