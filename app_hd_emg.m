
classdef app_hd_emg < matlab.apps.AppBase
    
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   
        LoadDataBaseButton        
        SubjectDropDown            
        TaskDropDown               
        EffortlevelDropDown        
        WindowsizeSlider  
        WindowsizeLabel       
        UIAxes_ts                  
        UIAxes                     
        UIPatch_ts
        UILines_ts
        UIAxesMenu
        ShowChannelsCheckBox
        ButtonGroup
        RadioButtons
        BackwardButton             
        FordwardButton             
    end
    
    methods (Access = private)
        
        % Button pushed function: LoadDataBaseButton
        function LoadDataBaseButtonPushed(app,varargin)
            
            % Loads data base
            directory = uigetdir();
            listing   = dir(directory);
            folders   = arrayfun(@(i) listing(i).name, 1:length(listing),'Un',0);
            locs      = cell2mat(arrayfun(@(i) listing(i).isdir, 1:length(listing),'Un',0));
            folders   = folders(locs);
            subjects  = folders(contains(folders,{'s1','s2','s3','s4','s5','s6','s7','s8','s9','s10','s11','s12'}));
            
            if isempty(subjects)
                errordlg(sprintf('You should load a valid data base\nNo subject data was found'))
            else
                
                % subjects and channels
                try
                    fid = fopen(fullfile(directory,'nchannels.txt'));
                    data = textscan(fid,['%s',repmat('%.0f',1,3)],'HeaderLines',1);
                    fclose(fid);
                    
                    locs = find(contains(data{1},subjects)); % subjects
                    channels.biceps  = [ones(size(locs)) data{2}(locs)]; % biceps channels >> from the first one to the last one
                    channels.triceps = [ones(size(locs)) data{3}(locs)]; % triceps channels
                    channels.forearm = [ones(size(locs)) data{4}(locs)]; % forearm channels
                catch ME
                    errordlg(ME.message,'Problems loading nchannels.txt file')
                    return
                end
                
                try
                    % forearm channels
                    fid = fopen(fullfile(directory,'forearm.txt'));
                    data = textscan(fid,['%s',repmat('%.0f',1,6)],'HeaderLines',2);
                    fclose(fid);
                    
                    channels.anconeus = [data{2}(locs) data{3}(locs)]; % first and last electrode >> anconeus
                    channels.brachio  = [data{4}(locs) data{5}(locs)]; % first and last electrode >> brachio radialis
                    channels.pronator = [data{6}(locs) data{7}(locs)]; % first and last electrode >> pronator teres
                    
                catch ME
                    errordlg(ME.message,'Problems loading the forearm.txt file'),
                    return
                end
                
                app.SubjectDropDown.String = upper(subjects);
                
                % enables all disabled uicontrols
                set(findobj('Enable','off'),'Enable','on')
                
                ws = 0.25; fs = 2048;
                
                app.WindowsizeSlider.Value = ws;
                
                app.UIFigure.UserData.directory = directory;
                app.UIFigure.UserData.subjects  = subjects;
                app.UIFigure.UserData.nchannels = channels;
                app.UIFigure.UserData.counter = 0;
                app.UIFigure.UserData.fs = fs;
                app.UIFigure.UserData.ws = round(fs*ws); % fs*ws(time)
                
                plot_activation_maps(app)
                
            end
        end
        
        function plot_activation_maps(app,varargin)
            
            
            read_hd_emg_signals(app); % output: hd_emg_data
            
            get_color_scale(app); % output: cmin and cmax
            
            plot_temporary_signals(app)
            
            plot_hd_emg_maps(app);
            
        end
        
        function WindowsizeSliderFun(app,varargin)
            fs = 2048;
            ws = app.WindowsizeSlider.Value;
            counter = app.UIFigure.UserData.counter;
            app.UIPatch_ts.XData = [0 1 1 0]*ws + counter*ws;
            
            app.UIFigure.UserData.ws = round(fs*ws); % fs*ws(time)
            
            get_color_scale(app); % output: cmin and cmax
            plot_hd_emg_maps(app);
            app.WindowsizeLabel.String = ['Window size: ',num2str(ws,'%0.2fs')];
        end
        
        function update_hd_emg_maps(app,varargin)
            plot_hd_emg_maps(app);
        end
        
        function BackwardButtonFun(app,varargin)
            counter = app.UIFigure.UserData.counter;
            if counter ~= 0
                counter = max(0,counter-1);
                ws = app.WindowsizeSlider.Value; % in seconds
                app.UIPatch_ts.XData = [0 1 1 0]*ws + counter*ws;
                app.UIFigure.UserData.counter = counter;
                plot_hd_emg_maps(app);
            else
                beep
            end
        end
        
        function FordwardButtonFun(app,varargin)
            counter = app.UIFigure.UserData.counter;
            long_data = numel(app.UIFigure.UserData.hd_emg_data{1}{1});
            window_size = app.UIFigure.UserData.ws;
            if counter ~= long_data/window_size - 1
                counter = min(long_data/window_size,counter+1);
                ws = app.WindowsizeSlider.Value; % in seconds
                app.UIPatch_ts.XData = [0 1 1 0]*ws + counter*ws;
                app.UIFigure.UserData.counter = counter;
                plot_hd_emg_maps(app);
            else
                beep
            end
        end
        
        function plot_temporary_signals(app,varargin)
            
            if isempty(varargin)
                source = findobj(app.UIAxesMenu{1},'Tag','allchannels');
                muscle_name = 'Anconeus';
            else
                source = varargin{1};
                muscle_name = varargin{3};
            end
            
            % updates check state
            set(findobj('Tag','allchannels'),'Checked','off');
            set(source,'Checked','on');
                        
            loc = strcmp(muscle_name,{'Anconeus','Brachio Radials','Pronator Teres','Biceps','Triceps'});
            
            hd_emg_data = app.UIFigure.UserData.hd_emg_data{loc};
            
            % temporary signals
            % delete(app.UIAxes_ts.Children);
            fs = 2048;
            arrayfun(@(i) set(app.UILines_ts(i),'XData',[],'YData',[]),1:numel(hd_emg_data),'Un',0); % reset data
            
            arrayfun(@(i) set(app.UILines_ts(i),...
                'XData',(0:1:(size(hd_emg_data{i},2)-1))/fs,...
                'YData',hd_emg_data{i}),1:numel(hd_emg_data),'Un',0); % plot new data values
            
            minval = min(cell2mat(get(app.UILines_ts,'YData')'));
            maxval = max(cell2mat(get(app.UILines_ts,'YData')'));
            range_val = maxval-minval;
            app.UIAxes_ts.YLim = [minval-0.1*range_val maxval+0.1*range_val];
            title(app.UIAxes_ts,muscle_name)
            
        end
        
        
        
    end
       
    
    
    % App initialization and construction
    methods (Access = private)
        
        % Create UIFigure and components
        function createComponents(app)
            
            % Create UIFigure
            app.UIFigure = figure(...
                'Name','UI Figure',...
                'Position',[100 100 1209 867],...
                'Resize','on',...
                'NumberTitle','off',...
                'HandleVisibility','callback',...
                'ToolBar','auto',...
                'MenuBar','figure',...
                'Tag',mfilename,...
                'Visible','on');
            
            
            % Create LoadDataBaseButton
            app.LoadDataBaseButton = uicontrol(app.UIFigure,...
                'Style','push',...
                'Position',[40 820 180 30],...
                'String','Load Data Base',...
                'FontWeight','Normal',...
                'FontSize',10,...
                'Callback',@app.LoadDataBaseButtonPushed,...
                'Enable','on');
            
            % Create SubjectDropDown
            % label
            uicontrol(...
                'Parent',app.UIFigure,...
                'Style','Text',...
                'String','Subject:',...
                'HorizontalAlignment','right',...
                'FontSize',9,...
                'Position',[40 771 70 22]);
            % uicontrol
            app.SubjectDropDown = uicontrol(app.UIFigure,...
                'Style','popup',...
                'Position',[120 776 100 22],...
                'String',{'S1', 'S2', 'S3', 'S4'},...
                'FontWeight','Normal',...
                'FontSize',9,...
                'Callback',@app.plot_activation_maps,...
                'Enable','off');
            
            % Create TaskDropDown
            % label
            uicontrol(...
                'Parent',app.UIFigure,...
                'Style','Text',...
                'String','Task:',...
                'HorizontalAlignment','right',...
                'FontSize',9,...
                'Position',[40 726 70 22]);
            % uicontrol
            app.TaskDropDown = uicontrol(app.UIFigure,...
                'Style','popup',...
                'Position',[120 731 100 22],...
                'String',{'Supination', 'Pronation', 'Flexion', 'Extension'},...
                'FontWeight','Normal',...
                'FontSize',9,...
                'Callback',@app.plot_activation_maps,...
                'Enable','off');
            
            % Create EffortlevelDropDown
            % label
            uicontrol(...
                'Parent',app.UIFigure,...
                'Style','Text',...
                'String','Effort level:',...
                'HorizontalAlignment','right',...
                'FontSize',9,...
                'Position',[40 681 70 22]);
            % uicontrol
            app.EffortlevelDropDown = uicontrol(app.UIFigure,...
                'Style','popup',...
                'Position',[120 686 100 22],...
                'String',{'10% MVC', '30% MVC', '50% MVC'},...
                'FontWeight','Normal',...
                'FontSize',9,...
                'Callback',@app.plot_activation_maps,...
                'Enable','off');
            
            % Create Windowsizes Edit Field
            % label
            app.WindowsizeLabel  = uicontrol(...
                'Parent',app.UIFigure,...
                'Style','text',...
                'String','Window size: 0.25s',...
                'HorizontalAlignment','left',...
                'FontSize',9,...
                'FontWeight','Normal',...
                'Position',[40 636 180 22]);
            % uicontrol
            app.WindowsizeSlider = uicontrol(app.UIFigure,...
                'Style','slider',...
                'Backgroundcolor',[1 1 1],...
                'Position',[40 620 180 18],...
                'FontWeight','Normal',...
                'FontSize',9,...
                'Min',0.25,...
                'Max',2,...
                'SliderStep',[1/(2/0.25-1) 1/(2/0.25-1)],...
                'Value',0.25,...
                'Callback',@app.WindowsizeSliderFun,...
                'Enable','off');
            
             % Create MapsettingButtonGroup
             app.ButtonGroup = uibuttongroup(app.UIFigure,...
                 'Title','HD-EMG maps',...
                 'FontWeight','Normal',...
                 'FontSize',10,...
                 'Units','Pixels',...
                 'Position',[40 475 180 120],...
                 'SelectionChangedFcn',@app.update_hd_emg_maps);
             
             String = {'Contour','Surface','Surface + Contour'};
             Value = [false false true];
             
             for i = 1:3
                 app.RadioButtons{i} = uicontrol(app.ButtonGroup,...
                     'Style','radiobutton',...
                     'String',String{i},...
                     'FontSize',9,...
                     'Units','Normalized',...
                     'Position',[0.05 0.70-0.25*(i-1) 0.90 0.15],...
                     'Value',Value(i),...
                     'Enable','off');
             end
            
             % Create show channels checkbox
             app.ShowChannelsCheckBox = uicontrol(app.UIFigure,...
                 'Style','CheckBox',...
                 'String','Show channels',...
                 'Value',1,...
                 'Enable','on',...
                 'HorizontalAlignment','left',...
                 'FontSize',9,...
                 'FontWeight','normal',...
                 'Units','Pixels',...
                 'Position',[40 450 180 22],...
                 'Callback',@app.update_hd_emg_maps,...
                 'Enable','off');
            
            % Create BackwardButton
            app.BackwardButton = uicontrol(app.UIFigure,...
                'Style','push',...
                'Position',[30 26 95 30],...
                'String','<< Backward',...
                'FontWeight','Normal',...
                'FontSize',9,...
                'Callback',@app.BackwardButtonFun,...
                'Enable','off');
            
            % Create FordwardButton
            app.FordwardButton = uicontrol(app.UIFigure,...
                'Style','push',...
                'Position',[140 26 95 30],...
                'String','Fordward >>',...
                'FontWeight','Normal',...
                'FontSize',9,...
                'Callback',@app.FordwardButtonFun,...
                'Enable','off');
            
            
            % Create UIAxes >> Temporal signals
            app.UIAxes_ts = axes(app.UIFigure,...
                'FontSize',8,...
                'Box','off',...
                'XGrid','on',...
                'YGrid','on',...
                'XLim',[0 10],...
                'YLim',[-4 4],...
                'NextPlot','add',...
                'Units','Pixels',...
                'Position',[300 725 875 125]);
            title(app.UIAxes_ts, 'Biceps')
            xlabel(app.UIAxes_ts, 'time (s)')
            ylabel(app.UIAxes_ts, 'Amplitude (uV)')
                       
            % Creates lines to see temporary signals
            Color = get(app.UIAxes_ts,'ColorOrder');
            for i = 1:120
                app.UILines_ts(i) = line(app.UIAxes_ts,...
                    'XData',[],...
                    'YData',[],...
                    'Color',Color(rem(i,size(Color,1)-1)+1,:));
            end
            
             % patch to see the temporary window
            app.UIPatch_ts = patch(app.UIAxes_ts,...
                'XData',[0 0.25 0.25 0],...
                'YData',[-10 -10 10 10],...
                'FaceColor',[1 0 1],...
                'EdgeColor',[1 0 1],...
                'FaceAlpha',0.15);
            
            % Create UIAxes >> Activation maps
            musclesName = {'Anconeus','Brachio Radials','Pronator Teres','Biceps','Triceps'};
            for i = 1:length(musclesName)
                switch musclesName{i}
                    case 'Anconeus'
                        pos = [300 380 260 280];
                    case 'Brachio Radials'
                        pos = [608 380 260 280];
                    case 'Pronator Teres'
                        pos = [915 380 260 280]; % end: 891+280
                    case 'Biceps'
                        pos = [300 50 415 280];
                    case 'Triceps'
                        pos = [760 50 415 280];
                end
                
                app.UIAxes{i}= axes(app.UIFigure,...
                    'FontSize',8,...
                    'Box','off',...
                    'XGrid','off',...
                    'YGrid','off',...
                    'XLim',[0 10],...
                    'YLim',[-4 4],...
                    'Units','Pixels',...
                    'NextPlot','add',...
                    'Position',pos);
                
                title(app.UIAxes{i},musclesName{i})
                xlabel(app.UIAxes{i},'medial to lateral')
                ylabel(app.UIAxes{i}, 'proximal to distal')
                
                % creates a context menu for axes above >> to see temporary signals
                app.UIAxesMenu{i} = uicontextmenu(app.UIFigure);
                % Create child menu of the uicontextmenu
                topmenu = uimenu('Parent',app.UIAxesMenu{i},'Label','View Temporary Signals');
                % Create submenu items
                uimenu('Parent',topmenu,'Label','all channels','Tag','allchannels','Callback',{@app.plot_temporary_signals,musclesName{i}});
                uimenu('Parent',topmenu,'Label','select channels','enable','off','Callback',@app.plot_temporary_signals);
                set(app.UIAxes{i},'UIContextMenu',app.UIAxesMenu{i})
            end
            
            fig_elements = get(app.UIFigure,'Children');
            for i = 1:length(fig_elements)
                try                     %#ok<TRYNC>
                    set(fig_elements(i),'Units','Normalized')
                end
            end
            
        end
    end
    
    methods (Access = public)
        
        % Construct app
        function app = app_hd_emg
            
            % Create the UI if one does not already exist.
            % Bring the UI to the front if one already exist
            h = findall(0,'Tag',mfilename);
            
            if isempty(h)
                % Create and configure components
                addpath('funcs'), 
                createComponents(app)
            else
                % Bring it to the front
                figure(app)
                % close(h)
                % createComponents(app)
            end
            
        end
        
        % Code that executes before app deletion
        function delete(app)            
            % Delete UIFigure when app is deleted
            % rmpath('funcs')
            delete(app.UIFigure)
        end
    end
end