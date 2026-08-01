function[LLM_maps] = helper_assemble_LLM_maps(terms, species, atlas, allLLMnames, optional_llmDir, optional_prompt, optional_separation_YN)

% INPUTS:
% *mandatory*
% terms: a cell array of strings; example: {'memory', 'emotion'}
% species: a string. example: 'human'
% atlas: a cell array with the atlas name (a string), the number of
%   regions (integer: this is the total across both hemisphere) and a flag for hemisphere order ('LLRR', 'RRLL', 'LRLR' or 'RLRL').
%   This must be one of the atlases available in /atlases
%   example: {'DesikanKilliany', 68, 'LLRR'}
%
% allLLMnames: a cell array with one row per LLM, and the columns being the unique full, and unique nickname;
%   example:
  % allLLMnames = {...
  % 'anthropic/claude-opus-4.6', 'Claude';...
  % 'google/gemini-3.1-pro-preview', 'Gemini';...
  % 'openai/gpt-5.4', 'ChatGPT';...
  % };

% *optional*
% optional_llmDir: a string with the ABSOLUTE path where the repo is located. Default
%   is 'neuroLLM' which is the name of the GitHub repo
% optional_prompt: a string defining the prompt (name of the file, NOT the full
%   prompt!). Default value is 'default'
% optional_separation_YN: boolean. Default is true. Set to false to avoid separation
%   between hemispheres.
% Any of the optional arguments can be replaced by [] to use the default

% OUTPUT:
% allMapsLLM: a struct, with one field being one of the requested terms.
% Each field contains a matrix with N rows (N being the number of regions
% specified in the atlas) and one column per LLM.

% NOTE:
% If the atlas provides subcortical regions by hemisphere alongside the cortical ones,
% then no adjustments are required.
% If instead all subcortical regions are provided before all cortical ones,
% or after, then the combined atlas can be reconstructed by separately
% assembling cortex and subcortex.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% HOUSEKEEPING AND DEFAULTS

%% Change this default to *your own path*
if not(exist('optional_llmDir', 'var'))
    optional_llmDir = '';
end
if isempty(optional_llmDir)
    optional_llmDir = ['/neuroLLM']; %default
end

if not(exist('optional_prompt', 'var'))
optional_prompt = [];
end
if isempty(optional_prompt)
    optional_prompt = 'default';
end

%Default is to have each hemisphere separately
if not(exist('optional_separation_YN', 'var'))
    optional_separation_YN = [];
end
if isempty(optional_separation_YN)
    optional_separation_YN = true;
end

%Allow simpler input for single term without throwing an error
if ischar(terms)
    terms = {terms};
end

%Transpose if necessary
if size(terms,2) > 1
    terms = terms';
end


%All files have this same name
file2load = 'probabilities';


%%%%%%%%%%%%%%%%
%% ACTUAL SCRIPT

for tt = 1:size(terms,1)
    thisTerm = terms{tt,1}

    for ll = 1:size(allLLMnames,1)

        stringParts = strsplit(allLLMnames{ll,1}, '/');
        thisLLM_company = stringParts{1};
        thisLLM_modelID = stringParts{2};


        if optional_separation_YN == true

            LH = readtable(([optional_llmDir, '/results/aggregated/query-functions/', species, '/', atlas{1}, num2str(atlas{2}), '/', thisLLM_company, '/', thisLLM_modelID, '/',  optional_prompt, '/separation', '/left/', replace_separator(terms{tt,1}, ' ', '_'),   '/', file2load, '.csv']));
            LH = table2array(LH(:, 2:end));

            RH = readtable(([optional_llmDir, '/results/aggregated/query-functions/', species, '/', atlas{1}, num2str(atlas{2}), '/', thisLLM_company, '/', thisLLM_modelID, '/', optional_prompt, '/separation', '/right/', replace_separator(terms{tt,1}, ' ', '_'),   '/', file2load, '.csv']));
            RH = table2array(RH(:, 2:end));

        elseif optional_separation_YN == false

            LH = readtable([optional_llmDir, '/results/aggregated/query-functions/', species, '/', atlas{1}, num2str(atlas{2}), '/', thisLLM_company, '/', thisLLM_modelID, '/',  optional_prompt, '/no_separation/', replace_separator(terms{tt,1}, ' ', '_'),   '/', file2load, '.csv']);
            LH = table2array(LH(:, 2:end));

            RH = readtable([optional_llmDir, '/results/aggregated/query-functions/', species, '/', atlas{1}, num2str(atlas{2}), '/', thisLLM_company, '/', thisLLM_modelID, '/', optional_prompt, '/no_separation/', replace_separator(terms{tt,1}, ' ', '_'),   '/', file2load, '.csv']);
            RH = table2array(RH(:, 2:end));

        end

        switch atlas{3}
            case {'LLRR'} %LEFT then RIGHT (example: DK, Glasser)
                thisMapLLM = [LH; RH];
            case {'RRLL'} %RIGHT then LEFT
                thisMapLLM = [RH; LH];
            case {'LRLR'} %Alternating, with LEFT first
                thisMapLLM = [];
                        for roi = 1: atlas{2}/2 %assumes even number of regions
                            thisMapLLM = [thisMapLLM; LH(roi); RH(roi)];
                        end
                                    case {'RLRL'} %Alternating, with RIGHT first
                thisMapLLM = [];
                        for roi = 1: atlas{2}/2 %assumes even number of regions
                            thisMapLLM = [thisMapLLM; RH(roi); LH(roi)];
                        end
        end

        for st = 1:size(thisMapLLM,2)
            LLM_maps.(replace_separator(replace_separator(thisTerm, ' ', '_'), '-', '_'))(:, ll, st) = thisMapLLM(:,st);
        end

    end %end loop over LLMS

end %end loop over terms



