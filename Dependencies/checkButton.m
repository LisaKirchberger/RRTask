% checkButton

[kd,kp] = cgkeymap;
if length(find(kp)) == 1
    if find(kp) == 15
        Button = toc(RunningTimer);
        ButtonVec = [ButtonVec, Button]; 
    end
end


