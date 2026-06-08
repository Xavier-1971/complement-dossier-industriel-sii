%% create_model4.m — Construit simul4.slx
%  Lancer APRES start4.m
%
%  Architecture :
%  [sig_arret ]                              [Scope signal]
%  [sig_camion] → [ModeSwitch] → [Capteur] →
%  [sig_train ] ↑               ICM20948    → [Buffer] → [Features] → [Classifieur]
%  [sig_avion ]                                                              ↓
%  [ctrl_ts   ] ─────────────────────────────────────── [Scope classes (2 voies)]

model_name = 'simul4';

if bdIsLoaded(model_name), close_system(model_name, 0); end
new_system(model_name);
open_system(model_name);

set_param(model_name, ...
    'SolverType',             'Fixed-step', ...
    'Solver',                 'ode4', ...
    'FixedStep',              num2str(1/fs), ...
    'StopTime',               num2str(T_total), ...
    'InitFcn',                'start4', ...
    'StopFcn',                'stop4', ...
    'ReturnWorkspaceOutputs', 'off');

%% ── 4 signaux sources (From Workspace) ──────────────────────────────────────
noms = {'sig_arret_ts','sig_camion_ts','sig_train_ts','sig_avion_ts'};
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

%% ── Signal de controle (classe reelle) ──────────────────────────────────────
add_block('simulink/Sources/From Workspace', [model_name '/ctrl_ws'], ...
    'VariableName',          'ctrl_ts', ...
    'SampleTime',            num2str(1/fs), ...
    'OutputAfterFinalValue', 'Holding final value', ...
    'Interpolate',           'off', ...
    'Position',              [30 340 130 365]);

%% ── Multiport Switch : selectionne le signal selon ctrl ─────────────────────
add_block('simulink/Signal Routing/Multiport Switch', ...
    [model_name '/ModeSwitch'], ...
    'Inputs',   '4', ...
    'Position', [180 55 220 305]);

add_line(model_name, 'ctrl_ws/1',       'ModeSwitch/1', 'autorouting','on');
for cl = 1:4
    add_line(model_name, [noms{cl} '/1'], ['ModeSwitch/' num2str(cl+1)], 'autorouting','on');
end

%% ── Sous-systeme Capteur ICM-20948 ──────────────────────────────────────────
add_block('simulink/Ports & Subsystems/Subsystem', ...
    [model_name '/Capteur_ICM20948'], 'Position', [290 155 430 205]);

sub = [model_name '/Capteur_ICM20948'];
blks = find_system(sub,'SearchDepth',1,'type','block');
for i=1:length(blks)
    if ~strcmp(blks{i},sub), delete_block(blks{i}); end
end
delete_line(find_system(sub,'FindAll','on','type','line'));

add_block('simulink/Sources/In1',   [sub '/In1'],  'Position',[30  130 60 160]);
add_block('simulink/Discrete/Discrete Transfer Fcn', [sub '/DLPF'], ...
    'Numerator','b_dlpf','Denominator','a_dlpf','SampleTime',num2str(1/fs), ...
    'Position',[110 125 240 165]);
bruit_power = sigma_bruit^2*(1/fs);
add_block('simulink/Sources/Band-Limited White Noise',[sub '/Bruit'], ...
    'Cov',num2str(bruit_power),'Ts',num2str(1/fs),'Seed','4321', ...
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

%% ── Scope signal brut ────────────────────────────────────────────────────────
add_block('simulink/Sinks/Scope',[model_name '/Scope_signal'], ...
    'Position',[490 100 540 140]);
add_line(model_name,'Capteur_ICM20948/1','Scope_signal/1','autorouting','on');

%% ── Buffer circulaire (MATLAB Function) ─────────────────────────────────────
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [model_name '/Buffer'], 'Position',[490 170 610 220]);
add_line(model_name,'Capteur_ICM20948/1','Buffer/1','autorouting','on');

%% ── Extraction features (MATLAB Function) ───────────────────────────────────
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [model_name '/Features'], 'Position',[660 170 780 220]);
add_line(model_name,'Buffer/1','Features/1','autorouting','on');

%% ── Classifieur k-NN (MATLAB Function) ──────────────────────────────────────
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [model_name '/Classifieur'], 'Position',[830 170 960 220]);
add_line(model_name,'Features/1','Classifieur/1','autorouting','on');

%% ── To Workspace label detecte ───────────────────────────────────────────────
add_block('simulink/Sinks/To Workspace',[model_name '/label_detecte_ws'], ...
    'VariableName','label_detecte','MaxDataPoints','inf','SaveFormat','Array', ...
    'Position',[1010 180 1110 210]);
add_line(model_name,'Classifieur/1','label_detecte_ws/1','autorouting','on');

%% ── Scope comparaison (2 voies : classe reelle vs classe detectee) ───────────
add_block('simulink/Sinks/Scope',[model_name '/Scope_classes'], ...
    'NumInputPorts','2','Position',[1010 280 1060 330]);
add_line(model_name,'ctrl_ws/1',        'Scope_classes/1','autorouting','on');
add_line(model_name,'Classifieur/1',    'Scope_classes/2','autorouting','on');

%% ── Injection automatique des scripts dans les blocs MATLAB Function ─────────
sf     = sfroot();
mdl_sf = sf.find('-isa','Simulink.BlockDiagram','Name',model_name);

blocs_fn = {'Buffer','Features','Classifieur'};
fichiers  = {'buffer_fn.m','features_fn.m','classifieur_fn.m'};

for i = 1:3
    ch = mdl_sf.find('-isa','Stateflow.EMChart', ...
                     'Path',[model_name '/' blocs_fn{i}]);
    if ~isempty(ch)
        ch.Script = fileread(fichiers{i});
        fprintf('  Script injecte : %s\n', blocs_fn{i});
    else
        fprintf('  AVERTISSEMENT : bloc %s non trouve\n', blocs_fn{i});
    end
end

save_system(model_name);

fprintf('\n== simul4.slx cree ==\n');
fprintf('Duree : %d s  (4 modes x %d s)\n', T_total, T_mode);
fprintf('Sequence : Arret(0s) → Camion(60s) → Train(120s) → Avion(180s)\n');
