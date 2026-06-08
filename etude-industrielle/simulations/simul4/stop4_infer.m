%% stop4_infer.m — Analyse des resultats apres la simulation d'inference
% StopFcn de simul4inference.slx
%
% label_detecte est desormais a la cadence T_hop = 5 s (bloc Buffer DSP).
% 240 s / 5 s = 48 fenetres au total.

fprintf('\n=== Fin simulation inference ===\n');

if ~exist('label_detecte','var')
    fprintf('  label_detecte non disponible — verifiez le bloc To Workspace.\n');
    return;
end

%% Parametres de cadence
T_hop    = N_win / fs;               % 10 s — periode reelle de sortie du bloc Buffer
T_mode   = 60;                        % s par mode (inference)
T_total  = 240;                       % s total simulation inference
N_frames = floor(T_total / T_hop);    % 48 fenetres

%% Reconstruction du vrai label a la cadence T_hop
t_frames = (0 : N_frames-1)' * T_hop;   % [0, 5, 10, ..., 235] s
y_true   = ones(N_frames, 1);
y_true(t_frames >= T_mode)   = 2;
y_true(t_frames >= 2*T_mode) = 3;
y_true(t_frames >= 3*T_mode) = 4;

%% Alignement (securite si label_detecte a moins de N_frames entrees)
ld = label_detecte(:);
n  = min(length(ld), N_frames);

%% Suppression de la premiere fenetre (demarrage buffer — donnees partielles)
i_debut = 2;
if n < i_debut + 1
    fprintf('  Pas assez de donnees pour evaluer.\n');
    return;
end

y_det = ld     (i_debut:n);
y_ref = y_true (i_debut:n);

%% Taux global
correct = sum(y_det == y_ref);
taux    = correct / length(y_ref) * 100;

MODES_loc = {'Arret','Camion','Train','Avion'};
fprintf('  Fenetres evaluees : %d  (premiere exclue — demarrage)\n', length(y_ref));
fprintf('  Taux de bonne classification : %.1f %%\n', taux);

%% Detail par classe
fprintf('\n  Detail par classe :\n');
for cl = 1:4
    mask = (y_ref == cl);
    if sum(mask) > 0
        ok_cl = sum(y_det(mask) == cl) / sum(mask) * 100;
        fprintf('    %s : %.1f %%\n', MODES_loc{cl}, ok_cl);
    end
end
