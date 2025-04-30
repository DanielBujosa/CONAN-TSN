function [] = Graph_results()

numExp = zeros(1,7);
NumNewk = zeros(1,7);

for i = 10:5:40
    
    file = '';
    
    for j = 1:1:100
        
        Newk = 1;
            
        numExp((i)/5-1) = numExp((i)/5-1) + 1;
        
        if exist(strcat(file , sprintf('Experiment%i%i/Schedule.txt',i,j)), 'file') == 2
            
            NewRT = readmatrix(strcat(file , sprintf('Experiment%i%i/final_new_new_results.txt',i,j)));
            for k = 1:1:length(NewRT)
                if NewRT(k,4) > NewRT(k,3)
                    Newk = 0;
                end
            end
            NumNewk((i)/5-1) = NumNewk((i)/5-1) + Newk;
            
        end
        
    end
    
end

figure
plot(10:5:40,(NumNewk(1:7)./numExp(1:7)).*100,'--ks')
hold on
for i = 1:1:7
    [phat,pci] = binofit(NumNewk(i),numExp(i));
    a = errorbar(5+i*5,(NumNewk(i)./numExp(i))*100,((NumNewk(i)./numExp(i))-pci(1))*100,(pci(2)-(NumNewk(i)./numExp(i)))*100);
    a.Color = 'black';
end
title('Schedulability of the use case for different link utilizations');
ylabel('Schedulability[%]')
xlim([5 45])
xlabel('Utilization [%]')
grid on

set(gcf, 'Color', 'none');  % Fondo transparente de la figura
set(gca, 'Color', 'none');  % Fondo transparente del área de los ejes
set(gcf, 'InvertHardcopy', 'off'); % No invertir colores al guardar

set(gcf,'Units','inches');
screenposition = get(gcf,'Position');
set(gcf,...
    'PaperPosition',[0 0 screenposition(3:4)],...
    'PaperSize',[screenposition(3:4)]);

% Opciones para forzar tipografía correcta
set(gcf, 'InvertHardcopy', 'off');  % Evita cambio de colores
set(gca, 'FontName', 'Times New Roman'); % O usa 'Helvetica' si prefieres

% Guardar como PDF vectorial
print(gcf, '-dpdf', '-painters', 'Schedulability');
%print -dpdf -painters Schedulability

end