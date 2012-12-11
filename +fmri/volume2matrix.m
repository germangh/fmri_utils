function volume2matrix(folder, varargin)
% volume2matrix
% Extracts intensity values of a NIFTI file and stores them as a text file
%
% volume2matrix(folder, 'key', value, ...)
% volume2matrix(file, 'key', value, ...)
%
% Where
%
% FOLDER is the path name where the .nii or .nii.gz files are located.
%
% FILE is the path to a .nii or .nii.gz file.
%
%
% Optional key/value pairs:
%
%
% OGE       : (logical scalar) Determines whether OGE should be used, if
%              available. Def: true
%
% HMemory   : (double scalar) Maximum limit that each OGE job can use, in
%              Gb. Def: MISC.evaluate.HVmem
%
% WallTime  : (string) A string of the form HH:MM:SS determining the
%             maximum duration of an OGE job. Def: MISC.evaluate.HRt
%
% Verbose   : (logical scalar) Determines whether status messages should be
%             generated or not. Def: true
%
% StdOut    : (string) A file name where the status messages will be logged
%
%
% Notes
%
% * This function depends on the NIFTI toolbox for MATLAB. Please ensure
% that the location of the NIFTI toolbox is specified in the NiftiToolbox
% variable of file +FMRI/@globals.globals.txt
%
% * Under linux, and if Oracle Grid Engine is available, this function will
% process each file as a different OGE job. 
%
%
% (c) German Gomez-Herrero
% g.gomez@nin.knaw.nl

% Add the MISC package to the path
thisName = mfilename('fullpath');
%fprintf('CACACACA: %s\n', thisName);exit;
miscPath = strrep(thisName, ...
    ['fmri' filesep '+FMRI' filesep 'volume2matrix'], 'misc');
addpath(miscPath);

import FMRI.globals;
import FMRI.volume2matrix;

opt.oge     = true;
opt.verbose = true;
opt.stdout  = 1;

[~, opt] = MISC.process_arguments(opt, varargin);

stdout = MISC.stdout_open(opt.stdout);

% Add the NIFTI toolbox to the path
niftiLocation = globals.evaluate.NiftiToolbox;
for i = 1:numel(niftiLocation)
    if exist(niftiLocation{i}, 'dir'),
        niftiLocation = niftiLocation{i};
        break;
    end
end
if isempty(niftiLocation) || ~ischar(niftiLocation),
    error('I could not find the NIFTI toolbox');
end
addpath(genpath(niftiLocation));

if iscell(folder),
    % Multiple folders or files as a cell array
    if opt.oge && MISC.has_oge,
        for i = 1:numel(folder),
            MISC.qsub(sprintf('FMRI.volume2matrix(''%s'')', folder{i}), varargin{:});
        end
    else
        for i = 1:numel(folder)
            volume2matrix(folder{i}, varargin{:});
        end
    end
    return;
elseif ischar(folder) && exist(folder, 'dir'),
    % FOLDER is a directory
    folder = strrep(folder, '\', '/');
    fileStruct = dir(folder);
    files = cell(numel(fileStruct),1);
    count = 1;
    for i = 1:numel(fileStruct)
        [~, ~, ext] = fileparts(fileStruct(i).name);
        if strcmpi(ext, '.nii'), 
            files{count} = [folder '/' fileStruct(i).name];
            count = count+1;
        end
        res = regexpi(fileStruct(i).name, '(?<name>.+).nii.gz$','names');
        if ~isempty(res) && isfield(res, 'name') && ~isempty(res.name) && ...
                ~exist([folder '/' res.name '.nii'], 'file'),
            files{count} = [folder '/' fileStruct(i).name];
            count = count+1;
        end
    end
    files(count:end)=[];
    volume2matrix(files, varargin{:});
    return;
elseif ischar(folder) && ~exist(folder, 'file'),
    % FOLDER does not exist
    error('I cound not find %s', folder);
elseif ~ischar(folder),
    error('The input argument must be a char array');
end

file = folder;

[~, ~, ext] = fileparts(file);
if ~(strcmpi(ext, '.nii') || ...
        ~isempty(regexpi(file, '.nii.gz$'))),
    error('Invalid file extension: %s', ext);
end

if  ~isempty(regexpi(file, '.nii.gz$'))
    if opt.verbose,
        fprintf(stdout, '(FMRI.volume2matrix) Decompressing %s...', file);
    end
    tmp = gunzip(file);
    newFile = tmp{1};
    file = newFile;
    if opt.verbose,
        fprintf(stdout, '[done]\n\n');
    end
else
    newFile = [];
end

file = strrep(file, '\', '/');
[folder, name, ext] = fileparts(file);
if ~strcmpi(ext, '.nii'),
    error('Invalid file extension: %s', ext);
end

if opt.verbose, 
    fprintf(stdout, [file '\n']);
    fprintf(stdout, ['--> ' folder '/' name '.matrix\n\n']);
end
if opt.verbose,
    fprintf(stdout, '(FMRI.volume2matrix) Loading %s...', file);
end
nii = load_nii(file);
if opt.verbose,
    fprintf(stdout, '[done]\n\n');
end
if opt.verbose,
    fprintf(stdout, '(FMRI.volume2matrix) Writing to %s...', ...
        [folder '/' name '.matrix']);
end
fid = fopen([folder '/' name '.matrix'], 'w');
try
    isBrain = (nii.img>0);
    isBrain = (sum(isBrain, 4)>0);
    isBrainIdx = find(isBrain);
    fprintf(fid, '# %d %d %d %d\n', size(nii.img));
    fprintf(fid, '# %d\n', numel(isBrainIdx));
    fprintf(fid, '%d ', isBrainIdx);
    fprintf(fid, '\n');
    for j = 1:size(nii.img,4)
        tmp = nii.img(:,:,:,j);
        fprintf(fid, '%3.2f ', tmp(isBrainIdx));
        fprintf(fid, '\n');
    end
catch ME
    fclose(fid);
    rethrow(ME);
end
fclose(fid);
if opt.verbose,
    fprintf('[done]\n\n');
end

% Delete the uncompressed files
if ~isempty(newFile),
    if opt.verbose,
        fprintf(stdout, '(FMRI.volume2matrix) Removing %s...', newFile);
    end
    delete(newFile);
    if opt.verbose, 
        fprintf(stdout, '[done]\n\n');
    end
end

end