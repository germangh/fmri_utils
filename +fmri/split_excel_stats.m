function split_excel_stats(fName, hdrRow, outFName, subjCol, varargin)
% SPLIT_EXCEL_STATS - Split Excel stats into various text files
%
% split_excel_stats(fName, hdrRow, outFName, subjCol, colGroup1, ...
%       colGroup2, colGroup3, ...)
%
% Where
%
% FNAME is the name of the input Excel file
%
% HDRROW is the index of the row in the Excel spreadsheed that corresponds
% to the stats table header. 
%
% OUTFNAME is a string that specifies the naming of the generated text
% files. The sub-strings '<?subj>' and '<?set>' will be replaced by the
% corresponding subject ID and column group name in order to produce the
% actual file name. The column group name is obtained by simply
% concatenating the names of the columns included in certain column group.
%
% SUBJCOL is the name of the column that contains the subject IDs.
% Typically this will be something like 'subject'
%
% COLGROUPi is the column group specification for the ith group. COLGROUPi
% is either a string (if the column group contains a single column) or a
% cell array of strings. In the latter case, the cell array contains the
% names of all the columns included in the group. For instance, use
% COLGROUP = {'even_onset', 'odd_onset'} to generate text files that
% contain, for a given subject, two columns. The first containing the
% values of the even_onset stat, and the second the values for the
% odd_onset stat.
%
%
% ## Examples:
%
% % There is a sample Excel file included with this package. Place yourself
% % on the directory where sub-directory +fmri is located and run:
%
% import fmri.split_excel_stats;
% split_excel_stats('+fmri/+test/test.xlsx', 1, ...
%   'test_<?subj>_<?set>.txt', 'subject', ...
%   'stat1', {'stat2', 'stat3'});
%
% % Then inspect the generated text files to understand how this script
% % works.
% 
% % The following example:
%
% split_excel_stats('ssmd_fmri_behav_auob.xlsx', ...
%   3, 'ssmd_<?subj>_fmri_behav_auob_<?set>.txt', 'subject', ...
%   'even_onset', 'odd_onset', 'even_correct_onset', ...
%   'odd_correct_onset', 'error_onset', 'noresp_onset', ...
%   'error+noresp_onset');
%
% % will generate 7 text files per subject. Each of those files will
% % contain a single column of values.
%
%
% ## Notes:
%
%   * This script is not designed to be fast but robust. This means that
%     it might be too slow if the input Excel file is very large. Also, the
%     whole Excel file is read at once into the functions workspace which
%     could produce an out-of-memory error for large files.
%
%   * There is a Perl interface to this script. Just open a console window
%     and type:
%
%       fmri_split_excel_stats --help
%
%
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