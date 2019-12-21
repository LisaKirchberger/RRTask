% checkButton
[kd,kp] = cgkeymap;
if length(find(kp)) >= 1
    if find(kp) == 57
        Button = toc(RunningTimer);
        ButtonVec = [ButtonVec, Button];
    end
    
    % ESCAPE stops experiment and closes window
    if find(kp) == 1
        ESC = 1;
    end
end
% [kd,kp] = cgkeymap;
% if length(find(kp)) == 1
%     if find(kp) == 15
%         Button = toc(RunningTimer);
%         ButtonVec = [ButtonVec, Button]; 
%     end
% end


