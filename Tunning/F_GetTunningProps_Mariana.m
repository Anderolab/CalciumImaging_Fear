function [Output,SexPerNeuron,AnimalPerNeuron,ResponseType,TOI,TOR,STD_Distance, Responses] = F_GetTunningProps_Mariana (Experiment,...
    TunningEpochs, ReferenceEpochs, Dataset, Iterations, group_dir, group_name)

%% STEP 1 - GENERATING THE STORAGE OUTPUTS
Expected = [];
Observed = [];
StandDevs = [];
STD_Distance = [];
Active = [];
Inhibited = [];
AllTraces = [];
Report = [];
lengths = [];
ResponseType = [];
AnimalPerNeuron = [];
SexPerNeuron = [];

save_path = group_dir
prompt = strcat("   Results will be saved @ ", save_path);

Report = [Report; prompt; ""];
fprintf('% s\n', prompt)

if isempty(ReferenceEpochs)
    prompt = strcat("The reference is the entire session");
    Report = [Report; prompt; ""];
    fprintf('% s\n', prompt)
else
    prompt = strcat("The reference is ", strjoin(ReferenceEpochs, ', '));
    Report = [Report; prompt; ""];
    fprintf('% s\n', prompt)
end


%% STEP 2 - IDENTIFYING OUTLIERS BEFORE PERFORMING THE TEST
% Identifying the animals

an_s = fieldnames(Dataset);
Animals = string(regexp(string(an_s(1:end)), '\d*', 'Match'));

% Finding all trial lengths;
c = 1;
for animal = Animals.'
    lengths(c) = size(Dataset.('M'+animal).("Raw"), 2);
    c = c+1;
end

% Identifying outliers
outliers = isoutlier(lengths, "mean"); % we have to CHECK this

% Reporting outliers to the user
for i = 1:sum(outliers)
    out_an = Animals(outliers);
    out_len = string(lengths(outliers));
    prompt = strcat("       Animal ", ...
        out_an(i), " was identified as an outlier with ",  ...
        out_len(i), ' frames.');
    fprintf('%s\n', prompt)
    Report = [Report; "   OUTLIER DETECTION:"; prompt];
end

% Visualising the outliers
boxplot(lengths)
xticks([])
ylabel("Frames (n)")

% Croppig all sessions and notifying the user
len = min(lengths);
prompt = strcat("       All sessions will be cropped to ", ...
    num2str(len), " frames.");
Report = [Report; prompt; ""];
fprintf('%s\n', prompt)

% Removing outliers
Animals = Animals(outliers == 0);

% Saving current figure
savename = strcat(save_path, "\Tunning - Outliers.pdf");
exportgraphics(gcf, savename, "ContentType", "vector")

%% STEP 3 - GENERATING MAIN OUTPUT TABLE

% Generating the output table
Output = table()
Output.Animal = double(Animals)
Sexes = string(Experiment.Project.Groups)
Output.Sex = Sexes(Output.Animal);

% % Adjusting column names based on TunningEpochs content
% if strcmp(TunningEpochs, "ROI")
%     % Case when all ROIs are analyzed
%     Excited_ColName = "All ROI Excited IX";
%     Inhibited_ColName = "All ROI Inhibited IX";
%     ExcitedP_ColName = "Probability of All ROI Excited";
%     InhibitedP_ColName = "Probability of All ROI Inhibited";
% elseif startsWith(TunningEpochs, "ROI")
%     % Case when a specific ROI is analyzed
%     Excited_ColName = strcat(TunningEpochs, " Excited IX");
%     Inhibited_ColName = strcat(TunningEpochs, " Inhibited IX");
%     ExcitedP_ColName = strcat("Probability of ", TunningEpochs, " Excited");
%     InhibitedP_ColName = strcat("Probability of ", TunningEpochs, " Inhibited");
% end

Excited_ColName = strcat(TunningEpochs, " Excited IX");
Inhibited_ColName = strcat(TunningEpochs, " Inhibited IX");
ExcitedP_ColName = strcat("Probability of ", TunningEpochs, " Excited");
InhibitedP_ColName = strcat("Probability of ", TunningEpochs, " Inhibited");

% Generating the storage variable columns
Output.(Excited_ColName) = repelem({""}, length(Animals)).';
Output.(Inhibited_ColName) = repelem({""}, length(Animals)).';
Output.(ExcitedP_ColName) = zeros(length(Animals), 1);
Output.(InhibitedP_ColName) = zeros(length(Animals), 1);

% For figures
Ep_ = {ExcitedP_ColName, InhibitedP_ColName};

%% STEP 5 - PERFORMING THE TEST
  
% Looping through animals
c = 1; % Counter function
all_binarised=[];
max_len = 0;

for an = Animals.'
    wb_ = waitbar(0, strcat("Identifying responsive neurons in animal ", num2str(an)));
    prompt = strcat("   Processing animal ", num2str(an));
    fprintf('%s\n', prompt)
    Report = [Report; prompt];

    % Generación de TOI y TOR específicos para cada animal
    Task = Dataset.(strcat('M', num2str(an))).Task; % Accediendo a la Task de cada animal
    length(Task.Titles)
    TOI = []; % Time of Interest
    TOR = []; % Time of Reference

    if isempty(ReferenceEpochs)
        % if you want to compare to the entire session
        for i = 1:length(Task.Titles)
            if startsWith(Task.Titles{i}, TunningEpochs)
                TOI = [TOI, Task.Start(i):(Task.Start(i)+Task.Frames(i))];
            else 
                TOR = [TOR, Task.Start(i):(Task.Start(i)+Task.Frames(i))];
            end
        end
    else
        % If you want to compare to a specific epoch
        for i = 1:length(Task.Titles)
            for x = 1:length(ReferenceEpochs)
                if startsWith(Task.Titles{i}, ReferenceEpochs{x})
                    TOR = [TOR, Task.Start(i):(Task.Start(i)+Task.Frames(i))];

                elseif startsWith(Task.Titles{i}, TunningEpochs)
                    TOI = [TOI, Task.Start(i):(Task.Start(i)+Task.Frames(i))];
                    
                end
            end
        end
    end
   
    disp(TOI)    
    disp(TOI)

    % Creación del binarizado para comparación
    len_an = length(Dataset.(strcat('M', num2str(an))).Raw); % Longitud de las trazas neuronales del animal
    BinarisedTask = repelem("0", len_an);
    BinarisedTask(TOI) = "1";
    %max_len = max(max_len, len);
    
    length(BinarisedTask)

    % Convertir BinarisedTask a número (para poder usar NaN)
    %BinarisedTaskNumeric = double(string(BinarisedTask) == "1");

    % Aquí continúa el análisis como en la versión anterior
    % Gathering the animal specific data
    Maxims = double(islocalmax(Dataset.(strcat('M', num2str(an))).Filt(:, 1:len_an), 2));
    Peaks = string(Maxims);
    length(Peaks)
    Intersect = BinarisedTask + Peaks;
    % Identifying the parameters for each neuron
    oo = sum(Intersect == "00", 2);
    lo = sum(Intersect == "10", 2);
    ol = sum(Intersect == "01", 2);
    ll = sum(Intersect == "11", 2);

    Obv = F_ComputePhi(oo, ol, lo, ll);

    % Computing Phi
    Observed = [Observed; Obv];

    % Iterating to attain the expected
    % Expected_Scores = gpuArray(zeros(size(Maxims, 1), Iterations));
    Expected_Scores = zeros(size(Maxims, 1), Iterations);

    for iter = 1:Iterations
        waitbar(iter/Iterations);
        Rand_Peaks = Peaks(:, randperm(len_an));
        Intersect_Rand = BinarisedTask + Rand_Peaks;
        oo = sum(Intersect_Rand == "00", 2);
        lo = sum(Intersect_Rand == "10", 2);
        ol = sum(Intersect_Rand == "01", 2);
        ll = sum(Intersect_Rand == "11", 2);
        Expected_Scores(:, iter) = F_ComputePhi(oo, ol, lo, ll);
    end

    Exp = mean(Expected_Scores, 2);
    Expected = [Expected; Exp];
    SDs = std(Expected_Scores, [], 2);
    StandDevs = [StandDevs; SDs];
    Distances = (Obv - Exp) ./ SDs;
    
    STD_Distance = [STD_Distance; Distances];

    % Saving the activated and inhibited neurons
    
    size(Dataset.(strcat('M', num2str(an))).Filt(Distances > 1.96, 1:len))
    Active = [Active; Dataset.(strcat('M', num2str(an))).Filt(Distances > 1.96, 1:len)];
    size(Active)
    Inhibited = [Inhibited; Dataset.(strcat('M', num2str(an))).Filt(Distances < -1.96, 1:len)];
    % All traces
    AllTraces = [AllTraces; Dataset.(strcat('M', num2str(an))).Filt(:, 1:len)];

    % Saving the results in the output table
    Excit = find(Distances > 1.96);
    Inhibit = find(Distances < -1.96);
    Output.(Excited_ColName)(c) = {Excit};
    Output.(Inhibited_ColName)(c) = {Inhibit};
    Output.(ExcitedP_ColName)(c) = 100 * length(Excit) / size(Maxims, 1);
    Output.(InhibitedP_ColName)(c) = 100 * length(Inhibit) / size(Maxims, 1);

    % For the frequency test
    Tunning_ = repelem("Unresponsive", length(Distances));
    Tunning_(Excit) = "Excited";
    Tunning_(Inhibit) = "Inhibited";
    ResponseType = [ResponseType, Tunning_];

    % Saving the animal and sex information
    AnimalPerNeuron = [AnimalPerNeuron, repelem(an, length(Distances))]
    SexPerNeuron = [SexPerNeuron; repmat({Experiment.Project.Groups{double(an)}}, length(Distances), 1)];
    length(SexPerNeuron)
    prompt = strcat("       ", num2str(length(Excit)), " stimulus-excited neurons have been identified for animal ", num2str(an));
    fprintf('%s\n', prompt)
    Report = [Report; prompt];
    prompt = strcat("       ", num2str(length(Inhibit)), " stimulus-inhibited neurons have been identified for animal ", num2str(an));
    fprintf('%s\n', prompt)
    Report = [Report; prompt];

    % Si BinarisedTask es más corto que el más largo hasta ahora, rellenar con NaN
    % if len_an < max_len
    %     BinarisedTaskNumeric = [BinarisedTaskNumeric, nan(1, max_len - len_an)];
    % end
    
    % Añadir BinarisedTask a la matriz all_binarised
    all_binarised = [all_binarised; BinarisedTask(1:len)];

    c = c + 1;
    close(wb_);
end

length(Distances)
Output

%% STEP 6 - GENERATING THE VISUALISATIONS
% First figure - Methods
    [~, sort_ix] = sort(Observed);
    F_FillArea(Expected(sort_ix).', (StandDevs(sort_ix).*1.96).', ...
        'k', 1:length(Expected(sort_ix)))
    hold on
    plot(Expected(sort_ix), "Color", 'k')
    hold on
    plot(Observed(sort_ix), "Color", 'r', "LineWidth", 2)
    O = Observed(sort_ix);
    STD_Sorted = STD_Distance(sort_ix);
    sig_ix = find(abs(STD_Sorted) > 1.96);
    scatter(sig_ix, O(sig_ix), 20, 'K', 'filled')
    hold off
    legend(["95% CI", "Expected", "Observed", "Significant"], ...
        "Location","northwest");
    xlim([1, length(Observed)])
    xlabel("Neuron", "FontSize", 12)
    ylabel("\phi Coefficient", "FontSize", 12)
    set(gcf,'Position',[400 100 300 400])
    box off
    hold off
    savename = strcat(save_path, "\Tunning - Neuron identification.pdf");
    exportgraphics(gcf, savename, "ContentType","vector")

%%
% Third figure - Individual-neuron level visualization
close all;
Fig_ = figure;
Fig_.Position = [400, 100, 600, 500];

% Selecting the top five excited and inhibited neurons;
Sorted = sort(Observed, 'ascend');
TopInactive = AllTraces(Observed <= Sorted(5), :);
TopActive = AllTraces(Observed >= Sorted(end-4),:);

% Combine top neurons for plotting
TopNeurons = [TopInactive; TopActive];
%TopNeurons = normalize(TopNeurons, 2, 'range', [0, 1]);
% Define el espacio inicial para la primera neurona
espacioInicial = 0.1;

% Almacena la altura acumulada para saber dónde comenzar la siguiente neurona
alturaAcumulada = 0;

AnimalPerNeuron=str2double(AnimalPerNeuron);
alturaPorNeurona = 0.1;
% Plot each neuron with its corresponding BinarisedTask
for i = 1:size(TopNeurons, 1)
    hold on;
    
    % Find out which animal this neuron belongs to
    neuronIndex = find(ismember(AllTraces, TopNeurons(i, :)), 1, 'first');
    
    neuronAnimalIndex = AnimalPerNeuron(neuronIndex)
    
    % Calcular el pico más alto para la traza actual
    picoMasAlto = max(TopNeurons(i, :));
    
    % Calcular los límites en Y para la neurona actual basándose en el pico más alto
    YlimiteInferior = alturaAcumulada + espacioInicial;
    YlimiteSuperior = YlimiteInferior + picoMasAlto;
    
    % Actualizar la altura acumulada para la siguiente neurona
    alturaAcumulada = YlimiteSuperior + espacioInicial;

    % Obtiene el BinarisedTask para esta neurona
    BinarisedTaskAnimal = double(all_binarised(neuronAnimalIndex, :));

    % Encuentra los índices donde la neurona está activa
    indicesActivos = find(BinarisedTaskAnimal == 1);
    % Dibuja las franjas verticales para los índices activos
    for idx = 1:length(indicesActivos)
        j = indicesActivos(idx);
        if j < length(BinarisedTaskAnimal)  % Asegurarse de que no estamos en el último índice
            fill([j j j+1 j+1], [YlimiteInferior YlimiteSuperior YlimiteSuperior YlimiteInferior], [0.7 0.7 0.7], 'EdgeColor', 'none', 'FaceAlpha', .3);
        end
    end

    % Crea una nueva matriz para pintar solo donde BinarisedTaskAnimal es 1
    % BinarisedTaskParaPintar = zeros(size(BinarisedTaskAnimal));
    % BinarisedTaskParaPintar(BinarisedTaskAnimal == 1) = YlimiteSuperior;


    % % Ajusta BinarisedTaskAnimal para pintarlo solo en la sección de esta neurona
    % BinarisedTaskAnimal = BinarisedTaskAnimal * (YlimiteSuperior -YlimiteInferior) + YlimiteInferior;
    
    % Plot the BinarisedTask for this neuron
    %area(BinarisedTaskAnimal .* 13, 'EdgeColor', 'none', 'FaceAlpha', .3, 'FaceColor', [0.8 0.8 0.8]);
    % Dibuja el área ajustada
    %area(BinarisedTaskParaPintar, 'EdgeColor', 'none', "FaceAlpha", .3, 'FaceColor', [0.8 0.8 0.8]);
    % Determine the color based on the index
    if i <= 5
        color = [76, 148, 199]./255; % Blue for inhibited neurons
    else
        color = [212, 100, 66]./255; % Red for excited neurons
    end
    
    % Plot the neuron trace
    plot(TopNeurons(i, :) + YlimiteInferior, 'Color', color);
end
% Ajustar los límites del gráfico para acomodar todas las trazas
ylim([0, alturaAcumulada]);
xlim([1, size(TopNeurons, 2)])
xlabel("Time (Frames)");
ylabel("Filtered fluorescence");
%set(gca, 'YTick', arrayfun(@(y) y + espacioInicial, 0:alturaAcumulada/size(TopNeurons, 1):alturaAcumulada, 'UniformOutput', false));
set(gca, 'YTickLabel', arrayfun(@(x) sprintf('Neuron %d', x), 1:size(TopNeurons, 1), 'UniformOutput', false));

% Save the figure
savename = strcat(save_path, "\Tunning - Sample Neurons.pdf");
exportgraphics(Fig_, savename, "ContentType", "vector");

close all

Properties = [sum(STD_Distance > 1.96, 'All'), ...
    sum(STD_Distance < -1.96, 'All')];
Properties(end+1) = length(STD_Distance) - sum(Properties);
pie(Properties)
ax = gca();
ax.Colormap = [212, 100, 66; 76, 148, 199; 200, 200, 200]./255; 
legend(["Active", "Inactive", "Unresponsive"], "Location", ...
    "northeast")
F_ = gcf;
F_.Position = [400, 100, 390, 320];
savename = strcat(save_path, "\Tunning - Ratios.pdf");
exportgraphics(gcf, savename, "ContentType", "vector")

%% STEP 7 - CLOSING
% Saving the report
savename = strcat(save_path, "\Report.txt");
writelines(Report,savename);
% And the data
savename = strcat(save_path, "\TunningOutput_", group_name, "_", TunningEpochs,".mat");
Tunning = Output;
save(savename, "Tunning");

% Generating the frequency table
Responses = table();
size(SexPerNeuron)
size(ResponseType)
size(AnimalPerNeuron)
Responses.Sex = SexPerNeuron;
Responses.Animal = AnimalPerNeuron.';
Responses.ResponseType = ResponseType.';

% And saving it
savename = strcat(save_path, "\SingleNeuronResponses_", group_name, "_", TunningEpochs,".mat");
save(savename, "Responses");
savename_chi = strcat(save_path, "\SingleNeuronResponses.csv");
writetable(Responses, savename_chi);


