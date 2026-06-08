%% create_inference.m — Construit simul4inference.slx
%  Lancer APRES avoir entraine mdl_knn (via simul4entrainement.slx)
%
%  Architecture :
%  [sig_arret ]                                [Buffer DSP]
%  [sig_camion] → [ModeSwitch] → [Capteur]  →  N=2500, L=1250  → [Features] → [Classifieur KNN] → [label_detecte_ws]
%  [sig_train ]                   ICM20948     Ts_sortie = 5 s    MATLAB Fn    bloc natif Stats        [Scope_classes]
%  [sig_avion ]                                                                                              ↑
%  [ctrl_ws   ] → [ModeSwitch]                                                              [ctrl_5s] ───────┘
%
%  Cadence : Buffer DSP impose Ts_hop = 5 s pour Features et Classifieur.
%  Signaux generes avec graine 100 (differente de l'entrainement : 42).

model_name = 'simul4inference';

if bdIsLoaded(model_name), close_system(model_name, 0); end
new_system(model_name);
open_system(model_name);

%% Cadence du bloc Buffer DSP
N_hop = N_win - N_win/2;          % 1250 echantillons de chevauchement (OverlapPercent=50)
T_hop = N_win / fs;               % 10 s — periode reelle de sortie du bloc Buffer

set_param(model_name, ...
    'SolverType',             'Fixed-step', ...
    'Solver',                 'ode4', ...
    'FixedStep',              num2str(1/fs), ...
    'StopTime',               '240', ...
    'InitFcn',                'start4_infer', ...
    'StopFcn',                'stop4_infer', ...
    'ReturnWorkspaceOutputs', 'off');

%% ── 4 signaux sources (From Workspace) ──────────────────────────────────
noms  = {'sig_arret_ts','sig_camion_ts','sig_train_ts','sig_avion_ts'};
pos_y = [50 130 210 290];
for cl = 1:4
    add_block('simulink/Sources/From Workspace', ...
        [model_name '/' noms{cl}], ...
        'VariableName',          noms{cl}, ...
        'SampleTime',            num2str(1/fs), ...
        'OutputAfterFinalValue', 'Holding final value', ...
        'Interpolate',           'off', ...
        'Position',              [30 pos_y(cl) 130 pos_y(cl)+25]);
end

%% ── Signal de controle — cadence 1/fs (pour ModeSwitch) ─────────────────
add_block('simulink/Sources/From Workspace', [model_name '/ctrl_ws'], ...
    'VariableName',          'ctrl_ts', ...
    'SampleTime',            num2str(1/fs), ...
    'OutputAfterFinalValue', 'Holding final value', ...
    'Interpolate',           'off', ...
    'Position',              [30 340 130 365]);

%% ── Signal de controle — cadence T_hop (pour Scope comparaison) ──────────
add_block('simulink/Sources/From Workspace', [model_name '/ctrl_5s'], ...
    'VariableName',          'ctrl_ts', ...
    'SampleTime',            num2str(T_hop), ...
    'OutputAfterFinalValue', 'Holding final value', ...
    'Interpolate',           'off', ...
    'Position',              [490 310 610 340]);

%% ── Multiport Switch ─────────────────────────────────────────────────────
add_block('simulink/Signal Routing/Multiport Switch', ...
    [model_name '/ModeSwitch'], ...
    'Inputs',   '4', ...
    'Position', [180 55 220 305]);

add_line(model_name, 'ctrl_ws/1', 'ModeSwitch/1', 'autorouting','on');
for cl = 1:4
    add_line(model_name, [noms{cl} '/1'], ['ModeSwitch/' num2str(cl+1)], 'autorouting','on');
end

%% ── Sous-systeme Capteur ICM-20948 ──────────────────────────────────────
add_block('simulink/Ports & Subsystems/Subsystem', ...
    [model_name '/Capteur_ICM20948'], 'Position', [290 155 430 205]);

sub = [model_name '/Capteur_ICM20948'];
blks = find_system(sub,'SearchDepth',1,'type','block');
for i = 1:length(blks)
    if ~strcmp(blks{i}, sub), delete_block(blks{i}); end
end
delete_line(find_system(sub,'FindAll','on','type','line'));

add_block('simulink/Sources/In1',   [sub '/In1'],  'Position',[30  130 60  160]);
add_block('simulink/Discrete/Discrete Transfer Fcn', [sub '/DLPF'], ...
    'Numerator','b_dlpf','Denominator','a_dlpf','SampleTime',num2str(1/fs), ...
    'Position',[110 125 240 165]);
bruit_power_val = sigma_bruit^2 * (1/fs);
add_block('simulink/Sources/Band-Limited White Noise',[sub '/Bruit'], ...
    'Cov',num2str(bruit_power_val),'Ts',num2str(1/fs),'Seed','9999', ...
    'Position',[110 215 240 255]);
add_block('simulink/Sources/Constant',[sub '/Biais'], ...
    'Value','biais_acc','Position',[110 290 240 325]);
add_block('simulink/Math Operations/Add',[sub '/Add'], ...
    'Inputs','+++','Position',[300 130 340 240]);
add_block('simulink/Sinks/Out1',[sub '/Out1'],'Position',[400 165 430 195]);
add_line(sub,'In1/1',  'DLPF/1', 'autorouting','on');
add_line(sub,'DLPF/1', 'Add/1',  'autorouting','on');
add_line(sub,'Bruit/1','Add/2',  'autorouting','on');
add_line(sub,'Biais/1','Add/3',  'autorouting','on');
add_line(sub,'Add/1',  'Out1/1', 'autorouting','on');

add_line(model_name,'ModeSwitch/1','Capteur_ICM20948/1','autorouting','on');

%% ── Scope signal brut ────────────────────────────────────────────────────
add_block('simulink/Sinks/Scope',[model_name '/Scope_signal'], ...
    'Position',[490 100 540 140]);
add_line(model_name,'Capteur_ICM20948/1','Scope_signal/1','autorouting','on');

%% ── Buffer circulaire (bloc DSP System Toolbox) ──────────────────────────
% Remplace la MATLAB Function buffer_fn.
% Entree : scalaire a Ts = 1/fs  →  Sortie : vecteur N_win x 1 a Ts = T_hop = 5 s
dsp_buffer_path = 'dspbuff3/Buffer';

add_block(dsp_buffer_path, ...
    [model_name '/Buffer'], ...
    'N',              num2str(N_win), ...    % taille fenetre : 2500 echantillons
    'OverlapPercent', '50', ...             % chevauchement 50 % (contenu) — sortie toutes les N_win echantillons
    'Position',       [490 170 610 220]);
add_line(model_name,'Capteur_ICM20948/1','Buffer/1','autorouting','on');

%% ── Sous-systeme Features (identique a simul4entrainement) ──────────────

fs_path = [model_name '/Features'];
add_block('simulink/Ports & Subsystems/Subsystem', fs_path, 'Position',[660 145 850 255]);
blks = find_system(fs_path,'SearchDepth',1,'type','block');
for i = 1:length(blks)
    if ~strcmp(blks{i}, fs_path), delete_block(blks{i}); end
end
delete_line(find_system(fs_path,'FindAll','on','type','line'));

add_block('simulink/Sources/In1',                            [fs_path '/Frame'],     'Position',[30  165  60  195]);
add_block('simulink/User-Defined Functions/MATLAB Function', [fs_path '/StatsFn'],   'Position',[150  80 290  140]);
add_block('dspxfrm3/FFT',                                    [fs_path '/FFT'],       'Position',[150 220 220  260]);
add_block('simulink/User-Defined Functions/MATLAB Function', [fs_path '/SpectralFn'],'Position',[300 215 450  265]);
add_block('simulink/Signal Routing/Mux',                     [fs_path '/Mux'],       'Inputs','6','Position',[550  65 580 310]);
add_block('simulink/Sinks/Out1',                             [fs_path '/Out1'],      'Position',[640 170 670  205]);

add_line(fs_path,'Frame/1','FFT/1',       'autorouting','on');
add_line(fs_path,'FFT/1',  'SpectralFn/1','autorouting','on');
add_line(fs_path,'Frame/1','StatsFn/1',   'autorouting','on');
add_line(fs_path,'Mux/1',  'Out1/1',      'autorouting','on');

sf     = sfroot();
mdl_sf = sf.find('-isa','Simulink.BlockDiagram','Name',model_name);

ch = mdl_sf.find('-isa','Stateflow.EMChart','Path',[model_name '/Features/StatsFn']);
if ~isempty(ch)
    ch.Script = fileread('stats_fn.m');
    fprintf('  Script injecte : StatsFn\n');
else
    error('StatsFn non trouve.');
end

ch = mdl_sf.find('-isa','Stateflow.EMChart','Path',[model_name '/Features/SpectralFn']);
if ~isempty(ch)
    ch.Script = fileread('spectral_fn.m');
    fprintf('  Script injecte : SpectralFn\n');
else
    error('SpectralFn non trouve.');
end

add_line(fs_path,'StatsFn/1',   'Mux/1','autorouting','on');
add_line(fs_path,'StatsFn/2',   'Mux/2','autorouting','on');
add_line(fs_path,'SpectralFn/1','Mux/3','autorouting','on');
add_line(fs_path,'SpectralFn/2','Mux/4','autorouting','on');
add_line(fs_path,'SpectralFn/3','Mux/5','autorouting','on');
add_line(fs_path,'SpectralFn/4','Mux/6','autorouting','on');

add_line(model_name,'Buffer/1','Features/1','autorouting','on');

%% ── Classifieur k-NN (bloc natif Statistics and Machine Learning Toolbox) ─
add_block('statsLibrary/Classification/ClassificationKNN Predict', ...
    [model_name '/Classifieur'], 'Position',[830 170 960 220]);
set_param([model_name '/Classifieur'], 'TrainedLearner', 'mdl_knn');
add_line(model_name,'Features/1','Classifieur/1','autorouting','on');

%% ── To Workspace label detecte ───────────────────────────────────────────
% label_detecte : vecteur 48 x 1 (240 s / T_hop = 48 fenetres)
add_block('simulink/Sinks/To Workspace',[model_name '/label_detecte_ws'], ...
    'VariableName','label_detecte','MaxDataPoints','inf','SaveFormat','Array', ...
    'Position',[1010 180 1110 210]);
add_line(model_name,'Classifieur/1','label_detecte_ws/1','autorouting','on');

%% ── Scope comparaison (2 voies : classe reelle vs classe detectee) ───────
% Les deux signaux sont a la cadence T_hop = 5 s.
add_block('simulink/Sinks/Scope',[model_name '/Scope_classes'], ...
    'NumInputPorts','2','Position',[1010 270 1060 320]);
add_line(model_name,'ctrl_5s/1',     'Scope_classes/1','autorouting','on');
add_line(model_name,'Classifieur/1', 'Scope_classes/2','autorouting','on');

%% ── Injection du script dans le bloc MATLAB Function Features ─────────────
sf     = sfroot();
mdl_sf = sf.find('-isa','Simulink.BlockDiagram','Name',model_name);

ch = mdl_sf.find('-isa','Stateflow.EMChart','Path',[model_name '/Features']);
if ~isempty(ch)
    ch.Script = fileread('features_fn.m');
    fprintf('  Script injecte : Features\n');
else
    fprintf('  AVERTISSEMENT : bloc Features non trouve\n');
end

save_system(model_name);

fprintf('\n== simul4inference.slx cree (bloc Buffer DSP natif) ==\n');
fprintf('Buffer DSP : N=%d pts, overlap=%d pts, Ts_sortie=%.0f s\n', ...
        N_win, N_win/2, T_hop);
fprintf('Duree : 240 s  (4 modes x 60 s)  →  %d fenetres au total\n', ...
        floor(240/T_hop));
fprintf('Sequence : Arret(0s) -> Camion(60s) -> Train(120s) -> Avion(180s)\n');
fprintf('Signaux generes avec graine 100 (differente de l''entrainement : 42)\n');
fprintf('Scope_classes : voie 1 = classe reelle, voie 2 = classe detectee\n');
fprintf('Latence inherente : %.0f s (= T_hop = N_hop / fs)\n', T_hop);
