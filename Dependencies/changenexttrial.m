function changenexttrial(src,event, Nexttrial, value)

if value == 1
    set(Nexttrial, 'string', 'Go')
elseif value == 2
    set(Nexttrial, 'string', 'No Go')
end

end