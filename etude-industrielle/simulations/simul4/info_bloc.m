%% info_bloc.m — Affiche les paramètres du dernier bloc ajouté dans simul4
% Usage : exécuter cette ligne après avoir ajouté un bloc dans simul4.slx

model = 'simul4';

% Récupère tous les blocs du modèle
blocs = find_system(model, 'Type', 'Block');

if isempty(blocs)
    fprintf('Aucun bloc trouvé dans %s.\n', model);
    return;
end

% Dernier bloc ajouté (dernier de la liste)
chemin = blocs{end};
nom    = get_param(chemin, 'Name');
type   = get_param(chemin, 'BlockType');

fprintf('\n══════════════════════════════════════════════════\n');
fprintf('  Bloc    : %s\n', nom);
fprintf('  Chemin  : %s\n', chemin);
fprintf('  Type    : %s\n', type);
fprintf('──────────────────────────────────────────────────\n');

% Récupère et affiche tous les paramètres
params = get_param(chemin, 'ObjectParameters');
champs = fieldnames(params);

for i = 1:length(champs)
    try
        val = get_param(chemin, champs{i});
        if ischar(val) && ~isempty(val)
            fprintf('  %-25s : %s\n', champs{i}, val);
        end
    catch
        % paramètre non lisible, on ignore
    end
end

fprintf('══════════════════════════════════════════════════\n');
