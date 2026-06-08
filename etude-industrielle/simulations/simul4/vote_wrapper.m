function label = vote_wrapper(idx)
%VOTE_WRAPPER  Recupere les labels des k voisins et retourne le vote majoritaire
%  idx   : vecteur 1xk d'indices dans y_train (retourne par KNN Search)
%  label : scalaire — classe majoritaire parmi les k voisins
y_tr  = evalin('base', 'y_train');
votes = y_tr(round(idx(:)));
label = double(mode(votes));
end
