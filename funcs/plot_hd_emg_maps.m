function plot_hd_emg_maps(app)

counter     = app.UIFigure.UserData.counter; 
hd_emg_data = app.UIFigure.UserData.hd_emg_data;
cmax        = app.UIFigure.UserData.cmax;
cmin        = app.UIFigure.UserData.cmin; 

% activation maps
fs = 2048; % samples per second
ws = round(fs*app.WindowsizeSlider.Value); %forward o backward
locs = (1:ws)+ws*counter;
locs = locs(locs>=1); % upper than 1
locs = locs(locs<=length(hd_emg_data{1}{1})); % lower than signal length

if ~isempty(locs)
    
    arrayfun(@(i) delete(get(app.UIAxes{i},'Children')),1:length(app.UIAxes),'Un',0);
    
    type_of_plot = app.ButtonGroup.SelectedObject.String;
    
    for i = 1:length(hd_emg_data)
        
        array_data = hd_emg_data{i};
        
        nrows = size(array_data,1);
        ncols = size(array_data,2);        
        [x,y] = meshgrid(1:ncols,1:nrows); % x --> cols, y --> rows
        z = cell2mat(cellfun(@(x) rms(x(locs)), array_data,'Un',0));

        [Xinterp,Yinterp] = meshgrid(1:0.1:ncols,1:0.1:nrows); 
        F = scatteredInterpolant(x(:),y(:),z(:));
        Zinterp = F(Xinterp,Yinterp);

        switch type_of_plot
            case 'Contour'
                [~,s] = contour(app.UIAxes{i},Xinterp,Yinterp,Zinterp,'color',0.85*[1 1 1],'fill','on','levelstep',(cmax-cmin)/10);
            case 'Surface'
                s = imagesc(app.UIAxes{i}, unique(Xinterp),unique(Yinterp),Zinterp,[cmin cmax]);%'LineStyle','none','facealpha',0.75);
            case 'Surface + Contour'
                s = surfc(app.UIAxes{i}, Xinterp,Yinterp,Zinterp,'LineStyle','none','facealpha',0.75);
                s = s(1);
        end         
        s.UIContextMenu = app.UIAxes{i}.UIContextMenu;
        
        if app.ShowChannelsCheckBox.Value
            plot3(app.UIAxes{i},x,y,z-0.25,'ko','MarkerSize',4,'MarkerFaceColor',0*[1 1 1],'MarkerEdgeColor','none');
        end

        view(app.UIAxes{i},[0 -90]),
        colormap(app.UIAxes{i},jet)
        caxis(app.UIAxes{i},[cmin,cmax])
        if i == 5
            colorbar('peer',app.UIAxes{i})
        end
       
        XLim = [find(sum(~isnan(z),1)~=0,1,'first'),find(sum(~isnan(z),1)~=0,1,'last')]; % cols
        YLim = [find(sum(~isnan(z),2)~=0,1,'first'),find(sum(~isnan(z),2)~=0,1,'last')]; % rows
        xlim(app.UIAxes{i},XLim),
        ylim(app.UIAxes{i},YLim)
       
    end
    
end


