%% Load data to generator 

clc; close all; clearvars;
addpath('..\Test_signals\', '..\DG_waveform_generator\', '..\MSO_oscilloscope\', '..\TF_waveform_generator');

% signal = Test_signals.normalized_sin();
signal = Test_signals.normalized_ofdm();

figure;
    plot(signal.freqline/1e6, abs(fft(signal.data)));
    grid on;
    title('Спектр тестового OFDM сигнала');
    xlabel('Частота, МГц');


figure;
    plot(signal.data);
    grid on;
    title('Тестовый OFDM сигнал во временной области');
    xlabel('Отсчёты');
    ylabel('Амплитуда');


dg_conn_ID = 'USB0::0x1AB1::0x0640::DG5S245900056::0::INSTR';
data_to_load = signal.data;


% load data
amp = .7;
DG.load_data(dg_conn_ID, data_to_load, signal.Fs, amp);
%% Oscilloscope and MSO file
clc; close all; 
% clearvars;
osci_conn_ID = 'USB0::0x1AB1::0x0515::MS5A244909354::0::INSTR';

channel_num = 1;
% read data in raw mode. The mode allows max of internal instrument memory depth points to load
oscilloscope_data = MSO.read_data(osci_conn_ID, channel_num, 125e6);

figure;
    plot(oscilloscope_data);
    grid on;
    title('Полученные данные с осциллографа');
    xlabel('Отсчёты');
    ylabel('Амплитуда, В');


processed_signal = Test_signals.process_ofdm(oscilloscope_data, signal.data, signal.modulation_order);
scatterplot(processed_signal.modulated_data);
    title('Созвездие принятого OFDM сигнала', 'Color','Black');
    grid on;

[er, errate] = biterr(signal.bits, processed_signal.bits);
er 
errate


%% READ RAW

clc; close all;
Fs = 4*125e6;
Ts = 1/Fs;
Npoints = 100e3;
TBscale = Npoints*Ts;

addpath('..\Test_signals\', '..\DG_waveform_generator\', '..\MSO_oscilloscope\', '..\TF_waveform_generator');


osci_conn_ID = 'USB0::0x1AB1::0x0515::MS5A244909354::0::INSTR';
channel_num = 1;

tic

[rr, t] = MSO.read_raw_ascii(osci_conn_ID, channel_num, 100e3);

% return;
splitted = split(rr, ',');


% test_string = 'fd.x11.6115.13123, 192.168.2.0, 192.315.11, 1.13.b.4., 192.168.4.0.';
% reg_expression = '(\d{1,3}\.){3}\d{1,3}';
% m2 = regexp(test_string, reg_expression, 'match')
% 
% 
% test_string2 = '<tag>Tarzan</tag> likes <tag>Jane</tag>';
% reg_expression2 = '<tag>.*</tag>';
% m3 = regexp(test_string2, reg_expression2, 'match')
% 
% 
% test_string3 = 'He said bluntly "that is what she said!" and winked clarly';
% reg_expression3 = '".*"';
% m4 = regexp(test_string3, reg_expression3, 'match')
% 
% 
% 
% test_string4 = 'He said bluntly "that is Awhat she said!" and winked clarly';
% reg_expression4 = '".*"';
% m5 = regexp(test_string4, reg_expression4, 'match')


t1 = toc;
disp(['MSO.read_raw elapsed time ', num2str(t1), ' seconds']);


reg_expre = '[-+][\d\.]+E[+-]\d+';
m = regexp(rr, reg_expre, 'match');
arr = str2double(m);

t2 = toc;
disp(['regex elapsed time ', num2str(t2 - t1), ' seconds']);

figure;
    plot(arr);
    grid on;
    title('Принятый с осциллографа сигнал');
    xlabel('Отсчёты');
    ylabel('Аплитуда, В');


t3 = toc;
disp(['plot elapsed time ', num2str(t3 - t2), ' seconds']);


%% READ BYTES


clc; close all; clearvars;
Fs = 4*125e6;
Ts = 1/Fs;
Npoints = 100e3;
TBscale = Npoints*Ts;

addpath('..\Test_signals\', '..\DG_waveform_generator\', '..\MSO_oscilloscope\', '..\TF_waveform_generator');


osci_conn_ID = 'USB0::0x1AB1::0x0515::MS5A244909354::0::INSTR';
channel_num = 1;



[rr, t, data] = MSO.read_raw_bytes_fs(osci_conn_ID, channel_num, 2e6, 100e6);

figure;
    plot(rr);