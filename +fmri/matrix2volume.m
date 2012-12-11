function matrix2volume(folder, varargin)
% MATRIX2VOLUME - Convert .matrix text files back to NIFTI format
%
% matrix2volume(folder,  'key', value, ...)
% matrix2volume(file, 'key', value, ...)
%
% Where
%
% FOLDER is the path name where the .matrix files (and the corresponding
% .nii or .nii.gz files) are located.
%
% FILE is the path to a .matrix file. The corresponding NIFTI file must be
% located in the same folder.
%
%
% Optional key/value pairs:
%
%       OGE : A logical scalar. Default: true
%           Determines whether OGE should be used, if available.
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
miscPath = strrep(thisName, ...
    ['fmri' filesep '+FMRI' filesep 'matrix2volume'], 'misc');
addpath(miscPath);

import FMRI.globals;
import FMRI.matrix2volume;

opt.verbose = true;
opt.stdout  = 1;
opt.oge     = true;

[~, opt] = MISC.process_arguments(opt, varargin);

if opt.verbose,
    stdout = MISC.stdout_open(opt.stdout);
end

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
            MISC.qsub(sprintf('FMRI.matrix2volume(''%s'')', folder{i}), varargin{:});
        end
    else
        for i = 1:numel(folder)
            matrix2volume(folder{i}, varargin{:});
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
        [~,~,ext] = fileparts(fileStruct(i).name);
        if strcmpi(ext, '.matrix'),
            files{count} = [folder '/' fileStruct(i).name];
            count = count+1;
        end
    end
    files(count:end)=[];
    matrix2volume(files, varargin{:});
    return;
elseif ischar(folder) && ~exist(folder, 'file'),
    % FOLDER does not exist
    error('FMRI:matrix2volume:InvalidArgument', ...
        'I cound not find %s', folder);
elseif ~ischar(folder),
    error('FMRI:matrix2volume:InvalidArgument', ...
        'The input argument must be a char array');
end

file = folder;
[path, ~, ext] = fileparts(file);
if ~strcmpi(ext, '.matrix'),
    error('Invalid file extension: %s', ext);
end

file = strrep(file, '\', '/');
[folder, name, ext] = fileparts(file);
if ~strcmpi(ext, '.matrix'),
    error('Invalid file extension: %s', ext);
end

niiFile = [path '/' name '.nii'];
newFile = [];

if ~exist(niiFile, 'file'),    
    if exist([path '/' name '.nii.gz'], 'file'),   
        if opt.verbose,
            fprintf(stdout, '(FMRI.matrix2volume) Decompressing %s...', niiFile);
        end
        niiFile = gunzip([path '/' name '.nii.gz']);
        if opt.verbose,
            fprintf(stdout, '[done]\n\n');
        end
        niiFile = niiFile{1};
        newFile = niiFile;        
    else
        error('FMRI:matrix2volume:MissingFile', ...
            'I could not find file %s', niiFile);
    end
end

if opt.verbose,
    fprintf(stdout, [file '\n']);
    fprintf(stdout, ['--> ' folder '/' name '_matrix2volume.nii']);
end

nii = load_nii(niiFile);

fid = fopen([folder '/' name '.matrix'], 'r');
try
    % read header
    dims = textscan(fid, '%s %d %d %d %d', 1);
    ncols = textscan(fid, '%s %d', 1);
    ncols = double(ncols{2});
    nrows = double(dims{5});
    % Read point indices
    idx = fscanf(fid, '%d', ncols);
    nrowsby10=ceil(nrows/10);
    for j = 1:nrows
        tmp = zeros(size(nii.img,1), size(nii.img,2), size(nii.img,3));
        tmp(idx) = fscanf(fid, '%f', ncols);
        nii.img(:,:,:,j) = tmp;
        if opt.verbose && ~mod(j, nrowsby10),
            fprintf(stdout, '.');
        end
    end
    if opt.verbose,
        fprintf(stdout, '[done]\n\n');
    end
    niiFile = strrep(niiFile, '.nii', '_matrix2volume.nii');
    if opt.verbose,
        fprintf(stdout, '(FMRI.matrix2volume) Saving %s...', niiFile);
    end
    save_nii(nii, niiFile);    
    fclose(fid);
    if opt.verbose,
        fprintf(stdout, '[done]\n\n');
    end
    if opt.verbose,
        fprintf(stdout, '(FMRI.matrix2volume) Compressing %s...', niiFile);
    end
    gzip(niiFile);
    delete(niiFile);
    if opt.verbose,
        fprintf(stdout, '[done]\n\n');
    end
catch ME
    fclose(fid);
    rethrow(ME);
end

% Delete the uncompressed files
if ~isempty(newFile),
    if opt.verbose,
        fprintf('(FMRI.matrix2volume) Removing %s...', newFile);
    end
    delete(newFile);
    if opt.verbose,
        fprintf('[done]\n');
    end
end


end