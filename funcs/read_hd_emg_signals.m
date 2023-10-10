function  hd_emg_data = read_hd_emg_signals(app,varargin)

directory = app.UIFigure.UserData.directory;
subjects  = app.UIFigure.UserData.subjects;
channels  = app.UIFigure.UserData.nchannels;

% -------------------------------------------------------------------------
% subject to plot
% -------------------------------------------------------------------------
loc      = app.SubjectDropDown.Value;
subject  = subjects{loc};
channels = structfun(@(x) (x(loc,:)),channels,'Un',0);

% -------------------------------------------------------------------------
% Task
% -------------------------------------------------------------------------
switch app.TaskDropDown.Value
    case 1 % 'Supination'
        TaskID = 's';
    case 2 %'Pronation'
        TaskID = 'p';
    case 3 %'Flexion'
        TaskID = 'f';
    case 4 %'Extension'
        TaskID = 'e';
end

% -------------------------------------------------------------------------
% Effort level
% -------------------------------------------------------------------------
switch app.EffortlevelDropDown.Value
    case 1 %'10% MVC'
        EffortID = '10';
    case 2 %'30% MVC'
        EffortID = '30';
    case 3 %'50% MVC'
        EffortID = '50';
end

% -------------------------------------------------------------------------
% Reads the hd_emg signals for the task and effort level above.
% -------------------------------------------------------------------------
muscle_array = {'forearm','forearm','forearm','biceps','triceps'};
muscle_name  = {'anconeus','brachio','pronator','biceps','triceps'};
muscle_id    = {'fa','fa','fa','bb','tb'};

hd_emg_data = cell(size(muscle_array));

for h = 1:length(muscle_array)
    
    % array channels
    a_channels = channels.(muscle_array{h})(1):channels.(muscle_array{h})(2);
    % muscle channels
    m_channels = channels.(muscle_name{h})(1):channels.(muscle_name{h})(2);
    
    % defines the array
    % rows and cols
    if strcmp(muscle_array{h},'forearm')
        nrows = 6;
    else
        nrows = 8;
    end
    ncols = ceil(numel(a_channels)./nrows);
    array_data = cell(nrows,ncols); % (medial to lateral, proximal to distal)
    
    % reads emg data
    filename = fullfile(directory,subject,muscle_array{h},[subject,'_',TaskID,EffortID,'_',muscle_id{h},'.bin']);
    try
        fileID   = fopen(filename);
        emg_data = fread(fileID,[numel(a_channels),inf],'double'); % channels x samples
    catch ME
        errordlg(ME.message,"Problems loading data")
        return
    end
    
    
    k = 1;
    for j = 1:ncols
        for i = 1:nrows % first rows
            if k <= numel(a_channels) && ismember(k,m_channels)
                array_data{i,j} = emg_data(k,:);
            else
                array_data{i,j} = nan(size(emg_data(1,:))); % for empty channels
            end
            k = k+1;
        end
    end
    
    hd_emg_data{h} = array_data;    
end

%-----------------------------------------------------------------------
% stores signals in user data variable
%-----------------------------------------------------------------------
app.UIFigure.UserData.hd_emg_data = hd_emg_data;

end

