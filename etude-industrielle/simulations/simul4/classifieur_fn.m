function label = classifieur_fn(feat)
%CLASSIFIEUR_FN  Classification k-NN (k=3)
%  Entree : feat   vecteur 1x6 (issu de features_fn)
%  Sortie : label  scalaire 1=Arret 2=Camion 3=Train 4=Avion
%  Le classifieur ne tourne que lorsque feat a change (gain de temps)
coder.extrinsic('predict_wrapper');

persistent last_feat last_label
if isempty(last_feat)
    last_feat  = zeros(1, 6);
    last_label = double(1);
end

% Calcul uniquement si nouvelles features disponibles
if any(feat ~= last_feat)
    last_label = double(0);
    last_label = predict_wrapper(feat);
    last_feat  = feat;
end

label = last_label;
end
