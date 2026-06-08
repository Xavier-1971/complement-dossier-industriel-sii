%% stop4.m — Arrêt propre de la simulation simul4

% Arrêt de la simulation si en cours
if bdIsLoaded('simul4')
    if strcmp(get_param('simul4','SimulationStatus'), 'running')
        set_param('simul4', 'SimulationCommand', 'stop');
        fprintf('Simulation simul4 arrêtée.\n');
    end
end
