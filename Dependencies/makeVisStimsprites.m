% makeVisStimsprites

%% Uniform Sprites
Luminances = [Par.blacklum Par.whitelum Par.greylum];
counter = 1;
for l = 1:length(Luminances)
    for c = [0 1]
        cogentGrating = makeUniformFullScreen(Luminances(l),c,Par.FigSize,gammaconversion);
        cgmakesprite(counter,Par.Screenx,Par.Screeny,Par.grey)
        cgsetsprite(counter)
        cgloadarray(counter,Par.Screenx,Par.Screeny,cogentGrating)
        cgtrncol(counter,'r')
        cgsetsprite(0)
        counter = counter+1;
    end
end


%% Grating Sprites
Orientations = [Par.GoFigOrient, Par.GoBgOrient, Par.NoGoFigOrient, Par.NoGoBgOrient];
for o = 1:length(Orientations) 
    if mod(o,2)
        c=0; % uniform
    else
        c=1; % with hole
    end
    for p = 1:length(Par.PhaseOpt)
        cogentGrating = makeFullScreenGrating(Orientations(o),Par.PhaseOpt(p),c,gammaconversion);
        cgmakesprite(counter,Par.Screenx,Par.Screeny,Par.grey)
        cgsetsprite(counter)
        cgloadarray(counter,Par.Screenx,Par.Screeny,cogentGrating)
        cgtrncol(counter,'r')
        cgsetsprite(0)
        counter = counter+1;
    end
end


%% Sprite Numbers:

% 1 black uniform           (Fig)
% 2 black + hole            (Bg)

% 3 white uniform           (Fig)
% 4 white + hole            (Bg)

% 5 grey uniform            (Fig)
% 6 grey + hole             (Bg)

% 7 GoFigOrient uniform     (Fig)
% 8        (4 Phases)
% 9
% 10
%
% 11 GoBgOrient + hole      (Bg)
% 12       (4 Phases)
% 13
% 14
%
% 15 NoGoFigOrient uniform  (Fig)
% 16       (4 Phases)
% 17
% 18
%
% 19 NoGoBgOrient + hole    (Bg)
% 20       (4 Phases)
% 21
% 22

% 100 extra one for human, a green tick
cgmakesprite(100,Par.Screenx,Par.Screeny,Par.grey)
cgsetsprite(100)
cgpencol(0,1,0)
cgpolygon([-100 0 100 0 ], [0 -150 100 -100])
cgsetsprite(0)
cgmakesprite(101,Par.Screenx,Par.Screeny,Par.grey)
cgsetsprite(101)
cgpencol(1,0,0)
cgfont('Arial',200)
cgtext('x', 0,0)
cgsetsprite(0)
        