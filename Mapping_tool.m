function [] = Mapping_tool(exp_ID)

load(sprintf('Experiment%i/Messages.mat',exp_ID),'message');
load(sprintf('Experiment%i/Routes.mat',exp_ID),'route');
load(sprintf('Experiment%i/Architecture',exp_ID),'architecture');

num_nodes = max(max(architecture));
num_switches = min(min(architecture));
if num_switches > 0
    num_switches = 0;
else
    num_switches = abs(num_switches);
end

message_TT_ID = 1;
message_AVB_ID = 1;
message_BE_ID = 1;
message_NP_ID = 1;

for message_ID = 1:length(message)
    message_tmp = message(message_ID);
    if message_tmp.period ~= 0 && (message_tmp.jitter_reception ~= 0 || (message_tmp.deadline <= 4000 && message_tmp.deadline ~= 0)) %|| (message_tmp.jitter_transmission == 0 && message_tmp.deadline ~= 0))
        message_TT(message_TT_ID) = message_tmp;
        message_TT_ID = message_TT_ID + 1;
    elseif message_tmp.deadline ~= 0 %&& (message_tmp.jitter_reception == 0 || message_tmp.hard_real_time == false)
        message_AVB(message_AVB_ID) = message_tmp;
        message_AVB_ID = message_AVB_ID + 1;
    elseif message_tmp.jitter_reception == 0 && message_tmp.deadline == 0
        message_BE(message_BE_ID) = message_tmp;
        message_BE_ID = message_BE_ID + 1;
    else
        message_NP(message_NP_ID) = message_tmp;
        message_NP_ID = message_NP_ID + 1;
    end
end
if message_TT_ID == 1
    message_TT(1).period = max(extractfield(message,'period'));
    message_TT(1).offset = min(extractfield(message,'offset'));
    message_TT(1).jitter_transmission = min(extractfield(message,'jitter_transmission'));
    message_TT(1).jitter_reception = 1;
    message_TT(1).min_inter_arr_time = min(extractfield(message,'min_inter_arr_time'));
    message_TT(1).length = min(extractfield(message,'length'));
    message_TT(1).deadline = max(extractfield(message,'deadline'));
    message_TT(1).hard_real_time = 1;
    message_TT(1).source = min(extractfield(message,'source'));
    message_TT(1).destination = max(extractfield(message,'destination'));
    message_TT(1).path = min(extractfield(message,'path'));
end
if message_AVB_ID == 1
    message_AVB = 0;
end
if message_BE_ID == 1
    message_BE = 0;
end
if message_NP_ID == 1
    message_NP = 0;
end

%WRITE INPUT FILE

fid = fopen(sprintf('Experiment%i/STHS_input.txt',exp_ID),'wt');

if isstruct(message_TT)
    struct_to_file(message_TT, route, architecture, fid);
end

fclose(fid);

save(sprintf('Experiment%i/TT_Messages',exp_ID), 'message_TT');
save(sprintf('Experiment%i/AVB_Messages',exp_ID), 'message_AVB');
save(sprintf('Experiment%i/BE_Messages',exp_ID), 'message_BE');

end

function [] = struct_to_file(message_struct, route, architecture, file)

for i = 1:length(message_struct)
    fprintf(file, 'message\n');
    fprintf(file, sprintf('length = %i\n',message_struct(i).length));
    fprintf(file, sprintf('period = %i\n',(message_struct(i).period + message_struct(i).min_inter_arr_time)));
    if message_struct(i).deadline > 0
        fprintf(file, sprintf('deadline = %i\n',message_struct(i).deadline));
    else
        fprintf(file, sprintf('deadline = %i\n',message_struct(i).period));
    end
    %fprintf(file, sprintf('priority = %s\n',type));
    path = route{message_struct(i).destination, message_struct(i).source}{message_struct(i).path}(:);
    num_links = length(path) - 1;
    fprintf(file, sprintf('linkNbr = %i\n',num_links));
    for j = 1:num_links
        fprintf(file, sprintf('link = %i\n',find(architecture(:,1) == path(j) & architecture(:,2) == path(j+1))));
    end
    fprintf(file, sprintf('initOffset = %i\n',message_struct(i).offset));
    %fprintf(file, sprintf('jitterIn = %i\n',message_struct(i).jitter_transmission));
    fprintf(file, '\n');
end
end