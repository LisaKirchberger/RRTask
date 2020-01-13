% makeVisStimsprites_vs2

if Par.FigSide == 1 %right
    Par.FigX = Par.ScreenAngleCoverage/4;
    Par.FigY = 0;
elseif Par.FigSide == 2 %left
    Par.FigX = -Par.ScreenAngleCoverage/4;
    Par.FigY = 0;
end

%% Uniform Sprites 1-5
Luminances = [Par.greylum Par.greylum Par.greylum Par.blacklum Par.blacklum Par.whitelum Par.whitelum];
cutouts = [0 1 3 1 3 1 3]; % 0 uniform, 1 red circular hole, 3 blue square (2 is blue circular hole)
counter = 1;
for i = 1:length(Luminances)
    c = cutouts(i);
    cogentGrating = makeUniformFullScreen(Luminances(i),c,Par.FigSize,gammaconversion);
    cgmakesprite(counter,Par.Screenx,Par.Screeny,Par.grey)
    cgsetsprite(counter)
    cgloadarray(counter,Par.Screenx,Par.Screeny,cogentGrating)
    if c == 1
        cgtrncol(counter,'r')
    elseif c == 3
        cgtrncol(counter,'b')
    end
    cgsetsprite(0)
    counter = counter + 1;
end

%% Grating Sprites
Orientations = [Par.GoFigOrient, Par.GoFigOrient, Par.GoUniOrient, Par.NoGoFigOrient, Par.NoGoFigOrient, Par.NoGoUniOrient];
cutouts = [0 1 3 0 1 3]; % 0 uniform, 1 red circular hole, 3 blue square (2 is blue circular hole)
for o = 1:length(Orientations) 
    c = cutouts(o);
    for p = 1:length(Par.PhaseOpt)
        cogentGrating = makeFullScreenGrating(Orientations(o),Par.PhaseOpt(p),c,gammaconversion);
        cgmakesprite(counter,Par.Screenx,Par.Screeny,Par.grey)
        cgsetsprite(counter)
        cgloadarray(counter,Par.Screenx,Par.Screeny,cogentGrating)
        if c == 1
            cgtrncol(counter,'r')
        elseif c == 3
            cgtrncol(counter,'b')
        end
        cgsetsprite(0)
        counter = counter + 1;
    end
end

CorrespPhase = [3 4 1 2];


%% Sprite Numbers:

% 1 grey uniform            (Fig1)
% 2 grey + red circle       (Fig2)
% 3 grey + blue square      (Uni)
% 4 black + red circle      (Fig2)
% 5 black + blue square     (Uni)
% 6 white + red circle      (Fig2)
% 7 white + blue square     (Uni)

% 8 GoFigOrient uniform             (Fig1)
% 9        (4 Phases)
% 10
% 11

% 12 GoFigOrient + red circle       (Fig2)
% 13       (4 Phases)
% 14
% 15

% 16 GoUniOrient + blue square      (Uni)
% 17       (4 Phases)
% 18
% 19

% 20 NoGoFigOrient uniform          (Fig1)
% 21       (4 Phases)
% 22
% 23

% 24 NoGoFigOrient + red circle    (Fig2)
% 25       (4 Phases)
% 26
% 27

% 28 NoGoUniOrient + blue square   (Uni)
% 29       (4 Phases)
% 30
% 31