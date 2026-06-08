%% stop4_train.m — Entraine le k-NN apres la simulation d'entrainement
% StopFcn de simul4entrainement.slx
%
% Le bloc Buffer DSP ne sort qu'une fenetre complete a chaque pas T_hop = 5 s.
% Toutes les lignes de feat_out / label_out sont donc valides.

fprintf('\n=== Fin simulation entrainement ===\n');

%% Recuperation des sorties
if ~exist('feat_out','var') || ~exist('label_out','var')
    error('Variables feat_out / label_out introuvables.');
end

% Normalisation vers [N x 6] et [N x 1] (format selon version MATLAB/Simulink)
if ndims(feat_out) == 3            % format [1 x 6 x N]
    feat_2d = squeeze(permute(feat_out, [3 2 1]));   % -> [N x 6]
elseif size(feat_out, 1) == 6     % format [6 x N]
    feat_2d = feat_out';                              % -> [N x 6]
else
    feat_2d = feat_out;            % deja [N x 6]
end

% Alignement : Buffer et ctrl_5s peuvent differ d'un pas (t=0 ou t=StopTime)
n = min(size(feat_2d, 1), length(label_out(:)));
fprintf('  feat_out  : %d fenetres x %d features\n', size(feat_2d,1), size(feat_2d,2));
fprintf('  label_out : %d entrees\n', length(label_out(:)));
fprintf('  Retenu    : %d fenetres\n', n);

X_train = feat_2d(1:n, :);
y_train = label_out(1:n);
y_train = y_train(:);

MODES_loc = {'Arret','Camion','Train','Avion'};
fprintf('  Fenetres collectees : %d  (6 features chacune)\n', size(X_train, 1));
for cl = 1:4
    fprintf('    %s : %d\n', MODES_loc{cl}, sum(y_train == cl));
end

if size(X_train, 1) < 4
    warning('Pas assez de fenetres — verifiez la simulation.');
    return;
end

%% Entrainement k-NN (k=3, normalisation z-score)
mdl_knn = fitcknn(X_train, y_train, ...
    'NumNeighbors', 3, ...
    'Standardize',  true);

%% Validation croisee 5-fold
cv  = crossval(mdl_knn, 'KFold', 5);
err = kfoldLoss(cv);
fprintf('\n  Erreur validation croisee 5-fold : %.1f %%\n', err*100);
fprintf('  mdl_knn disponible — lancez simul4inference.slx\n');
