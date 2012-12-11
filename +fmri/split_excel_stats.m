function split_excel_stats(fName, subjCol, varargin)
% SPLIT_EXCEL_STATS
%
%
% ## Example:
%
% import fmri.split_excel_stats;
% split_excel_stats('+fmri/+test/test.xlsx', 'subject', ...
%   'stat1', {'stat2', 'stat3'});
%
% See also: fmri


import misc.safefid;
import mperl.file.spec.*;


[~, ~, raw] = xlsread(fName);

header   = lower(raw(1,:));
varargin = lower(varargin);

fPath = fileparts(fName);

for i = 1:numel(varargin)
    % Iterate across column groups
    
    colNames = cellfun(@(x) regexprep(x, '[_\s]+', '-'), colNames, ...
        'UniformOutput', false);
    
    [isFound, loc] = ismember(header, varargin{i});
    
    if ~any(isFound), continue; end
    
    [~, order] = sort(loc, 'ascend');
    data = raw(2:end, isFound);
    data = data(:, order);
    
    thisFName = catfile(fPath, [name '_' groupName '.txt']);
    fid = safefid(thisFName, 'w');
    for j = 1:size(data,1)
        
        thisRow = data(j,:);
        fprintf(fid, '%s ', thisRow{:});
        fprintf(fid, '\n');
        
    end  
    
    
end





end