%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Example workflow for using 3 open-weight models to obtain literature 
% summaries for 8 domains of human cognition, for the DesikanKilliany68 
% atlas, and comparing with NeuroSynth and NeuroQuery meta-analytic maps.
% 
% It will produce figures showing empirical correlations between pairs of
% LLM and NeuroSynth/NeuroQuery maps, alongside histograms of null
% distributions obtained using spin-tests for spatial autocorrelation.
% Requires the ENIGMA toolbox (https://enigma-toolbox.readthedocs.io/en/latest/)
%
% Andrea Luppi (2026) Email: andrea.luppi[at]psych.ox.ac.uk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; close all

addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'helper_functions')));

% The ENIGMA toolbox should also be on your MATLAB path to use their spin-test functionality
addpath(genpath('ENIGMA')) 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0: get the LLM literature-summary maps

% This command needs to be run in the terminal after pip-installing and
% activating llm_neuro
% This requires OpenRouter credist and API 
% (see installation guide for the repo: https://github.com/andrealuppi/neuroLLM)
% but should only cost a few cents
% Note that although the codebase is setting a seed and setting temperature
% to 0.0, some inherent stochasticity will remain in the LLM outputs

    % python main.py query-functions \
    %    --separate-hemispheres  --skip-visualization --workers 5 \
    %    --atlas-name DesikanKilliany68 --species human \
    %    --functions "cognitive control,emotion,language,listening,manipulation,memory,reward,vision" \                                                          
    %    --models "google/gemma-4-31b-it,openai/gpt-oss-120b,qwen/qwen3-235b-a22b-2507"


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 1: Load the LLM maps

%Tell the function which LLMs to use
%full name, nickname
allLLMnames = {...
    'openai/gpt-oss-120b', 'OpenAI_OSS120b';...
    'google/gemma-4-31b-it', 'Gemma4_31b';...
    'qwen/qwen3-235b-a22b-2507', 'Qwen3_235b';...
}

%List the terms we want
terms = {'cognitive_control','emotion','language','listening','manipulation','memory','reward','vision'}

%switch to your location
llm_dir = '/Users/Andrea/neuroLLM'; 

%Now get the maps using the dedicated helper function: this will assemble
%maps from individual regions, as per the atlas and requested LLMs
[LLM_maps] = helper_assemble_LLM_maps(terms, 'human', {'DesikanKilliany',68,'LLRR'}, allLLMnames, llm_dir, 'default', true);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 2: load NeuroSynth maps

%NeuroSynth maps for the same 8 domains
load('meta_analytic_maps/NeuroSynth_BeamOntology.mat');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 3: correlate with spin-test correction for spatial autocorrelation

for tt = 1:numel(terms)
    thisTerm = terms{tt}

    %Z-score each LLM's map separately, to remove potential differences in baseline, then average across LLMs
    LLM_map = mean(zscore(LLM_maps.(thisTerm)),2);

    %Get the map that corresponds to the same term in NeuroSynth
    NS_map = NeuroSynth_BeamOntology.maps(:, cellfind(NeuroSynth_BeamOntology.names, thisTerm));

    %We use Spearman to be conservative, since we care primarily about
    %regions' ranks
    rho_emp_NS(tt) = corr(LLM_map, NS_map, 'type', 'spearman');

    %This function requires ENIGMA toolbox;
    % aparc is the name of the DesikanKilliany in ENIGMA/FreeSurfer
    [p_spin_NS(tt), null_dist_NS{tt}] = spin_test(LLM_map, NS_map, 'type', 'spearman', 'parcellation_name', 'aparc');

    plot_NullHistogram(rho_emp_NS(tt), null_dist_NS{tt}, p_spin_NS(tt), [thisTerm, ': LLM - NeuroSynth match (Spearman)']);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 4: Now compare LLMs with NeuroQuery

load('meta_analytic_maps/NeuroQuery_BeamOntology.mat')

for tt = 1:numel(terms)
    thisTerm = terms{tt}

    %Z-score each LLM's map separately, to remove potential differences in baseline, then average across LLMs
    LLM_map = mean(zscore(LLM_maps.(thisTerm)),2);

    %Get the map that corresponds to the same term in NeuroQuery
    NQ_map = NeuroQuery_BeamOntology.maps(:, cellfind(NeuroQuery_BeamOntology.names, thisTerm));

    %We use Spearman to be conservative, since we care primarily about
    %regions' ranks
    rho_emp_NQ(tt) = corr(LLM_map, NQ_map, 'type', 'spearman');

    %This function requires ENIGMA toolbox;
    % aparc is the name of the DesikanKilliany in ENIGMA/FreeSurfer
    [p_spin_NQ(tt), null_dist_NQ{tt}] = spin_test(LLM_map, NQ_map, 'type', 'spearman', 'parcellation_name', 'aparc');

    plot_NullHistogram(rho_emp_NQ(tt), null_dist_NQ{tt}, p_spin_NQ(tt), [thisTerm, ': LLM - NeuroQuery match (Spearman)']);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 5: check manipulation after refining the NeuroSynth map with NeuroSieve
%NeuroSieve repo: https://github.com/netneurolab/neurosieve

load('meta_analytic_maps/NeuroSynth_Manipulation_Refined.mat');

LLM_Manipul = mean(zscore(LLM_maps.manipulation),2);

rho_emp_Manipul = corr(LLM_Manipul, NeuroSynth_Manipulation_Refined, 'type', 'spearman');

[p_spin_Manipul, null_dist_Manipul] = spin_test(LLM_Manipul, NeuroSynth_Manipulation_Refined, 'type', 'spearman', 'parcellation_name', 'aparc');

plot_NullHistogram(rho_emp_Manipul, null_dist_Manipul, p_spin_Manipul, ...
    [thisTerm, ' NeuroSynth: original rho = ', num2str(rho_emp_NS(cellfind(NeuroSynth_BeamOntology.names, 'manipulation')),2), '; refined = ', num2str(rho_emp_Manipul,2)]);
