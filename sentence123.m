clear; clc; close all;

[x, Fs] = audioread('PG02.wav');

% plot audio so we can see the indiv syllables
t = (0:length(x)-1) / Fs;
figure;
plot(t, x);
xlabel('Time (s)');
ylabel('Amplitude');
title('Full audio signal');

ma_syllable = x(t >= 0.46 & t <= 0.72);
gan_syllable = x(t >= 1.59 & t <= 1.95);
dang_syllable = x(t >= 2.71 & t <= 3.15);
ha_syllable = x(t >= 3.85 & t <= 4.1);
pon_syllable = x(t >= 4.88 & t <= 5.2);
ga_syllable = x(t >= 6.90 & t <= 7.1);
bi_syllable = x(t >= 8.00 & t <= 8.33);

% Speed up "Magandang" for greeting (10% faster)
ma_fast   = resample(ma_syllable, 90, 100);
gan_fast  = resample(gan_syllable, 90, 100);
dang_fast = resample(dang_syllable, 90, 100);

% Sentence 1
pon_fast  = resample(pon_syllable, 95, 100);
s1_dang_syllable = resample(dang_syllable, round(0.85*100), 100);
s1_ha_syllable = resample(ha_syllable, round(0.85*100), 100);

sentence = [ma_fast; 
             gan_fast; 
             s1_dang_syllable; 
             s1_ha_syllable; 
             pon_fast];

figure;
plot((0:length(sentence)-1) / Fs, sentence);
xlabel('Time (s)');
ylabel('Amplitude');
title('Good afternoon');
sound(sentence, Fs);


pause(3)


% Sentence 2: /Magandang ha'pon?/ 
% turning 'hapon! to ha'pon?

% reducing the amplitude and duration of ha
ha_unstressed = 0.6 * ha_syllable(1:floor(length(ha_syllable)*0.7)); 

% gradually increasing pitch for 'pon' 
pon_syl_ques = [];
N = length(pon_syllable)
t = (0:N-1)/Fs;
for i = 1:60
    start_idx = floor((i-1)*N/60) + 1;
    end_idx   = floor(i*N/60);
    segment = pon_syllable(start_idx:end_idx);
    
    factor = 1 - i*0.005;
    seg_resampled = resample(segment, round(factor*100), 100);

    %adding the fade effects to remove cracking/hissing sounds
    fade_in = linspace(0,1,length(seg_resampled));
    fade_out = linspace(1,0,length(seg_resampled));
    
    seg_resampled = 3.*seg_resampled .* fade_in' .* fade_out';  
    pon_syl_ques = [pon_syl_ques; seg_resampled];
end


out_sentence = [
             ma_syllable
             gan_syllable
             dang_syllable
             ha_unstressed; 
             pon_syl_ques];

figure;
plot((0:length(out_sentence)-1) / Fs, out_sentence);
xlabel('Time (s)');
ylabel('Amplitude');
title('Magandang hapon? (beautiful japanese?)');
sound(out_sentence, Fs);

pause(3)

% Sentence 3: /Magandang ga'bi!/
ga_fast = resample(ga_syllable, 90, 100);
% add stress and falling Intonation 
% divide the syllable /bi/
mid = round(length(bi_syllable) / 2);
bi_p1 = bi_syllable(1:mid);
bi_p2 = resample(bi_syllable(mid+1:end), 110, 100); % create a falling intonation, resample the second half to be 10% slower (lowers pitch)
env = [ones(length(bi_p1), 1); linspace(1, 0.4, length(bi_p2))']; % apply a volume decay envelope for a natural "tail"
bi_final = [bi_p1; bi_p2] .* env * 2.0; % 2.0x Gain for Exclamatory Stress (!)

%combine for sentence 3
sentence_3 = [ma_fast; gan_fast; dang_fast; ga_fast; bi_final];

figure;
plot((0:length(sentence_3)-1)/Fs, sentence_3);
xlabel('Time (s)');
ylabel('Amplitude');
title("/Magandang ga'bi!/ (Good evening!)");
sound(sentence_3, Fs);
audiowrite("sentence3.wav", sentence_3, Fs);
