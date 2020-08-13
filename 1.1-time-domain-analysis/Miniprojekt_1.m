%% E3DSB miniprojekt 1 - Tidsdom�neanalyse
%%
% <latex>
% \chapter{Indledning}
% Dette f�rste miniprojekt i E3DSB behandler tre lydsignaler med analyser i tidsdom�net.
% Opgaven er l�st individuelt.
% Dette dokument er genereret i Matlab med en XSL-template.
% Matlab-kode og template findes p� \url{https://github.com/janusboandersen/E3DSB}.
% F�lgende lydklip benyttes \\
% \begin{table}[H]
% \centering
% \begin{tabular}{| c | c | c | c |} \hline
% Signal & Sk�ring & Genre & Samplingsfrekv. \\ \hline
% $s_1$ & Spit Out the Bone & Thrash-metal & 44.1 \si{\kilo\hertz} \\ \hline
% $s_2$ & The Wayfaring Stranger & Bluegrass & 96 \si{\kilo\hertz} \\ \hline
% $s_3$ & Svanes�en & Klassisk & 44.1 \si{\kilo\hertz} \\ \hline
% \end{tabular}\caption{3 signaler behandlet i analysen}\label{tab:lydklip}\end{table}
% </latex>
%%
% <latex>
% \chapter{Analyser}
% F�r analyser ryddes der op i \texttt{Workspace}.\\
% </latex>

clc; clear all; close all;
%% Afspilning af lydklip
%%
% <latex>
% Filen med signaler �bnes med \texttt{load}.
% Signaler kan afspilles med \texttt{soundsc(signal, fs)}.
% Samplingsfrekvensen $f_s$ s�ttes efter v�rdi i tabel~\ref{tab:lydklip}.
% Samplingfrekvenser for de tre signaler er inkluderet i
% \texttt{.mat}-filen.
% </latex>

load('miniprojekt1_lydklip.mat');   % �bn .mat-fil
soundsc(s1, fs_s1);                 % playback startes s�dan her
clear('sound');                     % stop playback

%% Bestemmelse af antal samples
%%
% <latex>
% Et sample er en v�rdi, eller s�t af v�rdier, fra et givent punkt i tid.
% Alle tre signaler er i stereo, s� hver sample har to v�rdier.\\\\
% Signalerne er repr�senteret som $N\times K$-matricer.
% Antallet af r�kker, $N$, repr�senterer antallet af samples.
% $N$ kan findes med \texttt{length(matrix)}.
% Antallet af s�ljer, $K$, er antallet af kanaler (v�rdier per sample).
% Samlet antal af v�rdier i matricen er $NK$, antaget at ingen er \texttt{NaN}.\\
% </latex>
%%
% <latex>
% $N$ og $K$ kan bestemmes p� en gang via \texttt{[N, K] = size(matrix)}.
% Vi kan ogs� bare benytte, at vi ved, at der er to kanaler, s� $K = 2$. \\\\
% Data samles i en tabel. Den kan udvides med signalernes afspilningstider.\\\\
% Der er alts� fx 1,323 millioner samples i signal $s_1$.
% Signal $s_2$, som dog har h�jere samplingsfrekvens, har 2,5 gange flere
% samples.
% De tre lydklip har afspilningstider p� mellem 30 og 35 sek.\\
% </latex>
%
%%
%
signaler = {'s1'; 's2'; 's3'};
N = [length(s1); length(s2); length(s3)];           % antal samples
K = [2; 2; 2];                                      % antal kanaler
M = N.*K;                                           % antal v�rdier
samplingsfrek = [fs_s1; fs_s2; fs_s3];              % f_s fra .mat-fil
tid = N./samplingsfrek;                             % spilletid i sek.
T = table(signaler, N, K, M, samplingsfrek, tid)    % vis en datatabel

%% Plot af signal
%%
% <latex> 
% N�r vi skal plotte signalerne med en tidsakse i sekunder, bruges det at
% $t = n T_s = \frac{n}{f_s}$. Man b�r plotte et diskret signal i et
% stem-diagram, dvs. \texttt{stem}-funktionen, men for at f� noget mindre
% gnidret at se p�, bruges \texttt{plot}. Til at danne akserne bruges
% Matlabs \texttt{:}-operator.\\\\
% </latex>
%
t1 = [0:1:N(1)-1]'/fs_s1;                   % s�jlevektor, dog ej vigtigt
t2 = [0:1:N(2)-1]'/fs_s2;
t3 = [0:1:N(3)-1]'/fs_s3;

% der g�res lidt arbejde for at f� et rent latex layout
set(groot, 'defaultAxesTickLabelInterpreter','Latex');
set(groot, 'defaultLegendInterpreter','Latex');
set(groot, 'defaultTextInterpreter','Latex');

figure(1)                                   % figur med 3 stablede subplots
subplot(3,1,1);
plot(t1,s1);                                % signal 1
ylabel('$s_1$','Interpreter','Latex', 'FontSize', 15);
subplot(3,1,2);
plot(t2,s2);                                % signal 2
ylabel('$s_2$','Interpreter','Latex', 'FontSize', 15);
subplot(3,1,3);
plot(t3,s3);                                % signal 3
ylabel('$s_3$','Interpreter','Latex', 'FontSize', 15);
xlabel('$t [s]$','Interpreter','Latex', 'FontSize', 15);

% og en titel for hele diagrammet
sgtitle('Plot af $s_1$, $s_2$, $s_3$', 'Interpreter', 'Latex', 'FontSize', 20);

%%
% <latex>
% Plots viser ret tydeligt store forskelle i lydklippenes ``intensitet''.
% Forst�et p� den m�de, at lydklippet med thrash-metal har en gennemg�ende
% h�j amplitude (opleves som ``h�jt''), i mods�tning til fx det klassiske stykke. 
% Nogle ville nok bare mene, at plottet over Metallicas nummer ligner ``st�j'' :-).\\\\
% N�ste analyse kan m�ske give numeriske m�l p� disse visuelle observationer.\\
% </latex>
%
%% Min, max, energi og RMS
%%
% <latex>
% I dette afsnit beregnes forskellige m�l p� signalernes lydm�ssige ``karakter''.\\
% </latex>
%
%% 
% <latex>
% \textbf{Overvejelser:}~ 
% Signalerne er i stereo (2 kanaler / s�jler).
% Hvis vi har et system med to h�jttalere, giver det mening at betragte kanalerne separat (ikke sammenlagt).
% Alts�, jeg analyserer kanalerne i forl�ngelse, som en mono serie med $M=2N$ samples.
% Denne l�sning bruges, fordi det er s�dan et menneske med to �rer og s�t hovedtelefoner ville opleve signalet :-).
% Det er ogs� proportionalt til effekt og energiafs�ttelse i et system med to h�jttalere.\\\\
% En sum eller et gennemsnit p� tv�rs af kanalerne ville betyde, at kanaler
% ude af fase kunne cancellere/eliminere hinanden.
% Dette ville m�ske give mening som en simpel konvertering til mono, dvs. vi
% kunne beregne m�l p� hvad der ville ske i et simpelt mono-system.\\
% </latex>
%%
% <latex>
% \textbf{Beregning:}~ 
% Minimum og maksimum findes med hhv. \texttt{min()}~ og \texttt{max()}.
% I tidsdom�net er effekten af et signal proportionalt til kvadratet p�
% amplituden. For en sekvens $x(n) \in \mathbb{R}$, $n = 0,\ldots,N-1$ 
% defineres effekten som $x_{pwr}(n) = |x(n)|^2 = x(n)^2 $.
% I diskret tid er energien i signalet summen af ``effekterne'', dvs.
% $E_x = \sum_{n=0}^{N-1} |x(n)|^2 $.
% Dette er ogs� det indre produkt $\langle x(n), x(n) \rangle$.
% RMS-v�rdien kan beregnes som kvadratroden af middeleffekten, dvs.
% $x_{RMS} = \sqrt{\frac{1}{N}E_x}$.
% Nu regnes alle serier s� blot over $n = 0, \ldots, 2(N-1)$ jf. overvejelserne ovenfor.\\
% </latex>
%

s1_vec = reshape(s1,[],1);      % Reshape matricer til s�jlevektorer:
s2_vec = reshape(s2,[],1);      % De har nu hver M = 2N r�kker og 1 s�jle
s3_vec = reshape(s3,[],1);      % N, M er selvf�lgelig forskellige for hver

minima = [min(s1_vec); min(s2_vec); min(s3_vec)];
maxima = [max(s1_vec); max(s2_vec); max(s3_vec)];
energi = [sum(s1_vec.^2); sum(s2_vec.^2); sum(s3_vec.^2)];     % kvadratsum
rms = [energi(1)/M(1); energi(2)/M(2); energi(3)/M(3)].^(1/2); % kv.rod

T = table(signaler, N, M, minima, maxima, energi, rms)         % resultater

%%
% Resultaterne (i tabellen) viser det, som plots ogs� illustrerede:
% Der er mere energi i metal end i klassisk og bluegrass :-)
% Og h�jttalerne bliver varmere af at spille Metallica end af Tchaikovsky.
% 
%% Venstre vs. h�jre kanal (for $s_1$)
%%
% <latex>
% Man kan eksperimentere lidt for at finde ud af hvilken kanal, der er
% h�jre, og hvilken der er venstre. 
% Man kan jo fx fylde den ene kanal med nuller, og s� se, hvad der ``sker''.
% Stereo bibeholdes ved at fastholde matricens $N\times K$-st�rrelse, men
% med en kanal ``nullet''.\\
% </latex>
%
s1_left_stereo = s1;
s1_left_stereo(:,2) = zeros(N(1),1); % Nuller "h�jre" via 2. kanal
soundsc(s1_left_stereo, fs_s1);      % Bingo, det virkede
clear sound;

s1_right_stereo = s1;
s1_right_stereo(:,1) = zeros(N(1),1); % Nuller "venstre" via 1. kanal
soundsc(s1_right_stereo, fs_s1);      
clear sound;

%%
% <latex>
% Differensen mellem kanalerne kan ogs� aflyttes.
% Vi tager venstre minus h�jre.\\
% </latex>
%
s1_diff_mono = s1(:,1) - s1(:,2);       % venstre minus h�jre
soundsc(s1_diff_mono, fs_s1);
clear sound;

%%
% <latex>
% Differensen mellem kanalerne giver en effekt af at lyden ``kommer'' et
% bestemt sted fra, rumligt/spatialt (eller evt. at der er en genklang).
% Fx vil en lille forsinkelse i den h�jre kanal snyde hjernen til at tro, at
% lyden kom fra et sted t�ttere p� det venstre �re.
% Forsinkelse kan derfor benyttes til at ``flytte'' instrumenternes lyd i
% rummet.\\\\
% I dette lydklip oplever jeg, at alle instrumenter er tilstede i b�de
% venstre og h�jre kanal, men i forskellig grad. Differensen afsl�rer, at:
% \begin{itemize}
% \item Den hurtige lyd af J. Hetfields downpicking/strumming bev�ger sig
% mellem kanalerne.
% \item Det g�r lyden af L. Ulrichs lilletromme til dels ogs�.
% \item Det giver en fornemmelse af at v�re omringet af lyden.
% \item Desuden er L. Ulrichs hi-hat placeret til venstre for midten p� enkeltslagene, 
% men til h�jre for midten p� triple-slaget.
% \end{itemize}
% Hvis klippet havde v�ret l�ngere, havde vi ogs� tydeligt h�rt den fede og
% lidt mere melodiske del af guitarriffet (som starter ca. 40 sekunder
% inde) placeret i venstre kanal.\\
% </latex>
%
%% Nedsampling af signal (for $s_1$)
%%
% <latex>
% Der laves en nedsampling af signalet med en faktor 4.
% Funktionen \texttt{resample(signal, fs\_ny, fs\_gl)}~ benyttes.\\
% </latex>

fs_s1_ny = fs_s1 / 4;                           % reduktion med faktor 4
s1_downsample = resample(s1, fs_s1_ny, fs_s1);  % downsampling
txt = sprintf("Nyt antal samples: %d", length(s1_downsample));
disp(txt);

soundsc(s1_downsample, fs_s1_ny);               % afspil nyt klip
clear sound;
%%
% Det h�res tydeligt, at downsampling har reduceret lydkvaliteten.
% Klippet lyder nu mere som internetradio i 90'erne, eller en d�rlig
% YouTube-video.
%
%% Fade-out med envelopes (for $s_2$)
%%
% <latex>
% Vi vil lave fade-out over den sidste tredjedel af signalet.
% Dvs. cirka de sidste 12 af de i alt 35 sekunder.
% Helt pr�cist skal indhyldningskurven p�virke de sidste 1,12 mio. samples.
% Alts� $N_{env,2} = \frac{1}{3} N_2 = 3360000/3 = 1120000$.
% Der benyttes to forskellige metoder:
% \begin{itemize}
% \item Line�r envelope fra 100 til 5 pct.
% \item Eksponentielt aftagende envelope fra 100 til 5 pct.
% \end{itemize}
% Metoden bliver at lave envelopes med den �nskede l�ngde, og s� applicere
% dem p� den sidste tredjedel af signalet.\\
% </latex>
%
%%
% <latex>\subsection{Line�r envelope}</latex>
%%
% <latex>
% Der skal over $N_{env,2}$~ samples foretages en \textbf{line�r} ``afskrivning''.
% Funktionen er $f_{lin}(n) = -\alpha n$ for $n=0,\ldots,N_{env,2}-1$.
% Yderpunkterne s�ttes $f_{lin}(0) = 1$ og $f_{lin}(N_{env,2}-1) = 0.05$.
% Det giver en h�ldning p� $ \alpha = -\frac{(0.05-1.00)}{N_{env,2}-1}=8.48\cdot 10^{-7}$.\\\\
% Men det er naturligvis nemmere bare at bruge \texttt{linspace}...
% </latex>
%
N_env2 = N(2)/3;                            % antal samples der skal filtr.
lin_env2 = linspace(1.0, 0.05, N_env2)';    % line�r envelope

%%
% <latex>\subsection{Eksponentiel envelope}</latex>
%%
% <latex>
% Der skal over $N_{env,2}$~ samples foretages en \textbf{eksponentiel} ``afskrivning''.
% Funktionen er $g_{exp}(n) = \exp(-\gamma n)$ for $n=0,\ldots,N_{env,2}-1$.
% Yderpunkterne s�ttes $g_{exp}(0) = 1$ og $g_{exp}(N_{env,2}-1) = 0.05$.
% Det giver med lidt omskrivning en faktor p� $ \gamma = -\frac{\ln(0.05)}{N_{env,2}-1}=2.67\cdot 10^{-6}$.\\\\
% </latex>
% 
gamma = -log(0.05)/(N_env2 - 1);            % nb. ln = log()
exp_env2 = exp(-gamma*[0:N_env2-1])';       % vektoriseret exp envelope

%%
% 
%%
% <latex>\subsection{Sammenligning af envelopes}</latex>
%%
% <latex>
% De to envelopes (indhyldningskurver) plottes, s� vi kan se, om vi har
% f�et hvad vi �nskede...\\
% </latex>
%
figure(2)
subplot(2,1,1);
plot(lin_env2);
ylabel('$-\alpha n$','Interpreter','Latex', 'FontSize', 15);
dim1 = [.2 .45 .3 .3];                   % Placering af annotation
str_lin = '$\alpha = 8.48\cdot10^{-7}$';
annotation('textbox',dim1,'Interpreter', 'Latex', 'String',str_lin,'FitBoxToText','on', 'FontSize', 15);

subplot(2,1,2);
plot(exp_env2);
ylabel('$\exp(-\gamma n)$','Interpreter','Latex', 'FontSize', 15);
str_exp = '$\gamma = 2.67\cdot10^{-6}$';
dim2 = [.2 .13 .0 .3];                  % Placering af annotation
annotation('textbox',dim2,'Interpreter', 'Latex', 'String',str_exp,'FitBoxToText','on', 'FontSize', 15);

xlabel('$n$','Interpreter','Latex', 'FontSize', 15);
sgtitle('Sammenligning af envelopes', 'Interpreter', 'Latex', 'FontSize', 20);

%%
% Envelopes p�trykkes signalet direkte, selvom man nok ogs� kunne have
% brugt |filter|-funktionen.
%
pad_ones = ones([2*N_env2, 1]);         % pad med 1-taller n�r sig. ej �ndr
tot_lin_fade = [pad_ones; lin_env2];    % sammens�t for hele serien
tot_exp_fade = [pad_ones; exp_env2];

% Fade p�trykkes hver kanal
s2_lin_fade = s2;
s2_exp_fade = s2;
for k=1:2
    s2_lin_fade(:,k) = s2_lin_fade(:,k) .* tot_lin_fade;  % p�tryk line�r
    s2_exp_fade(:,k) = s2_exp_fade(:,k) .* tot_exp_fade;  % p�tryk eksp.
end

% Afspil resultaterne
soundsc(s2_lin_fade, fs_s2);
clear sound;

soundsc(s2_exp_fade, fs_s2);
clear sound;

%%
% Det er nok smag og behag med de to forskellige typer. Jeg bryder mig
% bedst om den eksponentielle fade-out, fordi den hurtigere reducerer
% lydstyrken. Det mest naturlige ville nok v�re en logaritmisk fade, der
% matcher vores �rers og hjernes evne til at opfatte forskelle i
% lydniveauer, hvilket netop oftest er ``efter'' logaritimisk skala.
%
%%
% <latex>\chapter{Konklusion}</latex>
%%
% <latex>
% Dette miniprojekt har vist, hvordan man kan arbejde med digitale lydsignaler i
% Matlab.\\\\
% Det er interessant, hvordan relativt simple matematiske metoder kan
% benyttes til at analysere og behandle digitale lydsignaler. Matlab g�r
% arbejdet nemt for os.
% </latex>
%  