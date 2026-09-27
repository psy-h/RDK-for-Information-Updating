
clear;
clc;
close all;

%% Display parameters

display.viewDist = 100;      % Viewing distance (cm)
display.screenWidth = 34;    % Screen width (cm)
%% Trial structure

trial.conditions = {'noChangeShort', 'noChangeLong', 'change'};

% Number of trials at each coherence level for each condition.

trial.n1 = [1, 1, 1];
trial.n2 = [1, 1, 1];
 
% Motion coherence levels.

coherence1 = 0.40; 
coherence2 = 1;

%% Run the RDK demo

results = run_RDK(display, trial, coherence1, coherence2);