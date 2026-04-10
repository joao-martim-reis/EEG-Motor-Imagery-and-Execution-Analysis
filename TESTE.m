clear all
clc
close all

%NA ULTIMA SECTION É NECESSÁRIO TER O EEGLAB INSTALADO E A CORRER

path_dados = 'C:\Users\joaom\MATLAB Drive\PROJETO\database';
path_codigo = 'C:\Users\joaom\MATLAB Drive\PROJETO';

cd(path_dados)
num_tarefas = 4; %tarefas 
num_pacientes = 10; %pessoas
num_canais = 64; %canais

for j = 1:num_pacientes
    
    if j < 10 

        for i = 1:num_tarefas
            
            for k = 1:num_canais
            % Formatar o nome do arquivo com base no número atual do loop
            nome_arquivo = sprintf('S00%dR0%d_edfm.mat', j,i);
            load(nome_arquivo);
            
            dados_estrutura.(['subject_', num2str(j)]).(['tarefa_',num2str(i)]).(['canal', num2str(k)])= val(k,:);
            end
        end

    elseif j < 100
 
        for i = 1:num_tarefas
        
            for k = 1:num_canais
            % Formatar o nome do arquivo com base no número atual do loop
            nome_arquivo = sprintf('S0%dR0%d_edfm.mat', j,i);
            load(nome_arquivo);
            
            dados_estrutura.(['subject_', num2str(j)]).(['tarefa_',num2str(i)]).(['canal', num2str(k)])= val(k,:);
            end
        end

    else
        for i = 1:num_tarefas
        
            for k = 1:num_canais
            % Formatar o nome do arquivo com base no número atual do loop
            nome_arquivo = sprintf('S%dR0%d_edfm.mat', j,i);
            load(nome_arquivo);
            
            dados_estrutura.(['subject_', num2str(j)]).(['tarefa_',num2str(i)]).(['canal', num2str(k)])= val(k,:);
            end
        end

    end
       
end

%% Re reference - common average reference (CAR)
%podemos inserir isto ja na filtragem
%TIRAR NA FREQUENCIA A MEDIA -> COMPONENTE DC
%ISTO ESTÁ NO TEMPO

for i =1:num_pacientes
    for j=1:num_tarefas
        for k=1:num_canais
            dados = dados_estrutura.(['subject_', num2str(i)]).(['tarefa_', num2str(j)]).(['canal', num2str(k)]);
            average = mean(dados);
            dados_estrutura.(['subject_', num2str(i)]).(['tarefa_', num2str(j)]).(['canal', num2str(k)]) = dados-average;
        end
    end
end
   
%% PRE FILTROS
cd(path_codigo)

%plot de dados para verificação
figure(1)
for i=1:num_pacientes
    subplot(num_pacientes,1,i),plot(dados_estrutura.(['subject_', num2str(i)]).tarefa_1.canal1), title('Dados EEG'), axis tight
end

%vetor frequencias
Fs = 160;
f = struct();
for i =1:num_pacientes
    for j=1:num_tarefas
        for k=1:num_canais
            nome_vetor = sprintf('frequencia_%d_%d', i, j);
            f.(nome_vetor) = (0:length(dados_estrutura.(['subject_', num2str(i)]).(['tarefa_', num2str(j)]).canal1)-1)*(Fs/length(dados_estrutura.(['subject_', num2str(i)]).(['tarefa_', num2str(j)]).canal1));
        end
    end
end

%verificação das frequencias
figure(2)
subplot(4,1,1),plot(f.frequencia_1_1, abs(fft(dados_estrutura.subject_1.tarefa_1.canal1)))
subplot(4,1,2),plot(f.frequencia_2_1, abs(fft(dados_estrutura.subject_2.tarefa_1.canal1)))
subplot(4,1,3),plot(f.frequencia_3_1, abs(fft(dados_estrutura.subject_3.tarefa_1.canal1)))
subplot(4,1,4),plot(f.frequencia_4_1, abs(fft(dados_estrutura.subject_4.tarefa_1.canal1)))
sgtitle('FFT -> antes dos filtros');

%% FILTROS

[num_notch,den_notch] = tf(filter_notch_60);
[num_high1, den_high1] = tf(IIR_high_1hz);

ordem_notch = filtord(num_notch, den_notch);
[H, w]=freqz(num_notch,den_notch);
maxH=max(abs(H));
num_notch=num_notch*(1/maxH); 
[H, w]=freqz(num_notch,den_notch);%faz para os dois lados, a volta do circulo unitário
Hlog=20.*log10(abs(H));

figure
subplot(311),zplane(num_notch, den_notch), title('Mapa de polos e zeros do filtro notch')
subplot(312),impz(num_notch, den_notch,200), title('Respota impulsional do filtro notch')
subplot(313),plot(w, Hlog),xlabel('Frequência (Hz)'); ylabel('dB');title('Reposta em frequencia filtro Notch');

ordem_1hz = filtord(num_high1, den_high1);
[H1, w1]=freqz(num_high1,den_high1);
maxH=max(abs(H));
num_high1=num_high1*(1/maxH); 
[H1, w1]=freqz(num_high1,den_high1); %faz para os dois lados, a volta do circulo unitário
Hlog1=20.*log10(abs(H1));

figure
subplot(311),zplane(num_high1, den_high1), title('Mapa de polos e zeros do filtro de 1hz')
subplot(312),impz(num_high1, den_high1,200), title('Respota impulsional do filtro de 1hz')
subplot(313),plot(w1, Hlog1),xlabel('Frequência (Hz)'); ylabel('dB');title('Reposta em frequencia filtro de 1hz');
dados_fft = struct();
for i =1:num_pacientes
    for j=1:num_tarefas
        for k=1:num_canais
            dados = dados_estrutura.(['subject_', num2str(i)]).(['tarefa_', num2str(j)]).(['canal', num2str(k)]);
            dados_estrutura.(['subject_', num2str(i)]).(['tarefa_', num2str(j)]).(['canal', num2str(k)])= filter(num_notch, den_notch,dados);
            dados = dados_estrutura.(['subject_', num2str(i)]).(['tarefa_', num2str(j)]).(['canal', num2str(k)]);
            dados_estrutura.(['subject_', num2str(i)]).(['tarefa_', num2str(j)]).(['canal', num2str(k)])= filter(num_high1, den_high1, dados);
            dados_fft.(['subject_', num2str(i)]).(['tarefa_', num2str(j)]).(['canal', num2str(k)]) = abs(fft(dados_estrutura.(['subject_', num2str(i)]).(['tarefa_', num2str(j)]).(['canal', num2str(k)])));
        end
    end
end

figure(4)
subplot(4,1,1),plot(f.frequencia_1_1, dados_fft.subject_1.tarefa_1.canal1)
subplot(4,1,2),plot(f.frequencia_2_1, dados_fft.subject_2.tarefa_1.canal1)
subplot(4,1,3),plot(f.frequencia_3_1, dados_fft.subject_3.tarefa_1.canal1)
subplot(4,1,4),plot(f.frequencia_4_1, dados_fft.subject_4.tarefa_1.canal1)
sgtitle('FFT após os filtros - estrutura');

figure
for i=1:num_pacientes
    subplot(num_pacientes,1,i),plot(dados_estrutura.(['subject_', num2str(i)]).tarefa_1.canal1), title('Dados EEG pós filtros'), axis tight
end

%% DIVISAO E CALCULO DE ENERGIAS E POTENCIA

Potencia = struct();
for j =1:num_pacientes
    for i=1:num_tarefas
        for k=1:num_canais

            re_fre = 0.5; %resolucao em frequencia
            nfft = Fs/re_fre;

            s_teta = filter(theta_filter, dados_estrutura.(['subject_', num2str(j)]).(['tarefa_',num2str(i)]).(['canal', num2str(k)]));
            s_beta = filter(beta_filter, dados_estrutura.(['subject_', num2str(j)]).(['tarefa_',num2str(i)]).(['canal', num2str(k)]));
            s_delta = filter(delta_filter, dados_estrutura.(['subject_', num2str(j)]).(['tarefa_',num2str(i)]).(['canal', num2str(k)]));
            s_alfa = filter(alfa_filter, dados_estrutura.(['subject_', num2str(j)]).(['tarefa_',num2str(i)]).(['canal', num2str(k)]));
            s_gama = filter(gama_filter, dados_estrutura.(['subject_', num2str(j)]).(['tarefa_',num2str(i)]).(['canal', num2str(k)]));

            [p_total, ftotal]=pwelch(dados_estrutura.(['subject_', num2str(j)]).(['tarefa_',num2str(i)]).(['canal', num2str(k)]),[],200,nfft,Fs,'power');
            energia_total = sum(p_total);
            
%           calcular as energias de cada banda
%           Energia.(['subject_', num2str(i)])E_delta(j,k) --> e no
          
            %delta
            [p_delta, fdelta]=pwelch(s_delta, [], 200,nfft,Fs,'power');
            energia_delta = sum(p_delta);
            Energia.(['subject_', num2str(j)]).(['task_',num2str(i)]).E_delta(k) = (energia_delta/energia_total);
            Potencia.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).potencia_delta = p_delta;

            %beta
            [p_beta, fbeta]=pwelch(s_beta, [], 200,nfft,Fs,'power');
            energia_beta = sum(p_beta);
            Energia.(['subject_', num2str(j)]).(['task_',num2str(i)]).E_beta(k) = (energia_beta/energia_total);
            Potencia.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).potencia_beta = p_beta;

            %alfa
            [p_alfa, falfa]=pwelch(s_alfa, [], 200,nfft,Fs,'power');
            energia_alfa = sum(p_alfa);
            Energia.(['subject_', num2str(j)]).(['task_',num2str(i)]).E_alfa(k) = (energia_alfa/energia_total);
            Potencia.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).potencia_alfa = p_alfa;

            %teta
            [p_teta, fteta]=pwelch(s_teta, [], 200,nfft,Fs,'power');
            energia_teta = sum(p_teta);
            Energia.(['subject_', num2str(j)]).(['task_',num2str(i)]).E_teta(k) = (energia_teta/energia_total);
            Potencia.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).potencia_teta = p_teta;

            %gama
            [p_gama, fgama]=pwelch(s_gama, [], 200,nfft,Fs,'power');
            energia_gama = sum(p_gama);
            Energia.(['subject_', num2str(j)]).(['task_',num2str(i)]).E_gama(k) = (energia_gama/energia_total); 
            Potencia.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).potencia_gama = p_gama;

        end
    end
end

%%
%ERD/ERS 
% ERD=((A-R)/R)* 100;

%fazer só para beta
num_seg = length(p_beta); % é igual para todos
ERD = struct();
diferenca = struct();

for j =1:num_pacientes
    for i=1:num_tarefas
        for k=1:num_canais
            for w= 1:num_seg-1
                ERD.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).banda_beta(w) = ((Potencia.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).potencia_beta(w+1) - Potencia.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).potencia_beta(w)) / (Potencia.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).potencia_beta(w))) * 100;
                           
            end
        end
    end
end

%ver ponto a ponto se ha event related desynchronisation, atraves da
%diferença entre pontos adjacentes para ver se a percentagem da potencia
%varia muito de um para outro

for j =1:num_pacientes
    for i=1:num_tarefas
        for k=1:num_canais
            for w= 1:num_seg-2
                % Exemplo de um vetor com 160 valores (substitua isso pelos seus dados)
                vetor1 =ERD.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).banda_beta(w);
                vetor2 =ERD.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).banda_beta(w+1);                                              
                % Verifica se a diferença entre os valores consecutivos é maior que 500
                
                distancia = vetor2 - vetor1;
                if distancia > 300 %valor arbitrario derivado da analise do resultado (nao encontramos nada na literatura)
                    % Atribui 1 a matriz se a diferença for maior que X
                    diferenca.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).banda_beta(w) = 1;
                    diferenca.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).banda_beta(w+1) = 1;
                else 
                    diferenca.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).banda_beta(w) = 0;
                    diferenca.(['subject_', num2str(j)]).(['task_',num2str(i)]).(['canal_',num2str(k)]).banda_beta(w+1) = 0;
                end
                             
            end
        end
    end
end


% tentar fazer a intersecao para todos os canais e encontrar em que
% segmentos que se considera que em todos os canais houve desynchronisation


matriz_intersecao = struct();

for j = 1:num_pacientes
    for i = 1:num_tarefas
       
        canal_base = diferenca.(['subject_', num2str(j)]).(['task_', num2str(i)]).(['canal_', num2str(1)]).banda_beta;
        
        for k = 2:num_canais
            canal_atual = diferenca.(['subject_', num2str(j)]).(['task_', num2str(i)]).(['canal_', num2str(k)]).banda_beta;
            canal_base = canal_base & canal_atual;
        end
       
        matriz_intersecao.(['subject_', num2str(j)]).(['task_', num2str(i)]) = canal_base;
    end
end

%INCONCLUSIVO

%% Apresentação das energias

eletrodos = {'FC5', 'FC3', 'FC1', 'FCz', 'FC2', 'FC4', 'FC6', 'C5', 'C3', 'C1', 'Cz', 'C2', 'C4', 'C6', 'CP5', 'CP3', 'CP1', 'CPz', 'CP2', 'CP4', 'CP6', 'FP1', 'FPZ', 'FP2', 'AF7', 'AF3', 'AFz', 'AF4', 'AF8', 'F7', 'F5', 'F3', 'F1', 'Fz', 'F2', 'F4', 'F6', 'F8','FT7', 'FT8', 'T7', 'T8', 'T9', 'T10', 'TP7', 'TP8', 'P7', 'P5', 'P3', 'P1', 'Pz', 'P2', 'P4', 'P6', 'P8', 'PO7', 'PO3', 'POz', 'PO4', 'PO8', 'O1', 'Oz', 'O2', 'Iz'};
%eletrodos_nome = [FC5 FC3 FC1 FCz FC2 FC4 FC6 C5 C3 C1 Cz C2 C4 C6 CP5 CP3 CP1 CPz CP2 CP4 CP6 FP1 FPZ FP2 AF7 AF3 AFz AF4 AF8 F7 F5 F3 F1 Fz F2 F4 F6 F8 FT8 T7 T8 T9 T10 TP7 TP8 P7 P5 P3 P1 Pz P2 P4 P6 P8 PO7 PO3 POz PO4 PO8 O1 Oz O3 Iz];

%COMPARACAO BANDA BETA E GAMA PARA CADA TAREFA EM CADA PESSOA ->
%Variabilidade Intrapessoal entre bandas de cada tarefa

for j=3:4
     for i=1:num_pacientes
        figure
        subplot(2,1,1), bar(1:numel(eletrodos), Energia.(['subject_', num2str(i)]).(['task_',num2str(j)]).E_beta'), title('banda beta'), axis tight %bar para criar um gráfico de barras com as energias dos canais

        % Configuração dos rótulos no eixo x
        ylim([0, 1]);
        set(gca, 'XTick', 1:numel(eletrodos))
        set(gca, 'XTickLabel', eletrodos)
        xlabel('Canais')
        ylabel('Energias')
    
    %     definimos gca para obter o objeto de eixo atual e, em seguida, usamos a função set para configurar os rótulos no eixo x. 
    %     Usamos numel(canais) para garantir que cada canal esta corretamente
    %     alinhado com a energia correspondente
    
        subplot(2,1,2), bar(1:numel(eletrodos), Energia.(['subject_', num2str(i)]).(['task_',num2str(j)]).E_gama'), title('banda gama')
        ylim([0, 1]);
        set(gca, 'XTick', 1:numel(eletrodos))
        set(gca, 'XTickLabel', eletrodos)
        xlabel('Canais')
        ylabel('Energias')
        sgtitle(['Tarefa ', num2str(j), '-> Comparação das principais bandas de potência para a Pessoa ', num2str(i)]);

     end
end

%Comparacao ENTRE TODAS AS PESSOAS DA ENERGIA DA BANDA BETA OU ALFA PARA
%NAS TAREFAS 3 E 4  
%Variabilidade Intrerpessoal para a mesma tarefa e mesma banda

for j =3:4
    figure
    for i=1:num_pacientes
        subplot(num_pacientes,1,i), bar(1:numel(eletrodos), Energia.(['subject_', num2str(i)]).(['task_',num2str(j)]).E_beta'),
        title(['Pessoa ', num2str(i)], ['Tarefa ', num2str(j)]);
        ylim([0, 1]);
        set(gca, 'XTick', 1:numel(eletrodos))
        set(gca, 'XTickLabel', eletrodos)
        xlabel('Canais')
        ylabel('Energias')
        sgtitle('Banda beta')
     
    end
    figure
    for i=1:num_pacientes
        subplot(num_pacientes,1,i), bar(1:numel(eletrodos), Energia.(['subject_', num2str(i)]).(['task_',num2str(j)]).E_gama'),
        title(['Pessoa ', num2str(i)], ['Tarefa ', num2str(j)]);
        ylim([0, 1]);
        set(gca, 'XTick', 1:numel(eletrodos))
        set(gca, 'XTickLabel', eletrodos)
        xlabel('Canais')
        ylabel('Energias')
        sgtitle('Banda Gama')
     
    end
end

%% racios

Treshold3_1g = [];
Treshold3_1b = [];
Treshold4_1g = [];
Treshold4_1b = [];

%beta e gama
for i=1:num_pacientes
       %beta
       racio3_1b(:,i) =  (Energia.(['subject_', num2str(i)]).task_3.E_beta') ./  (Energia.(['subject_', num2str(i)]).task_1.E_beta');
       racio4_1b(:,i) =  (Energia.(['subject_', num2str(i)]).task_4.E_beta') ./  (Energia.(['subject_', num2str(i)]).task_1.E_beta');
       
       %gama
       racio3_1g(:,i) =  (Energia.(['subject_', num2str(i)]).task_3.E_gama') ./  (Energia.(['subject_', num2str(i)]).task_1.E_gama');
       racio4_1g(:,i) =  (Energia.(['subject_', num2str(i)]).task_4.E_gama') ./  (Energia.(['subject_', num2str(i)]).task_1.E_gama');
       
       media3_1b(:,i)=mean(racio3_1b(:,i)); desvio3_1b(:,i)= std(racio3_1b(:,i));
       media4_1b(:,i)=mean(racio4_1b(:,i)); desvio4_1b(:,i)= std(racio4_1b(:,i));
       media3_1g(:,i)=mean(racio3_1g(:,i)); desvio3_1g(:,i)= std(racio3_1g(:,i));
       media4_1g(:,i)=mean(racio4_1g(:,i)); desvio4_1g(:,i)= std(racio4_1g(:,i));


    disp(['Iteração ' num2str(i)]);
    disp(['Tamanho de racio3_1b: ' num2str(size(racio3_1b))]);
    disp(['Tamanho de racio4_1b: ' num2str(size(racio4_1b))]);
    disp(['Tamanho de racio3_1g: ' num2str(size(racio3_1g))]);
    disp(['Tamanho de racio4_1g: ' num2str(size(racio4_1g))]);
    %verificar se esta tudo bem em cada iteração
end

%variavel booleana
for j = 1:num_pacientes
     for k = 1:num_canais

               if racio3_1g(k,j) > (media3_1g(:,j) + desvio3_1g(:,j))
                   Treshold3_1g(k,j) = 1;
               else
                   Treshold3_1g(k,j) = 0;
               end

               if racio3_1b(k,j) > media3_1b(:,j) + desvio3_1b(:,j)
                   Treshold3_1b(k,j) = 1;
               else
                   Treshold3_1b(k,j) = 0;               
               end

               if racio4_1g(k,j) > media4_1g(:,j) + desvio4_1g(:,j)
                   Treshold4_1g(k,j) = 1;
               else
                   Treshold4_1g(k,j) = 0;                    
               end

               if racio4_1b(k,j) > media4_1b(:,j) + desvio4_1b(:,j)
                   Treshold4_1b(k,j) = 1;
               else
                   Treshold4_1b(k,j) = 0;
               end
     end        
end


%Apresentaca dos racios

Bandas_energia = {'Beta-3/1', 'Beta-4/1', 'Gama-3/1', 'Gama-4/1'};
racios = {racio3_1b, racio4_1b, racio3_1g, racio4_1g};
media = {media3_1b, media4_1b,media3_1g,media4_1g};
desvio = {desvio3_1b, desvio4_1b, desvio3_1g, desvio4_1g};

for j = 1:num_pacientes
    for banda_indice = 1:numel(Bandas_energia)
        figure
        for k = 1:num_canais
            bar(1:numel(eletrodos), racios{banda_indice}(:,j)), hold on
            media_canal = media{banda_indice}(:, j);
            desvio_canal = desvio{banda_indice}(:,j);

            %line([0.5, numel(eletrodos) + 0.5], [media_canal, media_canal], 'Color', 'black', 'LineWidth', 1);
            h = line([0.5, numel(eletrodos) + 0.5], [media_canal + desvio_canal, media_canal+desvio_canal], 'Color', 'red', 'LineStyle', '--', 'LineWidth', 2);
            legend(h, 'Média + Desvio Padrão');

            title(['Pessoa ', num2str(j)], ['Banda ' Bandas_energia{banda_indice}]);
            axis tight
            set(gca, 'XTick', 1:numel(eletrodos))
            set(gca, 'XTickLabel', eletrodos)
            xlabel('Canais')
            ylabel('Racio')

        end
    end
end

%% ONDE EXISTIU AUMENTO DE ENERGIA 

%VERIFICAR PARA CADA BANDA QUAL OS CANAIS ONDE EXISTIU ESSE AUMENTO DE
%ENERGIA CONSIDERADO SUFICIENTE

bandas = {'Beta', 'Gama', 'Beta', 'Gama'};
tresholds = {Treshold3_1b, Treshold3_1g, Treshold4_1b, Treshold4_1g};
tarefas = {'3', '3', '4', '4'};
canais_numero = struct();
for i = 1:length(tresholds)
    matriz = tresholds{i};
    
    for j = 1:size(matriz, 2)
        indices_eletrodos = find(matriz(:, j) == 1);
        nomes_eletrodos = eletrodos(indices_eletrodos);
        
        canais_numero.(['treshold_', num2str(i)]).(['subject_', num2str(j)]) = indices_eletrodos;

        disp(['Os eletrodos onde existe um aumento substancial da energia para a banda ' bandas{i} ' na tarefa ' tarefas{i} ' para a pessoa ' num2str(j) ' são:']);
        disp(nomes_eletrodos');
        disp('--------------------------');
    end
end

disp('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');


%AUMENTO PARA AMBAS AS BANDAS NA MESMA TAREFA 
%TENTAR VER SEMELHANÇAS ENTRE BANDAS
%VERIFICAR EM QUE CANAIS É QUE EXISTIU UM AUMENTO DE ENERGIA
%INDEPENDENTEMENTE DA BANDA, FAZENDO A INTERSEÇÃO ENTRE BANDAS PARA CADA
%TAREFA E CADA PESSOA   


tresholds = {Treshold3_1b, Treshold3_1g, Treshold4_1b, Treshold4_1g};
tarefas = {'3','4'};

canais_comum3 = zeros(num_canais, num_pacientes);
canais_comum4 = zeros(num_canais, num_pacientes);

canais_numero_intersecao3= struct();
canais_numero_intersecao4= struct();

for i = 1:length(tresholds)/2 % Divide por 2 porque temos dados para tarefa 3 e 4
    matriz_1 = tresholds{i*2 - 1}; 
    matriz_2 = tresholds{i*2};     
    
    for j = 1:size(matriz_1, 2)
        canais_1 = find(matriz_1(:, j) == 1);
        canais_2 = find(matriz_2(:, j) == 1);

        
        
        % Encontrar a interseção dos canais com valor 1
        canais_em_comum = intersect(canais_1, canais_2);
        
        
        % Armazenar os índices dos canais em comum
        if i == 1
            canais_comum3(canais_em_comum,j) = 1;
            canais_numero_intersecao3.(['subject_', num2str(j)]) = canais_em_comum;
        elseif i == 2
            canais_comum4(canais_em_comum,j) = 1;
            canais_numero_intersecao4.(['subject_', num2str(j)]) = canais_em_comum;
        end

        

        eletrodos_comum = eletrodos(canais_em_comum);  
        disp(['Os eletrodos onde existe um aumento substancial da energia para ambas as bandas na tarefa ' tarefas{i} ' para a pessoa ' num2str(j) ' são:']);
        disp('Canais em comum :');
        disp(eletrodos_comum');
        disp('--------------------------');
    end
end


%% TESTE ESTATISTICO

h = zeros(num_canais, num_pacientes);
valoresP = zeros(num_canais, num_pacientes);

%verificar se existe diferença na distribuicao entre a tarefa 3 e 4 e o
%controlo

for j = 1:num_pacientes
        [h_beta3(i),valoresP_beta3(i)] = ttest(Energia.(['subject_', num2str(j)]).task_3.E_beta,Energia.(['subject_', num2str(j)]).task_1.E_beta);
        [h_gama3(i),valoresP_gama3(i)] = ttest(Energia.(['subject_', num2str(j)]).task_3.E_gama,Energia.(['subject_', num2str(j)]).task_1.E_gama);
        [h_beta4(i),valoresP_beta4(i)] = ttest(Energia.(['subject_', num2str(j)]).task_4.E_beta,Energia.(['subject_', num2str(j)]).task_1.E_beta);
        [h_gama4(i),valoresP_gama4(i)] = ttest(Energia.(['subject_', num2str(j)]).task_4.E_gama,Energia.(['subject_', num2str(j)]).task_1.E_gama);
end


% Um teste não paramétrico é um teste estatístico que não faz suposições
% sobre a distribuição subjacente dos dados 

for i = 1:num_pacientes
        [ valoresP_3(i),h3(i)] = ranksum(canais_numero.treshold_1.(['subject_', num2str(i)]), canais_numero.treshold_2.(['subject_', num2str(i)]));
        [valoresP_4(i),h4(i)] = ranksum(canais_numero.treshold_3.(['subject_', num2str(i)]), canais_numero.treshold_4.(['subject_', num2str(i)]));

        %entre a tarefa 3 e 4
        [valoresP__intersect(i),h_intersect(i)] = ranksum(canais_numero_intersecao3.(['subject_', num2str(i)]),canais_numero_intersecao4.(['subject_', num2str(i)]));
end
%O parâmetro h retorna uma matriz de valores lógicos, onde 1 indica que há uma diferença significativa 
% entre as duas amostras e 0 indica que não há diferença significativa
%O parâmetro valoresP dá uma matriz de p-values, que é a probabilidade de observar uma diferença 
% tão extrema entre as duas amostras se a hipótese nula for verdadeira. 
% Um valor p menor que um nível de significância definido (0,05) sugere uma diferença estatisticamente significativa



indices_significativos_intersect = find(h_intersect == 1);
indices_significativos_3 = find(h3 == 1);
indices_significativos_4 = find(h4 == 1);

if ~isempty(indices_significativos_intersect)
    disp('Para as seguintes pessoas, houve uma diferença significativa entre tarefas:');
    disp(indices_significativos_3);
else
    disp('Não houve diferença significativa significativa entre tarefas.');
end

if ~isempty(indices_significativos_3)
    disp('Para as seguintes pessoas, houve uma diferença significativa nos canais mais ativados entre bandas na tarefa 3:');
    disp(indices_significativos_3);
else
    disp('Não houve diferença significativa significativo para nenhuma pessoa na tarefa 3.');
end

if ~isempty(indices_significativos_4)
    disp('Para as seguintes pessoas, houve uma diferença significativa nos canais mais ativados entre bandas na tarefa 4:');
    disp(indices_significativos_4);
else
    disp('Não houve diferença significativa significativo para nenhuma pessoa na tarefa 4.');
end


%% Topographical plotting
%necessário ter o ficheiro BioSemi64.loc e ter o EEGLAB operacional e a
%correr

eloc=readlocs('BioSemi64.loc');
eletrodos = {'FC5', 'FC3', 'FC1', 'FCz', 'FC2', 'FC4', 'FC6', 'C5', 'C3', 'C1', 'Cz', 'C2', 'C4', 'C6', 'CP5', 'CP3', 'CP1', 'CPz', 'CP2', 'CP4', 'CP6', 'FP1', 'FPZ', 'FP2', 'AF7', 'AF3', 'AFz', 'AF4', 'AF8', 'F7', 'F5', 'F3', 'F1', 'Fz', 'F2', 'F4', 'F6', 'F8','FT7', 'FT8', 'T7', 'T8', 'T9', 'T10', 'TP7', 'TP8', 'P7', 'P5', 'P3', 'P1', 'Pz', 'P2', 'P4', 'P6', 'P8', 'PO7', 'PO3', 'POz', 'PO4', 'PO8', 'O1', 'Oz', 'O2', 'Iz'}';
eloc_alterada = struct('theta',{},'radius',{},'labels', {}, 'sph_theta', {}, 'sph_phi', {}, 'sph_radius', {},'sph_theta_besa',{},'sph_phi_besa',{},'X',{},'Y',{},'Z',{});
%fazer modificação de alguns pontos para ficar de acordo com a localizacao
%de eletrodos que apresentamos
eloc(24).labels = 'T9';
eloc(24).theta = -90;
eloc(24).radius = 0.525;
eloc(61).labels = 'T10';
eloc(61).theta = 90;
eloc(61).radius =0.525;

for i = 1:length(eletrodos)
    string_atual = eletrodos{i};
    for j = 1:length(eloc)
        if strcmpi(eloc(j).labels, string_atual)
            eloc_alterada(i) = eloc(j);
            break
        end
    end
end

for j = 8
    for banda_indice = 1:numel(Bandas_energia)
        figure
        topoplot(racios{banda_indice}(:,j),eloc_alterada)
        title(['Pessoa ', num2str(j)], ['racio' Bandas_energia{banda_indice}]);
    end
end

%adaptado de mike Cohen

figure
topoplot([],eloc_alterada,'electrodes','ptslabels');

% get cartesian coordinates
[elocsX,elocsY] = pol2cart(pi/180*[eloc.theta],[eloc.radius]);

% plot electrode locations
figure, clf
scatter(elocsY,elocsX,100,'ro','filled');
set(gca,'xlim',[-.6 .6],'ylim',[-.6 .6])
axis square
title('Electrode locations')

% define XY points for interpolation
interp_detail = 100;
interpX = linspace(min(elocsX)-.2,max(elocsX)+.25,interp_detail);
interpY = linspace(min(elocsY),max(elocsY),interp_detail);

% meshgrid is a function that creates 2D grid locations based on 1D inputs
[gridX,gridY] = meshgrid(interpX,interpY);
hold on
plot3(gridY(:),gridX(:),-ones(1,interp_detail^2),'k.')

