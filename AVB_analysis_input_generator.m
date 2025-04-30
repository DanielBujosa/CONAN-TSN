function [] = AVB_analysis_input_generator(exp_ID)

rng('shuffle');

%load(sprintf('Experiment%i/TT_Messages.mat',exp_ID),"TT_Messages");
%message_TT = TT_Messages;
%load(sprintf('Experiment%i/AVB_Messages.mat',exp_ID),"AVB_Messages");
%message_AVB = AVB_Messages;
%load(sprintf('Experiment%i/BE_Messages.mat',exp_ID),"BE_Messages");
%message_BE = BE_Messages;

load(sprintf('Experiment%i/TT_Messages.mat',exp_ID),'message_TT');
load(sprintf('Experiment%i/AVB_Messages.mat',exp_ID),'message_AVB');
load(sprintf('Experiment%i/BE_Messages.mat',exp_ID),'message_BE');


%load(sprintf('Experiment%i/Routes.mat',exp_ID),"Routes");
%route = Routes;
%load(sprintf('Experiment%i/Architecture.mat',exp_ID),"Architecture");
%architecture = Architecture;

load(sprintf('Experiment%i/Routes.mat',exp_ID),'route');
load(sprintf('Experiment%i/Architecture.mat',exp_ID),'architecture');


fid = fopen(sprintf('Experiment%i/AVB_Input.txt',exp_ID),'wt');

if isstruct(message_TT) && isfile(sprintf('Experiment%i/Schedule.txt',exp_ID))
    schedule = readmatrix(sprintf('Experiment%i/Schedule.txt',exp_ID));
    STschedule_to_file(message_TT, route, architecture, 'ST', fid, schedule);
end
if isstruct(message_AVB)
    struct_to_file(message_AVB, route, architecture, 'ClassA', fid, 0);
end
if isstruct(message_BE)
    struct_to_file(message_BE, route, architecture, 'NRT', fid, 0);
end

fclose(fid);

end

function [] = struct_to_file(message_struct, route, architecture, type, file, other_files)

if other_files ~= 0
    start = extractBetween(other_files,'<block start="','" duration');
    creator = extractBetween(other_files,'creator="','"/>');
end

for i = 1:length(message_struct)
    fprintf(file, 'message\n');
    fprintf(file, sprintf('length = %i\n',message_struct(i).length));
    fprintf(file, sprintf('period = %i\n',(message_struct(i).period + message_struct(i).min_inter_arr_time)));
    %if message_struct(i).deadline > 0
        %fprintf(file, sprintf('deadline = %i\n',message_struct(i).deadline));
    %end
    %fprintf(file, sprintf('deadline = %i\n',(message_struct(i).period + message_struct(i).min_inter_arr_time)));
    fprintf(file, sprintf('deadline = %i\n',message_struct(i).deadline));
    %if type == "ClassA" && message_struct(i).deadline > 8000
    %if type == "ClassA" && message_struct(i).period < message_struct(i).deadline
    if type == "ClassA" && message_struct(i).deadline > 8000
        fprintf(file, 'priority = ClassB\n');
    else
        fprintf(file, sprintf('priority = %s\n',type));
    end
    %fprintf(file, sprintf('priority = %s\n',type));
    path = route{message_struct(i).destination, message_struct(i).source}{message_struct(i).path}(:);
    num_links = length(path) - 1;
    fprintf(file, sprintf('linkNbr = %i\n',num_links));
    for j = 1:num_links
        fprintf(file, sprintf('link = %i\n',find(architecture(:,1) == path(j) & architecture(:,2) == path(j+1))));
    end
    if strcmp(type,'ST')
        fprintf(file, 'jitterIn = 0\n');
        fprintf(file, 'initOffset = 0\n');
        offsets = [];
        k = 1;
        for j = 1:length(start)
            if strcmp(creator{j},sprintf('m%i_0',i))
                offsets(k) = str2num(start{j});
                k = k + 1;
            end
        end
        offsets = sort(offsets);
        for j = 1:length(offsets)
            fprintf(file, sprintf('offset = %i\n',offsets(j)));
        end
    else
        fprintf(file, sprintf('jitterIn = %i\n',message_struct(i).jitter_transmission));
        fprintf(file, 'initOffset = 0\n');
    end
    fprintf(file, '\n');
end
end

function [] = STschedule_to_file(message_struct, route, architecture, type, file, schedule)
    for i = 1:length(message_struct)
        P = message_struct(i).period;% + message_struct(i).min_inter_arr_time;
        path = route{message_struct(i).destination, message_struct(i).source}{message_struct(i).path}(:);
        num_links = length(path) - 1;
        link = zeros(1,num_links);
        link_instances = zeros(1,num_links);
        for j = 1:num_links
            link(j) = find(architecture(:,1) == path(j) & architecture(:,2) == path(j+1));
            %link_instances(j) = ceil((max(schedule(find(schedule(:,2) == link(j)),5))/1000)/P);
            link_instances(j) = length(schedule(find(schedule(:,2) == link(j) & schedule(:,1) == i-1),5));
        end
        for j = 1:num_links
            offset = schedule(find(schedule(:,2) == link(j) & schedule(:,1) == i-1),4);
            for k = 1:link_instances(j)
                fprintf(file, 'message\n');
                fprintf(file, sprintf('length = %i\n',message_struct(i).length));
                fprintf(file, sprintf('period = %i\n',P*link_instances(j)));
                fprintf(file, sprintf('deadline = %i\n',P*link_instances(j)));
                fprintf(file, sprintf('priority = %s\n',type));
                fprintf(file, sprintf('linkNbr = %i\n',1));
                fprintf(file, sprintf('link = %i\n',link(j)));
                fprintf(file, 'jitterIn = 0\n');
                fprintf(file, 'initOffset = 0\n');
                fprintf(file, sprintf('offset = %f\n',offset(k)/1000));
                fprintf(file, '\n');
            end
        end
    end
end