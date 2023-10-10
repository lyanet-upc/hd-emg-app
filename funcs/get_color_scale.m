function [cmax,cmin] = get_color_scale(app)

hd_emg_data = app.UIFigure.UserData.hd_emg_data;
ws = app.UIFigure.UserData.ws;

% initial values
cmax = -inf; cmin = inf;

for i = 1:5
    array_data = hd_emg_data{i};
    for j = 1:length(array_data{1})/ws+1 %forward o backward
        locs = (1:ws)+ws*(j-1);
        locs = locs(locs<=length(array_data{1}));
        z = (cell2mat(cellfun(@(x) rms(x(locs)), array_data,'Un',0)));
        cmax = max(cmax, prctile(z(:),95)); % to avoid outliers
        cmin = min(cmin,prctile(z(:),5));
    end
end

%-----------------------------------------------------------------------
% stores color limits in user data variable
%-----------------------------------------------------------------------
app.UIFigure.UserData.cmax = cmax;
app.UIFigure.UserData.cmin = cmin;
            
end