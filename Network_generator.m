function [] = Network_generator(exp_ID,i_architecture,i_full_duplex,i_num_messages,i_bandwidth,i_msg_length,i_max_link_load,i_periodic,i_jitter_transmission,i_jitter_reception,i_deadline,i_hard_real_time,i_max_period,i_max_offset,i_jitter_transmission_range,i_max_inter_arr_time,i_jitter_reception_range,i_deadline_range)

%i_bandwidth.................[bytes/us]
%i_msg_length...................[bytes]
%i_max_period......................[us]
%i_max_offset......................[us]
%i_jitter_transmission_range.......[us]
%i_max_inter_arr_time..............[us]
%i_jitter_reception_range..........[us]
%i_deadline_range..................[us]
%All other values are int or percentage

rng('shuffle');

%i_max_period = round(i_max_period/3)*3;
i_max_inter_arr_time = round(i_max_inter_arr_time/3)*3;

if length(i_msg_length) < 2
    i_msg_length = [0 i_msg_length];
end

num_nodes = max(max(i_architecture));
num_switches = min(min(i_architecture));
if num_switches > 0
    num_switches = 0;
else
    num_switches = abs(num_switches);
end

if i_full_duplex == true
    for i = 1:length(i_architecture(:,1))
        architecture(i*2-1,:) = i_architecture(i,:);
        architecture(i*2,:) = flip(i_architecture(i,:));
    end
else
    architecture = i_architecture;
end

for node_s = 1:num_nodes
    for node_d = 1:num_nodes
        path = 1;
        prev_path = path;
        link_num = 1;
        link_node = node_s;
        all_paths_finished = false;
        route{node_d,node_s}{path}(link_num) = link_node;
        if node_s ~= node_d
            while all_paths_finished ~= true
                all_paths_finished = true;
                for path_num = 1:path
                    if link_node(path_num) == node_d || link_node(path_num) == 0
                        path = path+1;
                        link_node(path) = 0;
                        route{node_d,node_s}{path}(:) = route{node_d,node_s}{path_num}(:);
                        route{node_d,node_s}{path}(link_num+1) = link_node(path);
                    else
                        [link_node_row,link_node_col] = find(architecture(:,1) == link_node(path_num));
                        for new_paths = 1:length(link_node_row)
                            if isempty(find(route{node_d,node_s}{path_num}(:) == architecture(link_node_row(new_paths),2),1))
                                path = path + 1;
                                link_node(path) = architecture(link_node_row(new_paths),2);
                                route{node_d,node_s}{path}(:) = route{node_d,node_s}{path_num}(:);
                                route{node_d,node_s}{path}(link_num+1) = link_node(path);
                            end
                        end
                        all_paths_finished = false;
                    end
                end
                link_node(1:prev_path)=[];
                link_num = link_num + 1;
                for i = 1:prev_path
                    route{node_d,node_s}{i} = {};
                end
                route{node_d,node_s} = route{node_d,node_s}(~cellfun('isempty',route{node_d,node_s}));
                path = path - prev_path;
                prev_path = path;
            end
            for i = 1:path
                route{node_d,node_s}{i}(route{node_d,node_s}{i} == 0) = [];
            end
        end
    end
end

for i = 1:length(architecture(:,1))
    link_load(i,:) = [architecture(i,:) 0];
end

no_space = false;
i = 1;
while i <= i_num_messages && no_space == false
    if randi(100) <= i_periodic % Probability of being periodic
        message(i).period = i_max_period(randi(length(i_max_period)));
        message(i).offset = randi(i_max_offset);
        if randi(100) <= i_deadline % Probability of having deadline constrains
            message(i).deadline = i_deadline_range(randi([2 3])) * message(i).period;
        else
            message(i).deadline = 0;
        end
        if randi(100) <= i_jitter_transmission % Probability of having jitter in the transmission being periodic
            message(i).jitter_transmission = message(i).period * (i_jitter_transmission_range/100);
        else
            message(i).jitter_transmission = 0;
        end
        if (message(i).deadline ~= 0 && randi(100) <= i_jitter_reception)% Probability of having jitter constrains in the reception
            message(i).jitter_reception = message(i).period * (i_jitter_reception_range/100);
            message(i).deadline = i_deadline_range(1) * message(i).period;
        else
            message(i).jitter_reception = 0;
        end
        message(i).min_inter_arr_time = 0;
    else
        message(i).period = 0;
        message(i).offset = 0;
        if randi(100) <= i_deadline % Probability of having deadline constrains
            message(i).deadline = i_deadline_range(randi(length(i_deadline_range))) * message(i).period;
        else
            message(i).deadline = 0;
        end
        message(i).jitter_transmission = 0;
        message(i).jitter_reception = 0;
        message(i).min_inter_arr_time = randi(3)*(i_max_inter_arr_time/3);
    end
    message(i).length = randi(i_msg_length); % Vector with the range of the length in bytes
    if randi(100) <= i_hard_real_time % Probability of having hard real time constrains
        message(i).hard_real_time = true;
    else
        message(i).hard_real_time = false;
    end
    message(i).source = randi(num_nodes);
    message(i).destination = randi(num_nodes);
    while message(i).source == message(i).destination
        message(i).destination = randi(num_nodes);
    end
    path_selected = randi(length(cellfun(@(v)v(1),route{message(i).destination,message(i).source})));
    for j = 1:num_nodes
        sources_tried(j) = 0;
        destinations_tried(j) = 0;
    end
    paths_tried = [];
    for j = 1:length(cellfun(@(v)v(1),route{message(i).destination,message(i).source}))
        paths_tried(j) = false;
    end
    if message(i).jitter_reception ~= 0 || (message(i).deadline <= 4000 && message(i).deadline ~= 0)
        path_selected = 1;
        paths_tried = [];
    end
    sources_tried(message(i).source) = true;
    destinations_tried(message(i).destination) = true;
    destinations_tried(message(i).source) = true;
    paths_tried(path_selected) = true;
    schedulable = false;
    while schedulable == false && no_space == false
        schedulable = true;
        for j = 1:length(route{message(i).destination,message(i).source}{path_selected}(:))-1
            [pos_j,pos_i]=ind2sub(fliplr(size(architecture(:,1:2))), strfind(reshape(architecture(:,1:2).',1,[]),route{message(i).destination,message(i).source}{path_selected}(j:j+1)).' );
            if link_load(pos_i,3) + message(i).length/(message(i).period + message(i).min_inter_arr_time) > i_bandwidth*(i_max_link_load/100)
                schedulable = false;
            end
        end
        if schedulable == false
            if message(i).length > min(i_msg_length)
                message(i).length = randi([min(i_msg_length) message(i).length]);
            %elseif message(i).period ~= i_max_period(end) && message(i).min_inter_arr_time ~= i_max_inter_arr_time
            %    if message(i).period == 0
            %        if message(i).min_inter_arr_time < i_max_inter_arr_time
            %            message(i).min_inter_arr_time = randi([message(i).min_inter_arr_time*(3/i_max_inter_arr_time) 3])*(i_max_inter_arr_time/3);
            %        end
            %    else
            %        if message(i).period < i_max_period(end)
            %            message(i).period = i_max_period(find(i_max_period == message(i).period) + 1);
            %            %message(i).period = randi([message(i).period*(3/i_max_period) 3])*(i_max_period/3);
            %        end
            %    end
            elseif ~isempty(find(~paths_tried,1))
                while paths_tried(path_selected) == true
                    path_selected = randi(length(cellfun(@(v)v(1),route{message(i).destination,message(i).source})));
                end
                paths_tried(path_selected) = true;
            elseif ~isempty(find(~destinations_tried,1))
                while destinations_tried(message(i).destination) == true
                    message(i).destination = randi(num_nodes);
                end
                destinations_tried(message(i).destination) = true;
                path_selected = randi(length(cellfun(@(v)v(1),route{message(i).destination,message(i).source})));
                paths_tried = [];
                for j = 1:length(cellfun(@(v)v(1),route{message(i).destination,message(i).source}))
                    paths_tried(j) = false;
                end
                if message(i).jitter_reception ~= 0 || (message(i).deadline <= 4000 && message(i).deadline ~= 0)
                    path_selected = 1;
                    paths_tried = [];
                end
                paths_tried(path_selected) = true;
            elseif ~isempty(find(~sources_tried,1))
                while sources_tried(message(i).source) == true
                    message(i).source = randi(num_nodes);
                end
                while message(i).source == message(i).destination
                    message(i).destination = randi(num_nodes);
                end
                path_selected = randi(length(cellfun(@(v)v(1),route{message(i).destination,message(i).source})));
                paths_tried = [];
                for j = 1:num_nodes
                    destinations_tried(j) = 0;
                end
                for j = 1:length(cellfun(@(v)v(1),route{message(i).destination,message(i).source}))
                    paths_tried(j) = false;
                end
                sources_tried(message(i).source) = true;
                destinations_tried(message(i).destination) = true;
                destinations_tried(message(i).source) = true;
                if message(i).jitter_reception ~= 0 || (message(i).deadline <= 4000 && message(i).deadline ~= 0)
                    path_selected = 1;
                    paths_tried = [];
                end
                paths_tried(path_selected) = true;
            else
                no_space = true;
            end
        end
    end
    if no_space == false
        for j = 1:length(route{message(i).destination,message(i).source}{path_selected}(:))-1
            [pos_j,pos_i]=ind2sub(fliplr(size(architecture(:,1:2))), strfind(reshape(architecture(:,1:2).',1,[]),route{message(i).destination,message(i).source}{path_selected}(j:j+1)).' );
            link_load(pos_i,3) = link_load(pos_i,3) + message(i).length/(message(i).period + message(i).min_inter_arr_time);
        end
        message(i).path = path_selected;
    else
        message(i) = [];
    end
    i = i + 1;
end

if min(size(message)) == 0
    message(1).period = i_max_period(end);
    message(1).offset = 0;
    message(1).jitter_transmission = 0;
    message(1).jitter_reception = 1;
    message(1).min_inter_arr_time = 0;
    message(1).length = min(i_msg_length);
    message(1).deadline = max(i_deadline_range)*message(1).period;
    message(1).hard_real_time = 1;
    message(1).source = 1;
    message(1).destination = num_nodes;
    message(1).path = 1;
end

%writetable(struct2table(message), sprintf('Messages%i.csv',exp_ID));
mkdir(sprintf('Experiment%i',exp_ID));
save(sprintf('Experiment%i/Messages',exp_ID), 'message');
save(sprintf('Experiment%i/Routes',exp_ID), 'route');
save(sprintf('Experiment%i/Architecture',exp_ID), 'architecture');

end

