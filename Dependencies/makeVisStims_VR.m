switch Log.TaskPhase(Trial)
    
    case 1      % Black/White Figure and Black/White Background
        
        if Log.Trialtype(Trial) == 1
            Log.BgColor(Trial) = Par.blacklum;
            Log.FgColor(Trial) = Par.whitelum;
        else
            Log.BgColor(Trial) = Par.whitelum;
            Log.FgColor(Trial) = Par.blacklum;
            Log.Trialtype(Trial) = 1;
        end
        BGcogentGrating = makeUniformFullScreen(Log.BgColor(Trial),1,gammaconversion); % 1 with circle, 0 without
        FGcogentGrating = makeUniformFullScreen(Log.FgColor(Trial),0,gammaconversion); % 1 with circle, 0 without
        Log.FgPhase(Trial) = NaN;
        Log.BgPhase(Trial) = NaN;
        Log.BgOri(Trial) = NaN;
        Log.FGOri(Trial) = NaN;
        Log.TestStim(Trial) = NaN;
        
        
    case 2    % Go and NoGo Figure-Ground stimuli
        
        if Log.Trialtype(Trial) == 1
            Log.FgOri(Trial) = Par.GoFigOrient;
            Log.BgOri(Trial) = Par.GoBgOrient;
        else
            Log.FgOri(Trial) = Par.NoGoFigOrient;
            Log.BgOri(Trial) = Par.NoGoBgOrient;
        end
        
        Log.FgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
        Log.BgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
        BGcogentGrating = makeFullScreenGrating(Log.BgOri(Trial),Log.BgPhase(Trial),1,gammaconversion); % 1 with circle, 0 without
        FGcogentGrating = makeFullScreenGrating(Log.FgOri(Trial),Log.FgPhase(Trial),0,gammaconversion); % 1 with circle, 0 without
        Log.BgColor(Trial) = NaN;
        Log.FgColor(Trial) = NaN;
        Log.TestStim(Trial) = NaN;
        
    case 3    % Test Stimuli
        
        switch Log.TestStim(Trial)
            case 1
                % Figure with GO grating
                Log.FgOri(Trial) = Par.GoFigOrient;
                Log.FgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
                FGcogentGrating = makeFullScreenGrating(Log.FgOri(Trial),Log.FgPhase(Trial),0,gammaconversion); % 1 with circle, 0 without
                % Grey Background
                Log.BgColor(Trial) = Par.greylum;
                BGcogentGrating = makeUniformFullScreen(Log.BgColor(Trial),1,gammaconversion); % 1 with circle, 0 without
                Log.BgPhase(Trial) = NaN;
                Log.BgOri(Trial) = NaN;
                Log.FgColor(Trial) = NaN;
                
            case 2
                % Grey Figure
                Log.FgColor(Trial) = Par.greylum;
                FGcogentGrating = makeUniformFullScreen(Log.FgColor(Trial),0,gammaconversion); % 1 with circle, 0 without
                % Background with GO grating
                Log.BgOri(Trial) = Par.GoBgOrient;
                Log.BgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
                BGcogentGrating = makeFullScreenGrating(Log.BgOri(Trial),Log.BgPhase(Trial),1,gammaconversion); % 1 with circle, 0 without
                Log.FgPhase(Trial) = NaN;
                Log.FgOri(Trial) = NaN;
                Log.BgColor(Trial) = NaN;
                
            case 3
                % Figure with NOGO grating
                Log.FgOri(Trial) = Par.NoGoFigOrient;
                Log.FgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
                FGcogentGrating = makeFullScreenGrating(Log.FgOri(Trial),Log.FgPhase(Trial),0,gammaconversion); % 1 with circle, 0 without
                % Grey Background
                Log.BgColor(Trial) = Par.greylum;
                BGcogentGrating = makeUniformFullScreen(Log.BgColor(Trial),1,gammaconversion); % 1 with circle, 0 without
                Log.BgPhase(Trial) = NaN;
                Log.BgOri(Trial) = NaN;
                Log.FgColor(Trial) = NaN;
                
            case 4
                % Grey Figure
                Log.FgColor(Trial) = Par.greylum;
                FGcogentGrating = makeUniformFullScreen(Log.FgColor(Trial),0,gammaconversion); % 1 with circle, 0 without
                % Background with NOGO grating
                Log.BgOri(Trial) = Par.NoGoBgOrient;
                Log.BgPhase(Trial) = Par.PhaseOpt(randi(length(Par.PhaseOpt)));
                BGcogentGrating = makeFullScreenGrating(Log.BgOri(Trial),Log.BgPhase(Trial),1,gammaconversion); % 1 with circle, 0 without
                Log.FgPhase(Trial) = NaN;
                Log.FgOri(Trial) = NaN;
                Log.BgColor(Trial) = NaN;
                
        end
        
        
end

% put into sprite 1
cgmakesprite(1,Par.Screenx,Par.Screeny,Par.grey)
cgsetsprite(1)
cgloadarray(12,Par.Screenx,Par.Screeny,BGcogentGrating)
cgtrncol(12,'r')
cgloadarray(11,Par.Screenx,Par.Screeny,FGcogentGrating)
cgdrawsprite(11,0,0)
cgdrawsprite(12,0,0)
cgsetsprite(0)
