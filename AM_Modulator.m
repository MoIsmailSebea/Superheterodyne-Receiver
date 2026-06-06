clc;
clear;
close all;

%% ===================== Read Audio Files ==========================
[msg1, Fs] = audioread('audio1.wav');
[msg2, Fs2] = audioread('audio2.wav');
[msg3, Fs3] = audioread('audio3.wav');
[msg4, Fs4] = audioread('audio4.wav');
[msg5, Fs5] = audioread('audio5.wav');

% Convert stereo to mono
msg1 = sum(msg1,2);
msg2 = sum(msg2,2);
msg3 = sum(msg3,2);
msg4 = sum(msg4,2);
msg5 = sum(msg5,2);


%% ===================== Equal Length ==============================
N = max([length(msg1), length(msg2), length(msg3), length(msg4), length(msg5)]);

msg1(length(msg1)+1:N) = 0;
msg2(length(msg2)+1:N) = 0;
msg3(length(msg3)+1:N) = 0;
msg4(length(msg4)+1:N) = 0;
msg5(length(msg5)+1:N) = 0;

%% ===================== Increase Sampling Rate ====================
L = 10;                     % interpolation factor
msg1 = interp(msg1,L);
msg2 = interp(msg2,L);
msg3 = interp(msg3,L);
msg4 = interp(msg4,L);
msg5 = interp(msg5,L);


Fs = Fs*L;
Ts = 1/Fs;

N = length(msg1);

t = (0:N-1)*Ts;

%% ===================== Carrier Frequencies =======================
Fc1 = 100e3;     % 100 kHz
Fc2 = 150e3;     % 150 kHz
Fc3 = 200e3;     % 200 kHz
Fc4 = 250e3;     % 250 kHz
Fc5 = 300e3;     % 300 kHz

%% ===================== DSB-SC Modulation =========================
mod1 = msg1 .* cos(2*pi*Fc1*t)';
mod2 = msg2 .* cos(2*pi*Fc2*t)';
mod3 = msg3 .* cos(2*pi*Fc3*t)';
mod4 = msg4 .* cos(2*pi*Fc4*t)';
mod5 = msg5 .* cos(2*pi*Fc5*t)';

%% ===================== FDM Signal ================================
FDM_signal = mod1+mod2+mod3+mod4+mod5;

%% ===================== RF Stage =================================
BW = 20e3;       % choose according to message bandwidth

RF_filter = designfilt('bandpassiir', ...
    'FilterOrder',8, ...
    'HalfPowerFrequency1',Fc1-BW,...
    'HalfPowerFrequency2',Fc1+BW,...
    'SampleRate',Fs);

RF_output = filter(RF_filter,FDM_signal);

%% ===================== Mixer ====================================
FIF = 25e3;

LO = Fc1 + FIF;          % local oscillator frequency

mixed_signal = RF_output .* cos(2*pi*LO*t)';

%% ===================== IF Stage =================================
IF_filter = designfilt('bandpassiir', ...
    'FilterOrder',8,...
    'HalfPowerFrequency1',FIF-BW,...
    'HalfPowerFrequency2',FIF+BW,...
    'SampleRate',Fs);

IF_output = filter(IF_filter,mixed_signal);

%% ===================== Baseband Detection =======================
baseband_mixed = IF_output .* cos(2*pi*FIF*t)';

LPF = designfilt('lowpassiir', ...
    'FilterOrder',8,...
    'HalfPowerFrequency',BW,...
    'SampleRate',Fs);

recovered_signal = filter(LPF,baseband_mixed);

%% ===================== Normalize ================================
recovered_signal = recovered_signal/max(abs(recovered_signal));

%% ===================== Play Recovered Signal ====================
sound(recovered_signal,Fs);

%% ===================== Spectrum of RF, IF and Baseband ==========
Nfft = length(FDM_signal);

f = (-Nfft/2:Nfft/2-1)*(Fs/Nfft);

RF_spec = fftshift(abs(fft(RF_output)));
IF_spec = fftshift(abs(fft(IF_output)));
BB_spec = fftshift(abs(fft(recovered_signal)));

figure;

subplot(3,1,1)
plot(f/1000,RF_spec)
xlabel('Frequency (kHz)')
ylabel('Magnitude')
title('RF Output Spectrum')
grid on

subplot(3,1,2)
plot(f/1000,IF_spec)
xlabel('Frequency (kHz)')
ylabel('Magnitude')
title('IF Output Spectrum')
grid on

subplot(3,1,3)
plot(f/1000,BB_spec)
xlabel('Frequency (kHz)')
ylabel('Magnitude')
title('Baseband Output Spectrum')
grid on
