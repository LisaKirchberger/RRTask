%Transfer Images for WF-imaging - Lisa modified from Enny 04/2019

% Path of Transfer target on Server
datapath = '\\NIN518\Imaging\';
topathoptions = {'\\vs02\VandC\MattpRF\Prem','\\vc2nin\WBimaging\pRFData\BilateralClearSkullMice\','\\vc2nin\WBimaging\pRFData\LisaUnilateralClearSkull\','\\vc2nin\WBimaging\pRFData\Sreedeepmice\','\\vs02\VandC\WorkingMemory_EB\PassiveImgOpto\','\\vc2nin\mouse_working_memory\Imaging\','\\vc2nin\WBimaging\Cholinergicsensor','\\vs02\VandC\WorkingMemory_EB\RewardBiasTaskV2\RawData\','\\vs02\VandC\WF_Sreedeep\Sreedeepmice', '\\vc2nin\WBimaging\pRFData\LisaBilateralClearSkull\', '\\vc2nin\Mouse_Plasticity\RawData\'};
[selection,ok] = listdlg('PromptString','Select destination (make sure you''re logged in):',...
    'ListString',topathoptions,'listsize',[350 300]); %#ok<*ASGLU>
topath = topathoptions{selection};
disp(topath)

% Path of Imaging Folder that you want to transfer
frompath = dir(datapath);
[selection,ok] = listdlg('PromptString','Select data to transfer:',...
    'ListString',{frompath(3:end).name},'InitialValue',repmat(1,[1,length(frompath)-2])); %#ok<*RPMT1>


for selidx = 1:length(selection)
    % Select the Sessions you would like to transfer
    tmppath = dir(fullfile(datapath,frompath(2+selection(selidx)).name));
    [selection2,ok] = listdlg('PromptString','Select sessions to transfer:',...
        'ListString', {tmppath(3:end).name},'InitialValue',repmat(1,[1,length(tmppath)-2]));
    mousen = frompath(2+selection(selidx)).name(1:strfind(frompath(2+selection(selidx)).name,'20')-1);
    date = frompath(2+selection(selidx)).name(strfind(frompath(2+selection(selidx)).name,'20'):end);
    
    % Create directory if necessary
    tmpnewloc = [topath mousen '\' mousen date '\'];
    if ~exist(tmpnewloc,'dir')
        mkdir(tmpnewloc)
    end
    
    
    %Loop over Sessions
    for sel2idx = 1:length(selection2)
        
        listtrials = dir([datapath frompath(2+selection(selidx)).name '\' tmppath(2+selection2(sel2idx)).name]);
        listtrials = listtrials(3:end);
        tmpnewloc2 = [tmpnewloc tmppath(2+selection2(sel2idx)).name];
        addpath(genpath([datapath frompath(2+selection(selidx)).name '\' tmppath(2+selection2(sel2idx)).name]))
        cd([datapath frompath(2+selection(selidx)).name '\' tmppath(2+selection2(sel2idx)).name])
        % find the first trial with WF data
        myTrial = find(strcmp({listtrials.name}, [tmppath(2+selection2(sel2idx)).name '_1']));
        tiffiles = dir([listtrials(myTrial).name '\*.tiff']);
        bmpfiles = dir([listtrials(myTrial).name '\*.bmp']);
        
        if ~isempty(bmpfiles)
            flag = 0;
            if flag~=1
                try
                    K = readrawimage(fullfile(listtrials(myTrial).name,bmpfiles(myTrial).name));
                    flag = 2;
                catch ME
                    disp(ME)
                end
            end
            if flag==2 && isa(K,'uint16')
                disp('Raw data, need to downsample it to 16 bit first..')
                downsampleraw
            end
        end
        
        for i = 1:length(listtrials)
            fprintf('Saving trial %.0f from %.0f, session %.0f of %.0f; mouse %s, date %s...\n',i-1,length(listtrials)-1,sel2idx,length(selection2),mousen, date)
            if ~isempty(strfind(listtrials(i).name,'.mat')) % Log file
                tosave = load([datapath frompath(2+selection(selidx)).name '\' tmppath(2+selection2(sel2idx)).name '\' listtrials(i).name]);
                if ~exist(tmpnewloc2,'dir')
                    mkdir(tmpnewloc2)
                end
                copyfile(fullfile(cd,listtrials(i).name),fullfile(tmpnewloc2,listtrials(i).name))
            elseif ~isempty(strfind(listtrials(i).name,'json')) % JSON file
                if ~exist(tmpnewloc2,'dir')
                    mkdir(tmpnewloc2)
                end
                copyfile(fullfile(cd,listtrials(i).name),fullfile(tmpnewloc2,listtrials(i).name))
            elseif ~isempty(strfind(listtrials(i).name,'JPG')) % Brain image
                if ~exist(tmpnewloc2,'dir')
                    mkdir(tmpnewloc2)
                end
                copyfile(fullfile(cd,listtrials(i).name),fullfile(tmpnewloc2,listtrials(i).name))
            else
                tiffiles = dir([listtrials(i).name '\*.tiff']);
                bmpfiles = dir([listtrials(i).name '\*.bmp']);
                if ~isempty(tiffiles)
                    try
                        copyfile(fullfile(cd,listtrials(i).name,'*.tiff'),fullfile(tmpnewloc2,listtrials(i).name))
                    catch ME
                        disp(ME)
                        disp('Please run the line between try and catch again, and then press continue')
                        keyboard
                    end
                    delete(fullfile(cd,listtrials(i).name,'*.bmp'))
                else
                    try
                        copyfile(fullfile(cd,listtrials(i).name,'*.bmp'),fullfile(tmpnewloc2,listtrials(i).name))
                    catch NE
                        disp(NE)
                        disp('Please run the line between try and catch again, and then press continue')
                        keyboard
                    end
                end
                
            end
            
        end
        
        
    end
   
    %movefile([datapath frompath(2+selection(selidx)).name],fullfile(datapath, mousen,frompath(2+selection(selidx)).name))
    
end