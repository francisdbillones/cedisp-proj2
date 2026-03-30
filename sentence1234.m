% CEDISP1 Project - Phase 2: Speech Synthesis
% S30 PG02
% Billones, Francis Hubert
% Go, John William
% Lopez, Kent Xavier
% Placer, Paul John

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
dang_syllable = x(t >= 2.71 & t <= 3.1);
ha_syllable = x(t >= 3.85 & t <= 4.11);
pon_syllable = x(t >= 4.88 & t <= 5.2);
ga_syllable = x(t >= 6.98 & t <= 7.1);
bi_syllable = x(t >= 8.00 & t <= 8.33);
o_syllable = x(t >= 5.87 & t <= 6.18);

% Speed up "Magandang" for greeting (10% faster)
ma_fast = resample(ma_syllable, 90, 100);
gan_fast = resample(gan_syllable, 90, 100);
dang_fast = resample(dang_syllable, 90, 100);

% Sentence 1: /Magandang 'hapon!/
% Stressed "dang" and "ha", falling intonation for "pon"
s1_dang_syllable = resample(dang_syllable, round(0.825*100), 100);
s1_ha_syllable = resample(ha_syllable, round(0.825*100), 100);
pon_fast  = resample(pon_syllable, 95, 100);

sentence_1 = [
    ma_fast; 
    gan_fast; 
    s1_dang_syllable; 
    s1_ha_syllable; 
    pon_fast
];

% Sentence 2: /Magandang ha'pon?/ 
% turning 'hapon! to ha'pon?

% reducing the amplitude and duration of ha
ha_unstressed = 0.6 * ha_syllable(1:floor(length(ha_syllable)*0.7)); 

% gradually increasing pitch for 'pon' 
pon_syl_ques = [];
N = length(pon_syllable);
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

sentence_2 = [
    ma_syllable
    gan_syllable
    dang_syllable
    ha_unstressed; 
    pon_syl_ques
];

% Sentence 3: /Magandang ga'bi!/
ga_fast = resample(ga_syllable, 90, 100);
% add stress and falling Intonation 
% divide the syllable /bi/
mid = round(length(bi_syllable) / 2);
bi_p1 = bi_syllable(1:mid);
bi_p2 = resample(bi_syllable(mid+1:end), 110, 100); % create a falling intonation, resample the second half to be 10% slower (lowers pitch)
env = [ones(length(bi_p1), 1); linspace(1, 0.4, length(bi_p2))']; % apply a volume decay envelope for a natural "tail"
bi_final = [bi_p1; bi_p2] .* env * 2.0;  % 2.0x gain to distinguish ga'bi from 'gabi

% combine for sentence 3
sentence_3 = [ma_fast; gan_fast; dang_fast; ga_fast; bi_final];

% Sentence 4: /Magandang 'gabi, o ga'bi?/
s4_ga_syllable = x(t >= 6.90 & t <= 7.32); % Using longer ga mapping for sentence 4

% 'ga is stressed -> increase amplitude
ga_decl = s4_ga_syllable * 1.5;

% bi has falling intonation at the end
mid = round(length(bi_syllable) / 2);
bi_part1 = bi_syllable(1:mid);
bi_part2 = bi_syllable(mid+1:end);

% create a falling intonation, resample the second half to be 25% slower (lowers pitch)
bi_part2_falling = resample(bi_part2, 125, 100);

% Combine and apply a volume decay envelope for a natural "tail"
s_bi_decl = [bi_part1; bi_part2_falling];
env_fall = [ones(length(bi_part1), 1); linspace(1, 0.4, length(bi_part2_falling))'];
s_bi_decl = s_bi_decl .* env_fall;

glottal = zeros(round(0.01 * Fs), 1); % tiny space between syllables

% Trim silences for a shorter pause between 'ga' and 'bi' in the first word
ga_decl_trim = ga_decl(1:end - round(0.12 * Fs)); % remove 120ms trailing silence
bi_decl_trim = s_bi_decl(round(0.08 * Fs):end);   % remove 80ms leading silence

declarative = [ma_fast; gan_fast; dang_fast; glottal; ga_decl_trim; bi_decl_trim];

pause_comma = zeros(round(0.25 * Fs), 1); % 250ms pause

% o stays normal
o_int = o_syllable;

% ga stays normal
ga_int = s4_ga_syllable;

% 'bi is stressed and has a rising intonation for the question
% We resample the second half to be 25% faster (raises pitch)
bi_part2_rising = resample(bi_part2, 75, 100);

% Combine and apply higher volume for stress and question emphasis
s_bi_int = [bi_part1; bi_part2_rising];
env_rise = [ones(length(bi_part1), 1); linspace(1, 1.3, length(bi_part2_rising))'];
s_bi_int = s_bi_int .* env_rise * 2.0; % 2.0x Gain for question stress

interrogative = [o_int; glottal; ga_int; s_bi_int];

sentence_4 = [declarative; pause_comma; interrogative];

% Normalize to prevent clipping
sentence_4 = sentence_4 / max(abs(sentence_4)) * 0.9;

% combine all 4 sentences and 1 second silence between each sentence
combined_sentences = [
    sentence_1; 
    zeros(Fs,1);   
    sentence_2; 
    zeros(Fs,1);
    sentence_3;
    zeros(Fs,1);
    sentence_4;
];

sound(combined_sentences, Fs); % play combined sentences

%subplot all four sentences
figure (2);
subplot(4,1,1);
plot((0:length(sentence_1)-1)/Fs, sentence_1);
title("Sentence 1: /Magandang 'hapon!/ (Good afternoon!)");
xlabel('Time (s)'); ylabel('Amplitude');

subplot(4,1,2);
plot((0:length(sentence_2)-1)/Fs, sentence_2);
title("Sentence 2: /Magandang ha'pon?/ (Beautiful Japan/Japansese?)");
xlabel('Time (s)'); ylabel('Amplitude');

subplot(4,1,3);
plot((0:length(sentence_3)-1)/Fs, sentence_3);
title("Sentence 3: /Magandang ga'bi!/ (Good evening!)");
xlabel('Time (s)'); ylabel('Amplitude');

subplot(4,1,4);
plot((0:length(sentence_4)-1)/Fs, sentence_4);
title("Sentence 4: /Magandang 'gabi, o ga'bi?/");
xlabel('Time (s)'); ylabel('Amplitude');

% write synthesized sentences in WAV files
audiowrite("sentence_1_02.wav", sentence_1, Fs);
audiowrite("sentence_2_02.wav", sentence_2, Fs);
audiowrite("sentence_3_02.wav", sentence_3, Fs);
audiowrite("sentence_4_02.wav", sentence_4, Fs);
