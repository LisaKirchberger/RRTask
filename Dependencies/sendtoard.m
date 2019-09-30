function sendtoard(com, message)

resp = 'n';
fprintf(com, message);
n = 1;
while ~strcmp(resp, 'D')
    if com.BytesAvailable
        resp = fscanf(com, '%s');
    end
    to = tic;
    while strcmp(resp,'W') && toc(to) < 0.2 %In case of W, keep looping until no W
        if com.BytesAvailable
            resp = fscanf(com,'%s');
        end
    end
    
    n = n+1;
    pause(0.001)
    if n > 30
        if ~strcmp(resp,'W') %Only send again when there's no W of waiting
            fprintf(com, message)
        end
        n = 1;
        disp(['Trouble sending ', message ' , trying again']);
    end
end

end