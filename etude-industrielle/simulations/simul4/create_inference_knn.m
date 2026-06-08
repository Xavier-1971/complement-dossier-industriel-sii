%% create_inference_knn.m — Construit simul4knn_explicite.slx
%  Lancer APRES avoir entraine mdl_knn (via simul4entrainement.slx)
%
%  Architecture pedagogique — chaque etape du k-NN est un bloc distinct :
%
%  [sig_arret ]                                [Buffer DSP]
%  [sig_camion] → [ModeSwitch] → [Capteur]  →  N=2500, L=1250  → [Features] → [Normalisation] → [KNNSearch] → [Vote] → [label_detecte_ws]
%  [sig_train ]                   ICM20948     Ts_sortie = 5 s    6 features   z-score           3 idx         vote      [Scope_classes]
%  [sig_avion ]                                                                                                               ↑
%  [ctrl_ws   ] → [ModeSwitch]                                                                            [ctrl_5s] ─────────┘
%
%  MATLAB Functions : Features (features_fn), Normalisation (normalisation_fn),
%                     KNNSearch (knn_search_fn), Vote (vote_fn)

model_name = 'simul4knn_explicite';

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
    'InitFcn',                'start4_infer_knn', ...
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

%% ── Signal de controle cadence 1/fs (ModeSwitch) ────────────────────────
add_block('simulink/Sources/From Workspace', [model_name '/ctrl_ws'], ...
    'VariableName',          'ctrl_ts', ...
    'SampleTime',            num2str(1/fs), ...
    'OutputAfterFinalValue', 'Holding final value', ...
    'Interpolate',           'off', ...
    'Position',              [30 340 130 365]);

%% ── Signal de controle cadence T_hop (Scope_classes) ────────────────────
add_block('simulink/Sources/From Workspace', [model_name '/ctrl_5s'], ...
    'VariableName',          'ctrl_ts', ...
    'SampleTime',            num2str(T_hop), ...
    'OutputAfterFinalValue', 'Holding final value', ...
    'Interpolate',           'off', ...
    'Position',              [1150 310 1270 340]);

%% ── Multiport Switch ─────────────────────────────────────────────────────
add_block('simulink/Signal Routing/Multiport Switch', ...
    [model_name '/ModeSwitch'], 'Inputs','4', 'Position',[180 55 220 305]);

add_line(model_name, 'ctrl_ws/1', 'ModeSwitch/1', 'autorouting','on');
for cl = 1:4
    add_line(model_name, [noms{cl} '/1'], ['ModeSwitch/' num2str(cl+1)], 'autorouting','on');
end

%% ── Sous-systeme Capteur ICM-20948 ──────────────────────────────────────
add_block('simulink/Ports & Subsystems/Subsystem', ...
    [model_name '/Capteur_ICM20948'], 'Position',[290 155 430 205]);

sub = [model_name '/Capteur_ICM20948'];
blks = find_system(sub,'SearchDepth',1,'type','block');
for i = 1:length(blks)
    if ~strcmp(blks{i},sub), delete_block(blks{i}); end
end
delete_line(find_system(sub,'FindAll','on','type','line'));

add_block('simulink/Sources/In1',  [sub '/In1'], 'Position',[30 130 60 160]);
add_block('simulink/Discrete/Discrete Transfer Fcn',[sub '/DLPF'], ...
    'Numerator','b_dlpf','Denominator','a_dlpf','SampleTime',num2str(1/fs), ...
    'Position',[110 125 240 165]);
bruit_power_val = sigma_bruit^2*(1/fs);
add_block('simulink/Sources/Band-Limited White Noise',[sub '/Bruit'], ...
    'Cov',num2str(bruit_power_val),'Ts',num2str(1/fs),'Seed','9999', ...
    'Position',[110 215 240 255]);
add_block('simulink/Sources/Constant',[sub '/Biais'], ...
    'Value','biais_acc','Position',[110 290 240 325]);
add_block('simulink/Math Operations/Add',[sub '/Add'], ...
    'Inputs','+++','Position',[300 130 340 240]);
add_block('simulink/Sinks/Out1',[sub '/Out1'],'Position',[400 165 430 195]);
add_line(sub,'In1/1','DLPF/1','autorouting','on');
add_line(sub,'DLPF/1','Add/1','autorouting','on');
add_line(sub,'Bruit/1','Add/2','autorouting','on');
add_line(sub,'Biais/1','Add/3','autorouting','on');
add_line(sub,'Add/1','Out1/1','autorouting','on');
add_line(model_name,'ModeSwitch/1','Capteur_ICM20948/1','autorouting','on');

%% ── Scope signal brut ────────────────────────────────────────────────────
add_block('simulink/Sinks/Scope',[model_name '/Scope_signal'],'Position',[490 100 540 140]);
add_line(model_name,'Capteur_ICM20948/1','Scope_signal/1','autorouting','on');

%% ── Buffer circulaire (bloc DSP System Toolbox) ──────────────────────────
% Entree : scalaire a Ts = 1/fs → Sortie : vecteur N_win x 1 a Ts = T_hop = 5 s
add_block('dspbuff3/Buffer', ...
    [model_name '/Buffer'], ...
    'N',              num2str(N_win), ...    % taille fenetre : 2500 echantillons
    'OverlapPercent', '50', ...             % chevauchement 50 % (contenu) — sortie toutes les N_win echantillons
    'Position',       [490 170 610 220]);
add_line(model_name,'Capteur_ICM20948/1','Buffer/1','autorouting','on');

%% ── Etape 1 : Extraction de features (MATLAB Function) ──────────────────
% features_fn.m : [rms, crete, f_c, E_basse, E_milieu, E_haute]
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [model_name '/Features'], 'Position',[660 170 800 220]);
add_line(model_name,'Buffer/1','Features/1','autorouting','on');

%% ── Etape 2 : Normalisation z-score (MATLAB Function) ───────────────────
% normalisation_fn.m : (feat - mu_train) ./ sigma_train
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [model_name '/Normalisation'], 'Position',[840 170 980 220]);
add_line(model_name,'Features/1','Normalisation/1','autorouting','on');

%% ── Etape 3 : Recherche k-NN (MATLAB Function) ───────────────────────────
% knn_search_fn.m : knnsearch sur X_train normalise → 3 indices
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [model_name '/KNNSearch'], 'Position',[1020 170 1140 220]);
add_line(model_name,'Normalisation/1','KNNSearch/1','autorouting','on');

%% ── Etape 4 : Vote majoritaire (MATLAB Function) ─────────────────────────
% vote_fn.m : mode(y_train(idx)) → label 1..4
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [model_name '/Vote'], 'Position',[1180 170 1300 220]);
add_line(model_name,'KNNSearch/1','Vote/1','autorouting','on');

%% ── To Workspace + Scope comparaison ────────────────────────────────────
add_block('simulink/Sinks/To Workspace',[model_name '/label_detecte_ws'], ...
    'VariableName','label_detecte','MaxDataPoints','inf','SaveFormat','Array', ...
    'Position',[1350 175 1450 205]);
add_block('simulink/Sinks/Scope',[model_name '/Scope_classes'], ...
    'NumInputPorts','2','Position',[1350 270 1400 320]);

add_line(model_name,'Vote/1',    'label_detecte_ws/1', 'autorouting','on');
add_line(model_name,'Vote/1',    'Scope_classes/2',    'autorouting','on');
add_line(model_name,'ctrl_5s/1', 'Scope_classes/1',    'autorouting','on');

%% ── Injection des scripts MATLAB Function ────────────────────────────────
sf     = sfroot();
mdl_sf = sf.find('-isa','Simulink.BlockDiagram','Name',model_name);

blocs_fn = {'Features',     'Normalisation',       'KNNSearch',       'Vote'};
fichiers  = {'features_fn.m','normalisation_fn.m',  'knn_search_fn.m', 'vote_fn.m'};

for i = 1:4
    ch = mdl_sf.find('-isa','Stateflow.EMChart', ...
                     'Path',[model_name '/' blocs_fn{i}]);
    if ~isempty(ch)
        ch.Script = fileread(fichiers{i});
        fprintf('  Script injecte : %s\n', blocs_fn{i});
    else
        error('%s non trouve.', blocs_fn{i});
    end
end

save_system(model_name);

fprintf('\n== simul4knn_explicite.slx cree (Buffer DSP natif) ==\n');
fprintf('Chaine explicite : Buffer → Features → Normalisation → KNNSearch → Vote\n');
fprintf('Buffer DSP : N=%d pts, overlap=%d pts, Ts_sortie=%.0f s\n', ...
        N_win, N_win/2, T_hop);
fprintf('Duree : 240 s  (4 modes x 60 s)  →  %d fenetres\n', floor(240/T_hop));
fprintf('Scope_classes : voie 1 = classe reelle, voie 2 = classe detectee\n');
