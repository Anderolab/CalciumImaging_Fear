%% STEP 1 - LOADING THE REQUIRED DATASETS

% Loading and fixing the required datasets
[filename, filepath] = uigetfile('*.mat', 'Select an Experiment File to Load');

if isequal(filename, 0)  % If user cancels the file selection
    disp('File selection canceled');
else
    load(fullfile(filepath, filename));  % Directly load the selected file
end

Paradigm = fields(Experiment);
Paradigm = char(Paradigm(1));
Intervals = Experiment.(Paradigm).M1.Task.Titles;

[filepath] = uigetdir('Where do you want to save your results?');

results_path = strcat(filepath,"\ResultsTunning_", Paradigm);
mkdir(results_path);

%% Choose Subset of Animals

%make different groups 1. How many groups 2. Choose animals per group 3.
%Create animals to delete 4. Continue with the code (make the different Experiments)

% Ask the user for the number of lists
x = input('Enter the number of lists: ');

% Initialize structures to store the lists 
lists = struct();
all_numbers = []; % Array to store all numbers

% Loop through to get names and numbers for each list
for i = 1:x
    list_name = input(sprintf('Enter a name for list %d: ', i), 's'); % Get list name
    
    % Create a target directory with timestamp
    timestamp = string(datetime(floor(now), 'ConvertFrom', 'datenum'));
    target_path = fullfile(results_path, list_name + " " + timestamp);

    % Get numbers for the list
    fprintf('Enter numbers for "%s" (separated by spaces): ', list_name);
    numbers = input('', 's'); % Get user input as string
    numbers = str2num(numbers); % Convert string input to numerical array
    
    % Store the list 
    lists.(list_name) = numbers;
    all_numbers = [all_numbers, numbers];

end

% Find the largest number
if ~isempty(all_numbers)
    max_number = max(all_numbers);
else
    disp('No numbers were entered.');
end

% Display the lists 
disp('Here are your lists:');
disp(lists);

%% Good Neurones Selection

[good_neurones_path] = uigetdir('*.mat', 'Select an Good Neurones Folder');

Experiment = eliminarMalasNeuronas(Experiment, Paradigm, good_neurones_path);

%% Find the animals to exclude

full_range = 1:max_number;
field_names = fieldnames(lists); % Get all list names

for i = 1:numel(field_names)
    original_list = lists.(field_names{i}); % Get the original list
    new_list = setdiff(full_range, original_list); % Remove original numbers from full range
    lists.(field_names{i}) = new_list; % Update the list
end

%% Make the different experiments

Experiment_grouped = [];

for i = 1:numel(field_names)
    Experiment_grouped.(field_names{i}) = removeAnimalAndGroup(Experiment, Paradigm, lists.(field_names{i}));
end 

%% Choose Analysis Option - START FROM HERE TO PERFORM ANOTHER ANALYSIS 


choice = input('Do you want to analyze (1) All Tones/Shock/ITI or (2) Binned? Enter 1 or 2: ');
if choice == 1
    for i = 1:numel(field_names)
        Experiment1 = Experiment_grouped.(field_names{i});
        animals1 = fields(Experiment1.(Paradigm));
        for y = 1:numel(animals1)
            titles = Experiment1.(Paradigm).(animals1{y}).Task.Titles;
            titles = regexprep(titles, '\d+', '');
            Experiment1.(Paradigm).(animals1{y}).Task.Titles = titles;
        end
        Experiment_grouped.(field_names{i}) = Experiment1;
    end 
elseif choice == 2
    num_bins = input('How many bins do you want? ');
    Bins = struct();

    for i = 1:num_bins
        prompt = sprintf('Enter tones/shocks for Bin %d (separated by spaces): ', i);
        bin_contents = input(prompt, 's');  % Get input as a string
        bin_contents = strsplit(bin_contents, ' ');
        Bins.(sprintf('Bin%d', i)) = bin_contents;
    end 

for i = 1:numel(field_names)
        Experiment1 = Experiment_grouped.(field_names{i});
        animals1 = fields(Experiment1.(Paradigm))
        for y = 1:numel(animals1)
            titles = Experiment1.(Paradigm).(animals1{y}).Task.Titles; %Titles del singolo animale
            for a = 1:numel(titles)
                for b = 1:num_bins
                    bin_items = Bins.(sprintf('Bin%d', b));
                    for j = 1:numel(bin_items)
                        if contains(titles{a}, bin_items{j})
                            % Split the title into two words
                            words = strsplit(titles{a}, ' ');
                            % Check if the second word is a number and matches 'b'
                            if numel(words) == 2 && strcmp(words{2}, bin_items{j})
                                titles{a} = strcat(words{1}, " ", num2str(b)); % Keep the first word, remove the number
                                titles{a} = titles{a}{1};
                            end
                        end
                    end
                end
            end
            Experiment1.(Paradigm).(animals1{y}).Task.Titles = titles;
        end 
        Experiment_grouped.(field_names{i}) = Experiment1;
    end

else
    disp('Invalid choice. Please enter 1 or 2.');
end

%% Setting up analysis - To be repeated for every analysis

Iterations = 5; % 1000 for the real test

unique_titles = unique(titles);
fprintf('Intervals:\n');
fprintf('- %s\n', unique_titles{:});
prompt = sprintf('What interval do you want to analyse: ', i);
focus_analysis = input(prompt, 's');  
remaining_titles = setdiff(unique_titles, focus_analysis, 'stable');

ReferenceEpochs = {};
while true
    % Ask the user for input
    prompt = 'Do you want to take a specific interval as reference? If yes, write it. If done, press Enter: ';
    ref = input(prompt, 's');  % Get input as a string
    % Stop if the user presses Enter without input
    if isempty(ref)
        break;
    end
    % Add the input to the list
    ReferenceEpochs{end + 1} = ref;
end

% Make new dir
timestamp = string(datetime(floor(now), 'ConvertFrom', 'datenum'));
analysis_path = fullfile(results_path + "\" + focus_analysis + "_" + timestamp);
mkdir(analysis_path)

%% Anayse every group of animals 

for i = 1:numel(field_names)
    % Make new directory for analysis 
    group_dir = fullfile(analysis_path + '\' + field_names{i})
    mkdir(group_dir)
    
    % Analysis 
    Neurons = Experiment_grouped.(field_names{i}).(Paradigm);
    
    [Output,SexPerNeuron,AnimalPerNeuron,ResponseType,TOI,TOR,STD_Distance,...
        Responses_VEH] = F_GetTunningProps_Mariana(Experiment_grouped.(field_names{i}), focus_analysis, ...
        ReferenceEpochs, Neurons, Iterations, group_dir, field_names{i});

end 


