clc; close all; clearvars;
addpath('..\Test_signals\', '..\DG_waveform_generator\', '..\MSO_oscilloscope\');

% Create data to load. Currently there are two signals available in
% Test_signals class:
%       normalized_two_sins
%       normalized_ofdm
% data_to_load = Test_signals.normalized_ofdm;
data_to_load = Test_signals.normalized_two_sins;


dg_conn_ID = 'USB0::0x1AB1::0x0640::DG5S244900056::0::INSTR';

% load data
DG.load_data(dg_conn_ID, data_to_load);


%% Oscilloscope and MSO file

osci_conn_ID = 'USB0::0x1AB1::0x0515::MS5A244909354::0::INSTR';

% read data in normal mode. The mode allows max of 1000 points to load
[d, p] = MSO.read_data_normal(osci_conn_ID);

% read data in raw mode. The mode allows max of internal instrument memory depth points to load
[d_raw, p_raw] = MSO.read_data_raw(osci_conn_ID, 1e6);


[d_max, p_max] = MSO.read_data_max(osci_conn_ID);


figure; 
    plot(d); 
    grid on;
    title('data acquired in normal mode');

figure; 
    plot(d_raw); 
    grid on;
    title('data acquired in raw mode');


figure; 
    plot(d_max); 
    grid on;
    title('data acquired in max mode');

figure; 
    plot(abs(fft(d))); 
    grid on;
    title('spectrum of normal data');

figure; 
    plot(abs(fft(d_raw))); 
    grid on;
    title('spectrum of raw data');


figure; 
    plot(abs(fft(d_max))); 
    grid on;
    title('spectrum of max data');