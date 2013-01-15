function initialize

import fmri.root_path;

% Add sub-modules to the path

subMods = {...
    'misc', ...     % matlab_misc
    'perl' ...     % matlab_mperl
    };       

for i = 1:numel(subMods),
    addpath([root_path filesep subMods{i}]);
end


end




