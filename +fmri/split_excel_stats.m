function split_excel_stats(fName, hdrRow, outFName, subjCol, varargin)
% SPLIT_EXCEL_STATS
%
%
% ## Example:
%
% import fmri.split_excel_stats;
% split_excel_stats('+fmri/+test/test.xlsx', 1, 'test_<?subj>_<?set>.txt', 'subject', ...
%   'stat1', {'stat2', 'stat3'});
%
% split_excel_stats('ssmd_fmri_behav_auob.xlsx', ...
%   3, 'ssmd_<?subj>_fmri_behav_auob_<?set>.txt', 'subject', 'even_onset', 'odd_onset', ...
%   'even_correct_onset', 'odd_correct_onset', 'error_onset', ...
%   'noresp_onset', 'error+noresp_onset');
%
% See also: fmri


import misc.safefid;
import mperl.file.spec.*;
import mperl.join;


[~, ~, raw] = xlsread(fName);

raw = raw(hdrRow:end,:);

header = raw(1,:);

isNaN = cellfun(@(x) isnumeric(x) & all(isnan(x)), header);
header(isNaN) = repmat({''}, 1, numel(find(isNaN)));

header   = lower(header);
varargin = cellfun(@(x) lower(x), varargin, 'UniformOutput', false);

for i = 1:numel(varargin),
    if ischar(varargin{i}),
        varargin{i} = varargin(i);
    end
end

[fPath, name] = fileparts(fName);

raw = raw(2:end,:);

subjIDs = raw(:, find(ismember(header, subjCol), 2, 'first'));

if isnumeric(subjIDs{1}),
    subjIDs = cellfun(@(x) num2str(x), subjIDs, 'UniformOutput', false);
end

uSubjIDs = unique(subjIDs);

if isempty(uSubjIDs),
    error('No subject IDs');
end

if isnumeric(uSubjIDs{1}),
    uSubjIDs = cellfun(@(x) num2str(x), uSubjIDs, 'UniformOutput', false);
end



for subjItr = 1:numel(uSubjIDs),
    % Iterate across subjects
    
    isCurrSubj = cellfun(@(x) all(x == uSubjIDs{subjItr}), subjIDs);
    
    subjData  = raw(isCurrSubj, :);
    
    for i = 1:numel(varargin)
        % Iterate across column groups
        
        
        [isFound, loc] = ismember(header, varargin{i});
        loc = loc(isFound);
        
        
        if ~any(isFound), continue; end
        
        [~, order] = sort(loc, 'ascend');
        
        colNames = header(isFound);
        colNames = colNames(order);
        colNames = cellfun(@(x) regexprep(x, '[^\w]+', '-'), colNames, ...
            'UniformOutput', false);
        
        data = subjData(:, isFound);
        data = data(:, order);
        
%         % Convert all NaNs (missing values) to the empty string
%         isNaN = cellfun(@(x) isnan(x), data(:));
%         data(isNaN) = repmat({''}, numel(find(isNaN)), 1);
        
        % Convert all numbers to strings
        isNumeric = cellfun(@(x) isnumeric(x) & ~all(isnan(x)), data(:));
        data(isNumeric) = cellfun(@(x) num2str(x), data(isNumeric), ...
            'UniformOutput', false);
        
        % Columns width for nice formatting
        formatStr = cell(1, numel(colNames));
        for j = 1:numel(colNames)
            colWidth = max(cellfun(@(x) numel(x), data(:,j)));
            formatStr{j} = ['%-' num2str(colWidth+1) 's'];
        end
        
        groupName = join('-', colNames);
        thisName  = strrep(outFName, '<?subj>', uSubjIDs{subjItr});
        thisName  = strrep(thisName, '<?set>', groupName);
        thisFName = catfile(fPath, thisName);
        
        % If a single column, remove all empty values
        % Quick and dirty fix. Think something better... maybe
        if size(data,2) == 1,
            isNaN = cellfun(@(x) isnumeric(x) && isnan(x), data);
            data(isNaN) = [];
            isEmpty = cellfun(@(x) isempty(x), data);
            data(isEmpty) = [];
        end
        
        if isempty(data),
            continue; 
        end
        
        fid = safefid(thisFName, 'w');
        
        
        for j = 1:size(data,1)
            
            thisRow = data(j,:);
            
            for k = 1:numel(thisRow),                
                fprintf(fid, formatStr{k}, thisRow{k});
            end
            fprintf(fid, '\n');
            
        end
        
    end
    
    
end





end