
%% Make sure you have all the correct executables
if ~exist('getdbfields.m')
    try
        user_name =getenv('USERNAME');
        tmpname = cd;
        if ~isempty(strfind(tmpname,[user_name '.HERSEN']))
            user_name = regexp(tmpname,'\','split');
            user_name = user_name{3};
        end
        addpath(genpath(fullfile(['C:\Users\' user_name '\Documents\Github'],'OpenAccessStorage')))
        if ~exist('getdbfields.m')
            error('Can not find OpenAccessStorage: https://github.com/VisionandCognition/OpenAccessStorage')
        end
    catch ME
        disp(ME)
        error('Can not find OpenAccessStorage: https://github.com/VisionandCognition/OpenAccessStorage')
    end
end
    
if ~exist('nhi_fyd_VCparms.m') %#ok<*EXIST>
    try
        addpath('Z:\OpenAccessStorageParameters')
        if ~exist('nhi_fyd_VCparms.m')
            error('Cannot locate a nhi_fyd_VCparms.m; please add to path (it is on OpenAccessStorageParameters on the shared folder)')
        end
    catch ME
        disp(ME)
        error('Cannot locate a nhi_fyd_VCparms.m; please add to path (it is on OpenAccessStorageParameters on the shared folder)')
    end
end

%% Fill JSON fields
try
    fields = getdbfields('VC',fields); %retrieves info from mysql tables using a GUI, fill in already.
catch ME
    disp(ME)
    error('Are you sure you have an updated version of the OpenAccessStorage repository?: https://github.com/VisionandCognition/OpenAccessStorage')
end

%% Create JSON file
json = fields;
json.logfile = [expname '.mat']; %name for your logfile
json.version = '1.0';

%% Save JSON File             
try
    savejson('', json, fullfile(SaveDataFolder,[expname '_session.json']));
catch ME
    disp(ME)
    error('Can not store json file properly. Gave correct pathname? E.g. "\\vs02\VandC\[YOURFOLDER]\"')
end