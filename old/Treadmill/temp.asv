
[window, rect]=Screen('OpenWindow',0);

dur=1; 

Screen('FrameOval',window,[127],[200 200 400 400]) 
Screen('Flip',window)
WaitSecs(dur)

Screen('FillOval',window,[127],[200 200 400 400])
Screen('Flip',window)
WaitSecs(dur)

Screen('FrameRect',window,[127],[200 200 400 400])
Screen('Flip',window)
WaitSecs(dur)

Screen('FillRect',window,[127],[200 200 400 400])
Screen('Flip',window)
WaitSecs(dur)

Screen('DrawLine',window,[127],200,200, 400, 400)
Screen('Flip',window)
WaitSecs(dur)

Screen('DrawLines',window,[200 300 300 400 400 500; 300 300 400 400 500 600],2, [255 8 89])
Screen('Flip',window)
WaitSecs(dur)

Screen('DrawArc',window,[127],[200 200 400 400],23,200)
Screen('Flip',window)
WaitSecs(dur)
Screen('FillArc',window,[127],[200 200 400 400],23,56)
Screen('Flip',window)
WaitSecs(dur)

Screen('FillPoly',window,rand(3,1)*255,[200 300 300 400 400 500; 300 300 400 400 500 600]')
Screen('Flip',window)
WaitSecs(dur)

Screen('FramePoly',window,rand(3,1)*255,[200 300 300 400 400 500; 300 300 400 400 500 600]')
Screen('Flip',window)
WaitSecs(dur)

% Note with text there are a lot of formatting options!
Screen('TextFont',window, 'Courier');
Screen('TextSize',window, 30);
Screen('TextStyle', window, 0);
Screen('DrawText', window, 'Here is one way to draw text', 100, 300, rand(3,1)*255);
DrawFormattedText(window,'Here is another','center','center',[255 0 255]);
Screen('Flip',window)
WaitSecs(dur)

%Note with Textures you need to first make them and then draw them.
IM1=rand(100,100,3)*255;
IM2= imread('T.png', 'png');
    tex(1) = Screen('MakeTexture', window, IM1);
    tex(2) = Screen('MakeTexture', window, IM2);
        Screen('DrawTextures', window, tex([1 2 1 2]), [], [100 100 400 400; 400 350 550 500; 600 600 800 800; 100 500 200 550]', rand(4,1)*360);
                Screen('DrawTexture', window, tex(2), []);
Screen('Flip',window)
WaitSecs(dur)

Screen('CloseAll');
