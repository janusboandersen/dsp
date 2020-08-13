%% E4DSA Case 2 - IIR notch-filter og real-time-implementering p� TMS320C5535
%%
% <latex>
% \chapter{Indledning}
% Anden case i E4DSA er design og real-time-implementering af et IIR
% notch-filter p� DSP-hardware.
% Filteret er designet og testet i \MATLAB . \MATLAB~er ogs� brugt til at 
% kvantisere koefficienter og teste fixed-point filter-algoritmen. 
% Filteret er implementeret p� DSP-hardware vha. Code Composer Studio
% (CCS). Target er TMS320C5535 (eZDSP kit).
% \MATLAB~og C-kode er gengivet med forskellige baggrundsfarver for lette
% genkendelighed i denne journal.
% \\�\\
% Beklager, at journalerne bliver lange; men det er ogs� for at
% kunne have detaljerne til fremtiden.
% </latex>

%%
% <latex>
% \chapter{Opgave 1: Analyse af inputsignal}
% Inputsignalet er ``Bright Side of the Road'' af Van Morrison
% fra albummet ``Into the Music'' (1979).
% Signalet indeholder de f�rste \SI{60}{\second} af nummeret.
% Signalet er i mono, 32-bit floating point, og samplingsfrekvensen er 
% \SI{48}{\kilo\hertz} (professionel standard).
% Nummeret er blevet saboteret med en ren sinustone, 
% der er ekstremt ubehagelig at lytte til i mere end et par sekunder.
% S� den skal fjernes.
% Tonens frekvens er fundet vha. spektralanalysen nedenfor.
% \\
% </latex>

%%
%
clc; clear all; close all;
%%
%
[x, fs] = audioread('musik_tone_48k.ogg');
% soundsc(x, fs);
% clear sound;

%%
% <latex>
% Spektrogrammet beregnes med rullende FFT'er.
% De f�rste \SI{5}{\second} vises her, men 
% sinustonen er station�r i hele signalets l�ngde.
% Hver FFT er zero-padded\footnote{Det giver p�nere spektrum, ``sampler'' DTFT'en p� flere punkter}.
% Vinduesl�ngden p� $L=\frac{f_s}{5}=9600$ samples giver et ok
% trade-off mellem frekvensopl�sning og tidsopl�sning.
% $\Delta f = \frac{f_s}{L} = 5.0$ Hz og tidsopl�sning $T_{STFT} = \frac{L}{f_s} = 0.20$ sek.
% Steppet er sat, s� der ikke er overlap p� vinduer.
% Der laves 25 FFT'er\footnote{Der analyseres \SI{5}{\second} signal med \SI{5}{STFT\per\second}, s� i alt 25 FFT'er beregnes}.
% \\
% </latex>

tl = 5;                              % tidsl�ngde til analyse, sekunder
x_ = x(1:tl*fs)';                    % udvalgt sektion af signal
L = fs/5;                            % vinduesl�ngde 9600 => 5 Hz opl�sning
stepSize = L;                        % step er 1 vindue (0% overlap)
Nfft = 2^nextpow2(L);                % 2^14
figure();
spectrogram0(x_, L, Nfft, stepSize, fs, [0 5000]); % Vis kun op til 5 kHz

%%
% <latex>
% Spektrogrammet viser ved den r�de vandrette streg en station�r ren tone 
% omkring \SI{875}{\hertz}.
% \\�\\
% Pga. lav grafikopl�sning i figuren ser det ogs� ud som om, at der er en 
% ren tone ved en lavere frekvens (100 Hz?).
% Hvis der zoomes ind, ses det dog, at denne hverken er station�r eller er 
% til stede konstant.
% \\�\\
% En enkelt FFT med 240000 samples benyttes for at pinpointe den eksakte 
% frekvens for den forstyrrende tone.
% Det giver en frekvensopl�sning p� $\Delta f = 0.2$ Hz.
% Der zero-paddes igen.
% Figuren nedenfor viser, at den forstyrrende tone er lokaliseret 
% ved $876 \pm$\SI{0.2}{\hertz}.
% \\
% </latex>

Nfft = 2^nextpow2(length(x_));      % 2^18 -> zero-padding med 22144 0'er 
X_ = fft(x_, Nfft);
X_pow = X_ .* conj(X_);             % Powerspektrum
f_vec = (fs / Nfft) * (0:Nfft-1);   % Tilh�rende frekvensakse
[val, idx] = max(10*log10(X_pow));  % Find frekvenssample med h�jeste power
fidx = f_vec(idx);                  % Tilh�rende frekvensbin

figure();
plot(f_vec, 10*log10(X_pow)); hold on;
plot(fidx, val, 'ro'); hold off;
xlim([850 900]); grid on;
legend({'Powerspektrum',['Tone: ', num2str(round(fidx)), ' Hz']});
ylabel('$|X(f)|^2$', 'Interpreter','Latex', 'FontSize', 12);
xlabel('Frekvens, $f$ [Hz]', 'Interpreter','Latex', 'FontSize', 12);
title('Powerspektrum for $x(t)$, $t=0 \ldots 5s $', ...
    'Interpreter', 'Latex', 'FontSize', 14)

%%
% <latex>
% Der optr�der ingen harmoniske af de \SI{876}{\hertz} (det kunne jo sagtens have v�ret tilf�ldet).
% Det kan ikke ses her, men det er unders�gt.
% Vi slipper derfor for at implementere noget mere avanceret, som fx et comb-filter. 
% Planen er nu at designe et notch-filter\footnote{Narrow-band b�ndstop}, der d�mper/filtrerer
% pr�cis frekvensen \SI{876}{\hertz} bort.
% </latex>
%%
% <latex>
% \chapter{Opgave 2: Filterdesign}
% Filteret skal v�re 2. orden af typen IIR, og skal designes vha. placering
% af poler og nulpunkter. Det kan man g�re manuelt for en lav filterorden.
% Vi kender allerede centerfrekvensen, som kan omregnes til vinklen for de
% kompleks-konjugerede nulpunkter (og tilh�rende poler).
% \\
% </latex>

%%
% <latex>
% \section{Pol-nulpunktsplacering i et digitalt notch-filter}
% Et 2. ordens digitalt notch-filter har to ``pol-nulpunktspar''.
% Pol og nulpunkt i et par placeres p� en radial, alts� med samme vinkel, 
% hvilken netop afg�r filterets centerfrekvens. 
% Et pol-nulpunktspar har et kompleks-konjugeret pol-nulpunktspar.
% Dvs. filteret alt-i-alt har to poler og to nulpunkter.
% Pol og nulpunkt skal ligge \textit{t�t} p� hinanden.
% Nulpunktet kan ligge p� enhedscirklen, 
% og modulus for polen skal v�re mindre end modulus for nulpunktet.
% Polerne skal ligge inden for enhedscirklen for at sikre stabilitet.
% \\�\\
% Ideen er, at ved evaluering af frekvensrespons $H(e^{j \omega})$ 
% rundt p� enhedscirklen, vil pol og nulpunkt i et par oph�ve hinanden 
% set for frekvenser relativt langt v�k fra centerfrekvensen (fordi parret ligger t�t).
% For frekvenser t�t p� centerfrekvensen vil nulpunktet blive 
% dominerende, fordi det ligger relativt t�ttere p� enhedscirklen end polen.
% Nulpunktet giver netop d�mpningen i centerfrekvensen.
% \\ \\
% S� l�nge pol og nulpunkt ikke ligger oveni hinanden, vil det v�re s�dan,
% at jo t�ttere de er p� hinanden, jo skarpere bliver notchet.
% \MATLAB s \texttt{filterDesigner} kan bruges til analysen.
% \\�\\
% Der er en gr�nse for hvor skarpt/stejlt et filter, der
% kan implementeres p� fixed-point. 
% Det er grundet den finitte pr�cision i kvantisering af koefficienter samt
% i beregninger.
% Modulus for polerne i filteret, der udvikles nedenfor, er fundet
% iterativt i et trade-off mellem at have et skarpt notch og at have et
% filter, som performer godt p� target fixed-point platformen.
% </latex>

%%
% <latex>
% \section{Ligninger for et digitalt notch-filter}
% Centerfrekvensen for notch-filteret er $\omega_c$ [rad/s] med
% $\omega_c=\pi \frac{f_c}{f_s / 2}$.
% Modulus for nulpunkterne v�lges til 1, og for polerne $r<1$.
% Da pol-nulpunktsparrene er komplekst konjugerede, f�s f�lgende nulpunkter og poler:
% $z_0=e^{j\omega_c}$, 
% $z_1=e^{-j\omega_c}$, 
% $p_0=r e^{j\omega_c}$ og
% $p_1=r e^{-j\omega_c}$.
% Filterets overf�ringsfunktion findes i den faktoriserede form \cite[6-38 s. 285]{lyons}:
% \begin{equation}
%  H(z) = \frac{(z-z_0)(z-z_1)}{(z-p_0)(z-p_1)} 
%  = \frac{(z-e^{j\omega_c})(z-e^{-j\omega_c})}{(z-r e^{j\omega_c})(z-r e^{-j\omega_c})}
% \end{equation}
% Ganges paranteserne ud og benyttes Eulers relation
% $2\cos(\omega)=e^{j\omega}+e^{-j\omega}$, s� har vi:
% \begin{equation}
% H(z) = \frac{z^2-2\cos(\omega_c)z+1}{z^2-2r\cos(\omega_c)z+r^2} 
% \end{equation}
% Overf�ringsfunktionen er alts� en ratio af to polynomier med reale
% koefficienter, og svarer til \cite[ex. 6.14 s. 340]{lyons}.
% For nemheds skyld indf�res nu en gain-faktor $G$ til at
% normalisere responset til et gain p� 1 i pasb�ndet, og der forkortes med
% $z^{-2}$ for at se systemfunktionen \cite[6-25 s. 277]{lyons}:
% \begin{equation}
% \begin{aligned}
% \frac{Y(z)}{X(z)} = G \cdot H(z) &= G \frac{1 - 2\cos(\omega_c)z^{-1} + z^{-2}}{1 - 2r\cos(\omega_c)z^{-1} + r^2 z^{-2}}
%              \equiv \frac{b_0 + b_1 z^{-1} +  b_2 z^{-2}}{a_0 - a_1
%              z^{-1} - a_2 z^{-2}} = \frac{B(z)}{A(z)}
% \end{aligned}
% \end{equation}
% Ved sammenligning ses, at $b_0 = b_2 = G$, $b_1 = -2G\cos(\omega_c)$,
% $a_0=1$ (altid!), $a_1 = 2r\cos(\omega_c)$ og $a_2=-r^2$. 
% Ovenst�ende omskrives til IIR-filterets output i z-dom�net:
% \begin{equation}
% \begin{aligned}
% & Y(z)(1 - 2r\cos(\omega_c)z^{-1} + r^2 z^{-2}) = X(z)G(1-2\cos(\omega_c)z^{-1}+z^{-2}) \\
% \Longrightarrow Y(z) &= GX(z)-2G\cos(\omega_c)z^{-1}X(z)+Gz^{-2}X(z) + 2r\cos(\omega_c)z^{-1}Y(z)-r^2 z^{-2}Y(z)
% \end{aligned}
% \end{equation}
% Differensligningen findes via den inverse z-transformation heraf.
% Her benyttes delay-relationen: hvis
% $X(z)\longleftrightarrow x(n)$ s� $z^{-k}X(z) \longleftrightarrow
% x(n-k)$. Dette giver differensligningen, og ved sammenligning med 
% standardformen kan koefficienterne bekr�ftes \cite[6-21 s. 276]{lyons}:
% \begin{equation}
% \begin{aligned}
% y(n) & = Gx(n)-2G\cos(\omega_c)x(n-1)+Gx(n-2) + 2r\cos(\omega_c)y(n-1) - r^2 y(n-2) \\
%      & \equiv b_0 x(n) + b_1 x(n-1) + b_2 x(n-2) + a_1 y(n-1) + a_2 y(n-2)
% \end{aligned}
% \end{equation}
% </latex>

%%
% <latex>
% \section{Design af notch-filter}
% For $f_c = 876$ Hz er $\omega_c = 0.1147$ rad/s.
% V�rdien for $r$ svarer til ``selectivity'' (Q-faktor) for et analogt
% notch-filter: Jo h�jere $r$, jo stejlere filter\footnote{Der m� v�re en
% algebraisk sammenh�ng via den biline�re transformation?}.
% For et analogt filter er Q-faktor givet ved $Q=\frac{\omega_c}{\text{Bandwidth}}$.
% Antaget nogenlunde tilsvarende for det digitale filter: b�ndbredden
% omkring notch-frekvensen mindskes som $r$ �ges.
% V�rdien $r$ er valgt til $r=0.99$ (ved iterative fors�g) for at f� et 
% stejlt filter, der ogs� fungerer godt p� target.
% Dermed kan filterets koefficienter beregnes:
% \\
% </latex>

r = 0.99;                          % Modulus for poler ("Q-faktor")
wc = pi * round(fidx) / (fs / 2);   % Centerfrekvens [rad/s]
K = 1;                              % Til f�rste iteration af DC gain

for iteration=1:2
    G = 1/K;                % Skalering s� DC Gain = 1 (0 dB). G=0.9991.

    % F�lgende koefficienter ift. differensligning.
    b0 = G;                 % z^0
    b1 = -2*cos(wc)*G;      % z^-1
    b2 = G;                 % z^-2
    a1 = 2*r*cos(wc);       % z^-1
    a2 = -r*r;              % z^-2

    % F�lgende polynomier ift. overf�ringsfkt.
    b = [b0 b1 b2];         % B(z)
    a = [1 -a1 -a2];        % A(z)

    K = sum(b)/sum(a);      % DC gain (Lyons s. 300)
end

%%
% <latex>
% \section{Pol-/nulpunktsdiagram}
% Figuren nedenfor viser, hvad der indledningsvist blev beskrevet
% om pul-nulpunktsplacering:
% De ligger meget t�t, med nulpunkterne p� enhedscirklen.
% \\
% </latex>
p = roots(a);                                   % Find poler

figure()
sgtitle('Pol-nulpunktsplacering for notch-filter')
subplot(211)
zplane(b,a); grid on;

subplot(212)
zplane(b,a); grid on;
title('Udsnit: Et pol-nulpunktspar')
xlim([real(p(1))*0.9 real(p(1))*1.1]);      % Vis t�t udsnit af et pol-
ylim([imag(p(1))*0.8 imag(p(1))*1.2]);        % nulpunktspar

%%
% <latex>
% \section{Differensligning og systemfunktion}
% Differensligningen nedenfor er ikke til direkte implementering p� DSP,
% da koefficienter skal skaleres og kvantiseres f�rst.
% Overf�ringsfunktion er ogs� opskrevet.
% \\
% </latex>

% Differensligning:
feedforward = [num2str(b0) ' x(n) ' ... 
               num2str(b1) ' x(n-1) + ' ...
               num2str(b2) ' x(n-2)'];
feedback =    [num2str(a1) ' y(n-1) ' ...
               num2str(a2) ' y(n-2) '];
diffeq = ['y(n) = ' feedforward ' + ' feedback];
disp(diffeq);

Hsys = tf(b, a, 1/fs)   % Vis fin overf�ringsfunktion

%%
% <latex>
% \section{Signalgraf (direkte form 1)}
% Filteret bliver implementeret p� direkte form 1.
% Figuren nedenfor viser filterstrukturen.
% V�rdien af koefficienterne er angivet i foreg�ende afsnit.
% Disse er f�rst endelige efter skalering og kvantisering til target.
% \\
% \begin{figure}[H]
% \centering
% \includegraphics[width=11cm]{../img/signalflow_case2.png}
% \caption{Signalgraf\label{fig:signalflow}}
% \end{figure}
% Signalgrafen viser, at denne implementering er en kaskade af en 
% feedforward-sektion og en feedback-sektion \cite[s. 158]{kuo2013}.
% Ved implementering i C vil feedforward-sektion have 3 memory-elementer,
% hhv. 1 til $x(n)$ (input) og 2 til $x(n-1)$ og $x(n-2)$ (delay-line).
% Feedback-sektionen skal ligeledes have 3 memory-elementer; 1 til $y(n)$
% (output) og 2 til $y(n-1)$ og $y(n-2)$ (delay-line).
% Det kr�ver 5 multiplikationer og 4 summationer at beregne et ouput.
% Hvis vi havde benyttet direkte form 2 (byttet om p� sektionerne) kunne vi
% n�jes med i alt 2 memory elementer til hele delay-line \cite[s. 159]{kuo2013}.
% </latex>
%%
% <latex>
% \section{Frekvensrespons}
% Frekvensresponset (amplitude- og faserespons) regnes for IIR notch-filteret.
% Frekvensreponset $H(e^{j \omega})$ regnes vha. ratioen p� to FFT'er
% \cite{dtftratios}.
% \\
% </latex>

Nfft = 2^16;
H = fft(b, Nfft) ./ fft(a, Nfft);
figure();
sgtitle('Designet notch-filter', 'Interpreter','Latex', 'FontSize', 14)
subplot(211)
plot( (fs/Nfft)*(0:Nfft-1), 20*log10(abs(H)));
xlim([600 1200]); ylim([-60 10]); grid on;
ylabel('Amplituderespons [dB]', 'Interpreter','Latex', 'FontSize', 12);
xline(round(round(fidx)),'r--');
subplot(212)
plot( (fs/Nfft)*(0:Nfft-1), (180/pi)*unwrap(angle(H)));
xlim([600 1200]); grid on;
xline(round(round(fidx)),'r--');
xlabel('f [Hz]', 'Interpreter','Latex', 'FontSize', 12);
ylabel('Fase [grader]', 'Interpreter','Latex', 'FontSize', 12);

%%
% <latex>
% Amplituderesponset viser, at filteret rammer den �nskede frekvens (r�d,
% lodret linje), og at gain i hele pasb�ndet er 0 dB.
% Filteret er dog \textbf{ikke} ideelt, da transitionen fra pas- til 
% stopb�nd ikke er undelig skarp/hurtig (roll-off ikke uendeligt stejl).
% Punkterne for \SI{-3}{dB} ligger ved hhv. \SI{800}{\hertz} og 
% \SI{950}{\hertz}. Dvs. ca. \SI{150}{\hertz} b�ndbredde i stopb�ndet.
% Filterets selektivitet (Q-faktor) er da ca. $\frac{876}{150}=6$.
% Det kan nok g�res bedre.
% \\�\\
% Faseresponset viser en kvalitet ved et IIR notch-filter: 
% Fasen er flad i det meste af pasb�ndet (dvs. group-delay er 0), 
% og i det meste af pasb�ndet vil der ikke opst� faseforvr�ngning. 
% N�rmere centerfrekvensen er fasen ikke-line�r, og der kan
% opst� faseforvr�ngning i omr�det ca. 700-\SI{800}{\hertz} og 
% igen ved ca. 950-\SI{1050}{\hertz}.
% Det er alts� en fordel at v�re mere selektiv i valg af frekvens; 
% forudsat at det kan h�ndteres med fixed-point p� target, 
% at frekvensen kendes p� forh�nd og at frekvensen er station�r.
% \\ \\
% Et IIR-filter af h�jere orden (kaskade) kunne ogs� give mening, og 
% det kunne designes ud fra yderligere krav til responset:
% Stejlhed (bandwidth el. Q-faktor), d�mpning i stopb�nd, 
% faserespons/group delay, osv.
% Vi arbejder med lyd her, og kunne nok bruge et filter med maksimalt
% line�r fase (Bessel). S� det kunne fx ogs� v�re et designkriterium.
% Design vha. et analogt prototypefilter og konvertering til digitalt 
% filter med den biline�re z-transformation ville give mening.
% \\�\\
% Det er �rgerligt, at der �ndres p� musiksignalet i de n�vnte 
% frekvensomr�der, da der netop er meget god lyd her - bas, percussion, osv.
% En bedre tilgang ville v�re et adaptivt filter, der helt specifikt kunne
% fjerne sinustonen.
% </latex>

%%
% <latex>
% \section{Test af filter i \MATLAB}
% Filteret testes p� lydklippet. For at p�vise, at der ikke l�ngere er
% en forstyrrende frekvens i signalet, beregnes igen et spektrogram, med
% samme indstillinger som tidligere.
% \\
% </latex>

xfilt = filter(b,a,x);               % filtr�r lydklippet
% soundsc(xfilt,fs)                  % lyt til klippet

tl = 5;                              % tidsl�ngde til analyse, sekunder
x_ = xfilt(1:tl*fs)';                % udvalgt sektion af filtreret signal
L = fs/5;                            % vinduesl�ngde 9600 => 5 Hz opl�sning
stepSize = L;                        % step er 1 vindue (0% overlap)
Nfft = 2^nextpow2(L);                % 2^14
figure();
spectrogram0(x_, L, Nfft, stepSize, fs, [0 5000]); % Vis kun op til 5 kHz

%%
% <latex>
% Spektrogrammet viser nu, at den rene tone er fjernet fra signalet. 
% Det samme er bekr�ftet ved at lytte til signalet.
% Spektrogrammet viser ogs� tydeligt, at en del information er mistet pga.
% d�mpning i frekvensomr�det omkring centerfrekvensen.
% Der ses et tydeligt ``d�dt'' omr�de omkring filterets centerfrekvens.
% Filteret virker alts� - i hvert fald med 64-bit-pr�cision - som �nsket.
% </latex>

%%
% <latex>
% \chapter{Opgave 3: Algoritmeudvikling og implementering p� signalprocessor}
% </latex>

%%
% <latex>
% \section{Kvantisering og algoritmeudvikling}
% Dette afsnit analyserer og tester kvantisering af filterkoefficienterne.
% Desuden testes algoritmen (floating-point $\longrightarrow$ fixed-point), 
% der implementeres p� target DSP'en.
% Der foretages test af algoritmer \textit{og} koefficienter sammen, 
% f�r der implementeres p� hardware.
% \\�\\
% Koefficientkvantisering �ndrer filterets karakteristik / respons. 
% S� der er risiko for et anderledes respons end hvad f�s med infinite
% precision:
% \sbul
% \item �ndrede koefficienter (afrunding) �ndrer filterets respons: 
% Kritiske frekvenser flyttes - muligvis signifikant.
% I yderste konsekvens bliver IIR-filteret ogs� ustabilt, hvis
% kvantisering (afrunding) flytter pol(er) uden for enhedscirklen \cite[s. 170]{kuo2013}.
% \item Kvantisering fra 64-bit \textit{floating-point} til 16-bit 
% \textit{fixed-point} finite precision giver l�bende 
% afrundings-/trunkeringsfejl i filtrering:
% Fordi det er et IIR-filter, s� feedes disse fejl tilbage ind filteret,
% og kan akkumulere. Det kan give oscillationer (limit cycles) \cite[s. 293]{lyons}.
% \item Filterorden og filterstruktur p�virker ovenst�ende risiko
% for ustabilitet for�rsaget af kvantisering \cite[s. 293]{lyons}:
% Det kan v�re en bedre strategi at implementere kaskadekobling af 
% 1./2.ordenssystemer, end at have et
% filter af h�jere orden \cite[s. 78]{kuo2013} \cite{directforms}.
% S� det er fornuftigt nok at arbejde med et 2. ordens filter her, og s�
% evt. kaskadere (og skalere), efter behov.
% \ebul
% Med \MATLAB s \texttt{fixed-point designer}, \texttt{filterDesigner} 
% og \texttt{fvtool} kan man analysere effekten af kvantisering af filteret.
% </latex>

%%
% <latex>
% \subsection{S15-kvantisering af filterkoefficienter}
% V�rdiomr�det for S15 er $1 \leq x < 1-2^{-15}$.
% Koefficienterne $b_1$ og $a_1$ er numerisk st�rre end $1-2^{-15}$ 
% men numerisk mindre end $2$. S� ved division med $2$ nedskaleres til S15.
% Der er umiddelbart to metoder til at h�ndtere dette i differensligningen:
% \sbul
% \item Nedskal�r \textit{kun} de to koefficienter med $2$, og ``opvej'' 
% skaleringen ved at indregne deres led dobbelt i differensligningen. 
% Dvs. $y(n) = \ldots + \frac{b_1}{2} x(n-1) + \frac{b_1}{2} x(n-1) + \ldots $.
% \item Nedskal�r \textit{alle} koefficiencter med faktor 2. Skaleringen
% opvejes i differensligningen ved at akkumulere dobbelt, dvs. afsluttende 
% MAC-operation er \texttt{akk += akk}.
% Da b�de $B(z)$ og $A(z)$ skaleres, �ndres frekvensresponset ikke.
% \ebul
% F�rstn�vnte v�lges, da det p�virker f�rrest koefficienter. Herunder
% vises princippet i S15-kvantiseringen. I det f�lgende repr�senterer $b_n$
% bits og \textit{ikke} filterkoefficienter!
% \\ \\
% I S15 \textit{forestiller} vi os, at der er et bin�rkomma $k=15$ pladser
% fra h�jre (LSB), og at MSB repr�senterer tallets fortegn.
% S15 bitm�nsteret med indsat bin�rkomma er
% $b_{0}.b_{1}b_{2}b_{3} \cdots b_{13}b_{14}b_{15}$.
% M�nsteret repr�senterer radix-10 kommatalsv�rdien
% $-b_{0} + \sum_{n=1}^{k=15} b_n 2^{-n}$.
% \\�\\
% S� for et tal $0 \leq u_1 < 1$ g�lder repr�sentationen
% $\sum_{n=1}^{k=15} b_n 2^{-n} \longleftrightarrow u_1$ som er �kvivalent
% til $b_1 2^{14} + b_2 2^{13} + \ldots + b_{15} \longleftrightarrow u_1
% 2^{15}$.
% Venstresiden er et heltal p� bin�r form (radix-2 med 15-bits).
% En evt. overskydende kommadel i $u_1 2^{15}$ p� h�jresiden trunkeres, 
% da der ikke er bits p� venstresiden til at repr�sentere den.
% \\�\\
% Derfor kan $u_1$ omregnes fra kommatal til S15 med
% \texttt{floor($u_1 2^{15}$)}. Tydeligvis f�s en numerisk mindre fejl, 
% hvis vi i stedet benytter \texttt{round($u_1 2^{15}$)}, antaget at evt.
% oprunding kan indeholdes i wordlength uden overflow\footnote{
% Det kr�ver mange flere operationer at tage \texttt{round} end
% at tage \texttt{floor}, s� mens det er OK til omregning af koefficienter
% i \MATLAB~, s� duer det slet ikke til l�bende MAC-beregninger p� DSP.}.
% Lagring af dette i signed heltalsbitm�nster lader vi compiler/\MATLAB~ 
% h�ndtere (det er 2-komplement).
% \\ \\
% Det negative tal $u_2 = -u_1$ repr�senteres ved
% $u_2 = -u_1 \longleftrightarrow$ \texttt{-round($u_1 2^{15}$)}
% $=$ \texttt{round($u_2 2^{15}$)}.
% For begge tal benyttes alts� en skaleringsfaktor $K=2^k=2^{15}$,
% som svarer til bitshift og cast \texttt{(short) (u1 <\/< 15)}.
% Ved lagring som bits h�ndteres fortegnsbit med to-komplement. 
% Den bin�re repr�sentation af $u_2$ kan fx\footnote{Alternativt 
% $2^{16}-1 - (u_1)_2 + 1$, hvilket er et-komplement og addering med 1.} 
% beregnes ved $(2^{16})_{2} - (u_1)_{2}$.
% Et negativt tal vil altid have $b_0=1$.
% \\ \\
% Regneeksempel: To tal, $u_1=0.9$ og $u_2=-0.9$, konverteres til S15
% og multipliceres som p� en 16-bit fixed-point platform.
% \\
% </latex>

u1 = 0.9; u2 = -u1;
B = 16;                 % B er l�ngden p� hele bin�r-ordet (word length)
k = 15;                 % k er l�ngden p� br�k-delen (fraction length)
K = 2^k;

U1 = round(u1*K);       % u1 -> S15
U2 = round(u2*K);       % u2 -> S15
disp( ['u1 -> S15: ' num2str(U1) newline ...
       'u2 -> S15: ' num2str(U2)] );
disp([newline 'To-komplementtallenes bits:']);
disp(['U1 bin -> ' num2str( bitget(int16(U1), 16:-1:1)' )' newline ...
      'U2 bin -> ' num2str( bitget(int16(U2), 16:-1:1)' )' ]);
  
%%
% <latex>
% Da skaleringsfaktoren ogs� multipliceres, kr�ves 32-bit for
% repr�sentere produktet $U_1 U_2=$ \texttt{round($u_1 u_2 2^{30}$)}.
% S15-formatet kan genetableres ved at dividere med skaleringsfaktoren, s�
% i S15: $u_1 u_2 = \texttt{round(} U_1 U_2 2^{-15} \texttt{)} $.
% Decimatallet genetableres ved yderlige nedskalering med $2^{15}$ uden 
% afrunding.
% \\
% </latex>

disp( ['Multiplikation af u1 og u2 i S15 -> ' num2str(round(U1*U2/K)) ] );
disp( ['Resultat i decimal -> ' num2str(round(U1*U2/K)/K) ] );

%%
% <latex>
% P� en fixed-point-platform caster man $u_1$ og $u_2$ til en bredere type,
% \texttt{U1U2 = (long) u1 * u2} og konverterer og trunkerer bagefter vha. 
% \texttt{(short) (U1U2 >\/> 15)}\footnote{Det giver selvf�lgelig en anden
% fordeling for afrundingsfejl end eksemplerne med \texttt{round} vist her.}.
% Dette kan emuleres:
% \\
% </latex>

U1U2_Q30 = int32(U1)*int32(U2);                          % (long) U1*U2

% Manipulation af bitm�nstrene:
U1U2_S15_bits = bitget(U1U2_Q30, 31:-1:16 );             % U1U2 >> 15
U1U2_S15 = sum( int16(U1U2_S15_bits) .* ...
                 int16([-1*2^15 2.^(14:-1:0)]) );        % (short) ...
u1u2 = sum( double(U1U2_S15_bits) .* [-1 2.^(-1:-1:-15)] ); % radix-10 dec.

disp( ['(U1*U2) bits     -> '  num2str(bitget(U1U2_Q30, 32:-1:1)' )' ]);
disp( ['(U1*U2) S15 bits  -> ' num2str(U1U2_S15_bits' )' newline ...
       '(U1*U2) i S15     -> ' num2str(U1U2_S15) newline ...
       '(u1*u2) i decimal -> ' num2str(u1u2) ] );

%%
% <latex>
% Hvilket demonstrerer, at det rigtige resultat ogs� frembringes ved
% direkte bitmanipulationer.
% \\
% </latex>
%%
% <latex>
% \subsection{Test af effekt af kvantisering i \MATLAB}
% For at se effekt af kvantisering, oprettes et diskret filterobjekt som 
% direkte form 1, med kvantiserede koefficienter (fixed-point).
% Denne fremgangsm�de er inspireret af \cite[s. 125 ff.]{kuo2013}.
% \\�
% </latex>

Hd = dfilt.df1(b,a);            % Ikke-kvantiseret filter
Hdq = copy(Hd);                 % Kopi�r objekt s� vi evt. kan sammenligne

% Kvantis�r filteret
Hdq.Arithmetic='fixed';         % Fixed-point-filter
Hdq.RoundMode='floor';          % Trunkering
Hdq.CoeffAutoScale = false;
Hdq.CoeffWordLength = 16;
Hdq.DenFracLength = 14;         % Kan ikke redueres til S15 pga v�rdiomr.
Hdq.NumFracLength = 14;
Hdq.ProductMode='SpecifyPrecision';
Hdq.ProductWordLength = 32;     % (long) b0*x(n) ind i akkumulator
Hdq.InputWordLength = 16;
Hdq.InputFracLength = 15;
Hdq.OutputWordLength = 16;
Hdq.OutputFracLength = 15;
Hdq.CastBeforeSum = true;

x_filt_q = filter(Hdq, x);      % Filtr�r med kvantiseret filter
x_filt_fp = double(x_filt_q);   % Konvert�r filtreret sign. til floating pt
% soundsc(x_filt_fp, fs);           % Afspil filtreret lydsignal - OK!
% freqz(Hdq, 'half');           % �bner FVtool og viser frekvensrespons,
                                % pol-/nulpunktsdiagram mv.

%%
% <latex>
% Ovenst�ende fors�g bekr�fter, at filteret ogs� virker, n�r det er
% kvantiseret (med trunkering).
% \texttt{FVtool} viser et pol-/nulpunktsdiagram (ikke
% illustreret her), som bekr�fter at polerne stadig ligger inden for
% enhedscirklen (stabilt).
% Der vises ogs� et frekvensrespons, som bekr�fter, at
% centerfrekvensen ikke er flyttet signifikant sfa. kvantisering.
% De oprindelige og kvantiserede koefficienter vises.
% \\
% </latex>

%%
% <latex>
% \subsection{Powerspektrum for kvantiseret filter}
% Sammenligning af powerspektra for kvantiseret filtrering og oprindeligt
% signal vises i figuren nedenfor. Tre observationer:
% \sbul
% \item Den rene tone er d�mpet omkring 40 dB 
% (ingen uendelig d�mpning med kvantiseret filter).
% Dog er en del af signalet omkring tonen ogs� blevet d�mpet i processen.
% \item Powerspektra matcher fint i pasb�ndet, s� kvantiseret filtrering 
% har ikke generelt ``�delagt'' signalet.
% \item N�r frekvensen n�rmes centerfrekvensen, �ndres signalet gradvist, 
% hvilket stemmer overens med de tidligere n�vnte frekvensomr�der.
% \ebul
% </latex>

x_post_ = x_filt_fp(1:tl*fs);         % Udv�lg 5s af filtreret signal 
Nfft = 2^nextpow2(length(x_post_));   % 2^18 -> zero-padding med 22144 0'er 
X_post_ = fft(x_post_, Nfft);
X_post_pow = X_post_ .* conj(X_post_);      % Powerspektrum
f_vec = (fs / Nfft) * (0:Nfft-1);           % Tilh�rende frekvensakse

figure();
plot(f_vec, 10*log10(X_pow)); hold on;
plot(f_vec, 10*log10(X_post_pow), 'r--'); hold off;
xlim([750 970]); grid on;
legend({'Pre filter', 'Post filter'});
ylabel('$|X(f)|^2$', 'Interpreter','Latex', 'FontSize', 12);
xlabel('Frekvens, $f$ [Hz]', 'Interpreter','Latex', 'FontSize', 12);
title('Powerspektrum for $x(t)$, $t=0 \ldots 5s $', ...
    'Interpreter', 'Latex', 'FontSize', 14)

%%
% <latex>
% Kvantiseringsfejlen (pga. pr�cision og trunkering) har et spektrum og 
% en sandsynlighedsfordeling.
% Men her antages bare, at denne fejl er j�vnt fordelt hvidst�j med 
% middelv�rdi p� 0, og at der ikke skal foretages yderligere.
% </latex>

%%
% <latex>
% \subsection{Output af \MATLAB -kvantiserede filterkoefficienter}
% Det indebyggede \texttt{filterDesigner}-v�rkt�j kan eksportere 
% filterkoefficienterne til en C-header:
% \sbul
% \item \texttt{File > Import filter from Workspace > Filter object > Hdq}.
% \item \texttt{Targets > Generate C Header > Export as > Signed 16-bit integer > Export}.
% \ebul
% Da koefficienterne ligger i intervallet $-2 \leq x < 2-2^{-14}$, vil 
% \texttt{filterDesigner} eksportere som Q2.14, dvs. med kun 14 fractional 
% bits.
% \\�\\
% Bem�rk ogs� fortegn p� $a_1$ og $a_2$ (DEN[1] og DEN[2]).
% Fortegnene er som i polynomiet $A(z)$, dvs. omvendt af
% hvad der bruges i differensligningen, som jeg har opskrevet den.
% \\�\\
% For koefficienterne i v�rdiomr�det for S15, dvs. $b_0$, $b_2$ og $a_2$, 
% vil et venstre bitshift (<\/< 1) konvertere fra Q2.14 til S15.
% For koefficienter uden for v�rdiomr�de (dvs. $b_1$ og $a_1$), kan
% koefficienterne benyttes direkte jf. diskussionen omkring skalering med 2
% og efterf�lgende dobbelt-addition.
% Koefficienter modsvarende  \MATLAB s benyttes i implementeringen.
% \\
% </latex>

%%
% <latex>
% \begin{lstlisting}[style={C++}, caption={Eksporterede filterkoeff.}]
% /* General type conversion for MATLAB generated C-code  */
% #include "tmwtypes.h"
% /* 
%  * Expected path to tmwtypes.h 
%  * /Applications/MATLAB_R2018b.app/extern/include/tmwtypes.h 
%  */
% const int NL = 3;
% const int16_T NUM[3] = {
%     16345, -32475,  16345
% };
% const int DL = 3;
% const int16_T DEN[3] = {
%     16384, -32227,  16058
% };
% \end{lstlisting}
% </latex>

%%
% <latex>
% \section{Algoritmetest: Floating-point implementering af IIR-differensligning i \MATLAB}
% Forud for en testalogritme med fixed-point, laves en 
% reference med floating-point.
% Der benyttes en line�r buffer. Det giver et par f� ekstra operationer.
% Det giver ikke mening at implementere en cirkul�r buffer i \MATLAB~ da
% der ikke findes pointers, og delay lines kun best�r af 2 elementer hver.
% \\
% </latex>

delay_x = [0 0];    % delay line til feedforward
delay_y = [0 0];    % delay line til feedback

N = length(x);
y = zeros(1,N);

% impulsrespons
delta = [1 zeros(1, N-1)];

%in = x;            % Beregn filtrering af lydsignal
in = delta;         % Beregn impulsrespons

for n = 1:N
    % Implement�r differensligning:
    y(n) = b0*in(n) + b1*delay_x(1) + b2*delay_x(2) + ...
            a1*delay_y(1) + a2*delay_y(2);
    
    % Opdat�r delay line ved at shifte nyeste v�rdi ind
    delay_x = [in(n) delay_x(1)];
    delay_y = [y(n) delay_y(1)];
end

%%
% <latex>
% Ved aflytning af det filtrerede signal bekr�ftes det, at algoritmen har
% virket som �nsket. Der er ogs� k�rt en impuls igennem filteret, 
% og impulsresponset er tranformeret til frekvensrespons herunder.
% \\
% </latex>

% soundsc(y, fs)
% clear sound

f_vec = (0:N-1)*(fs/N);
figure();
plot(f_vec, 20*log10(abs(fft(y))));
grid on; xlim([750 1000]); ylim([-290 10]);
xlabel('f [Hz]', 'Interpreter','Latex', 'FontSize', 12);
ylabel('$|X(f)|^2$ [dB]', 'Interpreter','Latex', 'FontSize', 12);
title('Frekvensrespons (floating-point)', 'Interpreter','Latex', 'FontSize', 14);

%%
% <latex>
% \section{Algoritmeudvikling: Fixed-point implementering af IIR-differensligning i \MATLAB}
% Ud fra floating-point-algoritmen udarbejdes her en
% fixed-point-algoritme, som emulerer DSP'ens MAC.
% Form�let er at forst� og analysere forskellene til floating-point, og at
% forberede implementering p� target DSP'en.
% Der benyttes S15-kvantiserede koefficienter og input (16-bit pr�cision).
% ``Akkumulatoren'' i \MATLAB~ er 64-bit, mens DSP'ens egen 32/40-bit 
% akkumulator har 8 guard-bits, og kan h�ndtere 256 32-bit additioner uden 
% overflow. S� overflow-aspektet beh�ver vi ikke at simulere her.
% \\
% </latex>

K = 2^15;                   % Benyttes til <<15 og >>15 operationer

% Koefficienter i S15
b0_ = round(b0 * K);        % Svarer til (short) (b0 << 15)
b1_ = round(b1/2 * K);      % Bem. b1/2, s� skal akkumuleres dobbelt
b2_ = round(b2 * K);
a1_ = round(a1/2 * K);      % Bem. a1/2, s� skal akkumuleres dobbelt
a2_ = round(a2 * K);

% Kvantis�r input. Dette skal ikke g�res i C.
% F�rst skaleres til v�rdiomr�de for S15
% -> der er meget f� elementer |x|>1 , disse clippes i stedet for at
% re-skalere hele serien.
x_ = x;
x_(x_ >= 1) = 1-2^-15;      % Clippes til max-v�rdi for S15
x_(x_ < -1) = -1;           % Clippes til min-v�rdi for S15
x_ = round(x_*K);           % Kvantisering

N = length(x_);
y = zeros(1, N);

dx = [0 0];                 % Nulstil delay lines
dy = [0 0];

for n=1:N
    % Implement�r differensligning med MAC-operationer
    acc = b0_*x_(n);
    acc = acc + b1_*dx(1);
    acc = acc + b1_*dx(1);  % Adderer 2 gange fordi koefficient er b1/2
    acc = acc + b2_*dx(2);
    acc = acc + a1_*dy(1);
    acc = acc + a1_*dy(1);  % Adderer 2 gange fordi koefficient er a1/2
    acc = acc + a2_*dy(2);
                   
    y(n) = round(acc/K);    % (short) (acc >>15),  Q2.30 -> Q1.15 (S15)
    
    % Opdat�r delay line til n�ste iteration ved at shifte nyeste v�rdi ind
    dx = [x_(n) dx(1)];     % Bliver [x(n-1) x(n-2)]
    dy = [y(n) dy(1)];      % Bliver [y(n-1) y(n-2)]
    
end

y = y/K;                    % Omregn y tilbage til v�rdiomr�det [-1;1[

%%
% <latex>
% Afspilning af nummeret efter filtrering bekr�fter, at den forstyrrende
% tone er fjernet. Filteret virker alts� ogs� med fixed-point aritmetik.
% Det er oplagt at sammenligne tids- og frekvensserier hhv. f�r og efter
% filtrering, for at se filterets indvirkning.
% \\
% </latex>

% soundsc(y, fs)
% clear sound

%%
%
Tmax = 10;      % sek
n = (1:Tmax*fs);
t_vec = (n-1)/fs;
f_vec = (0:Tmax*fs-1)*(fs/(Tmax*fs));

figure();
setlatexstuff('latex');
sgtitle('Pre- og post filtrering', 'Interpreter','Latex', 'FontSize', 14)

subplot(211)
plot(t_vec, x(n) / max(abs(x(n))));
hold on;
plot(t_vec, y(n) / max(abs(y(n))), 'r--');
hold off;
grid on;
xlabel('t [s]', 'Interpreter','Latex', 'FontSize', 12);
ylabel('Amplitude', 'Interpreter','Latex', 'FontSize', 12);
title('Tidsserier 0..10s', 'Interpreter','Latex', 'FontSize', 12);

subplot(212)
plot(f_vec, 20*log10(abs(fft(x(n) / max(abs(x(n)))))));
hold on;
plot(f_vec, 20*log10(abs(fft(y(n) / max(abs(y(n)))))), 'r--');
hold off;
grid on;
xlim([750 1000]);
ax = gca; ax.XAxis.Exponent = 0;
xlabel('f [Hz]', 'Interpreter','Latex', 'FontSize', 12);
ylabel('$|X(f)|^2$ [dB]', 'Interpreter','Latex', 'FontSize', 12);
title('Powerspektra 0..10s', 'Interpreter','Latex', 'FontSize', 12);

%%
% <latex>
% �verste figur over tidsdom�net viser, at bortfiltrering af tonen har 
% taget energi (amplitude) ud af signalet.
% Det er mest markant i starten af sk�ringen, 
% hvor der kun er sinustonen og ingen musik.
% For den filtrerede tidsserie ses i �vrigt en indsvingning af filteret.
% \\�\\
% I effektspektra (kun vist i intervallet 750-\SI{1000}{\hertz}, ses, at
% filtreringen har d�mpet den rene \SI{876}{\hertz}-tone med ca. \SI{40}{dB}.
% Kun i den n�re omegn af notchet (notch b�ndbredde), er frekvensindholdet
% blevet �ndret af filteret. Det er sv�rt at h�re, at ``der mangler
% noget'' i forhold til originaloptagelsen.
% \\�\\
% Ovenst�ende analyse giver noget vished om, at algoritme og koefficienter
% svarende til ovenst�ende burde virke p� signalprocessoren.
% N�ste skridt er implementering p� hardware.
% </latex>

%%
% <latex>
% \section{Ops�tning af projekt i CCS}
% Som udgangspunkt for kodeprojektet er opskriften ``Audio Loop Through''
% benyttet \cite{kplezdsp}.
% Da jeg i dette projekt driver input med wavegenerator, og ikke en
% mikrofon, er gain i ADC/DSP reduceret til \SI{0}{dB}.
% Samplingsfrekvens er fastholdt p� \SI{48}{\kilo\hertz} da filteret er
% designet dertil, og der intet behov er for at �ndre derp�. Ops�tning
% i \texttt{main.c} ses herunder:
% \\
% </latex>

%%
% <latex>
% \begin{lstlisting}[style={C++}, caption={Ops�tning i main.c}]
% printf("E4DSA Case 2 (Janus) - IIR notch filter DSP: ");
% %\newline%
% /* Setup sampling frequency and 0 dB gain for line in */
% set_sampling_frequency_and_gain(SAMPLES_PER_SECOND, 0);
% \end{lstlisting}
% </latex>

%%
% <latex>
% Desuden er bias af mikrofon sl�et fra (til fx mikrofoner i headset, 
% som skal have bias for at virke). Denne registerindstilling er n�vnt i
% \cite{porting}.
% \\
% \begin{lstlisting}[style={C++}, caption={aic3205\_init.c}]
% AIC3204_rset( 0, 1 );      // Select page 1
% //AIC3204_rset( 51, 0x48); // power up MICBIAS with AVDD (0x40) or LDOIN (0x48)
% \end{lstlisting}
% </latex>

%%
% <latex>
% \section{Implementering af differensligning i C}
% Implementering af filteret er i to filer, \texttt{iir\_notch.h} 
% og \texttt{iir\_notch.c}. I header-filen findes koefficienter og prototype
% p� funktion. I c-filen findes implementeringen. I \texttt{main.c} er
% der implementeret et uendeligt loop, der tager input fra ADC (line-in),
% kalder filterfunktion og sender resultat ud af DAC (line-out).
% Som det ses, benyttes kun h�jre kanal, for at kunne benytte den venstre 
% kanal til en anden filtrering eller til det ufiltrerede output i 
% forbindelse med tests.
% \\
% \begin{lstlisting}[style={C++}, caption={Uendelig l�kke i main.c}]
% while (1) {
%   aic3204_codec_read(&left_input, &right_input);
%   right_output = filter_iir_notch(iir_b, iir_a, right_input);
%   left_output =  0;
%   aic3204_codec_write(left_output, right_output);
% }
% \end{lstlisting}
% </latex>

%%
% <latex>
% Header-filen indeholder koefficienterne beregnet i designafsnittet.
% Som kan ses i koden, er der eksperimenteret med forskellige s�t
% koefficienter, der repr�senterer forskellige Q-faktor,
% for at se og h�re forskel p� filterets funktion og respons.
% \\
% \begin{lstlisting}[style={C++}, caption={iir\_notch.h}]
% /*
%  * iir_notch.h
%  *
%  *  Created on: 10 Mar 2020
%  *      Author: Janus Bo Andersen (JA67494)
%  *      Interface for the IIR filter function
%  *      Defines the filter coefficients for a 876 Hz notch filter
%  */
% %\newline%
% #ifndef IIR_NOTCH_H_
% #define IIR_NOTCH_H_
% %\newline%
%     /*                           b0     b1 / 2   b2 */
%  /* const signed int iir_b[3] = {32738, -32523, 32738}; */
%     const signed int iir_b[3] = {32690, -32475, 32690};
% %\newline%
%     /*                           a0     a1 / 2   a2 */
%  /* const signed int iir_a[3] = {32767,  32520, -32702}; */
%     const signed int iir_a[3] = {32767,  32227, -32116};
% %\newline%
%     /* The filter takes b and a coefficients, and input from line-in */
%     signed int filter_iir_notch(const signed int * b, 
%                                 const signed int * a, signed int input);
% %\newline%
% #endif /* IIR_NOTCH_H_ */
% \end{lstlisting}
% </latex>

%%
% <latex>
% Implementering af filterfunktionen er inspireret af 
% \cite[kap. 7, slide 39]{rom} og \cite[s. 181]{kuo2013}.
% Som kan ses, er delay lines implementeret som
% line�re buffers (s� f� koefficienter, at det er en ligegyldig
% optimering at bruge en cirkul�r buffer her).
% Filteret er i direkte form 1, 
% s� der er delay lines for b�de $x(n)$ og $y(n)$.
% Bem�rk ogs�, at MAC-operation for $b_1$ og $a_1$ forekommer dobbelt, da
% disse to koefficienter er halveret for at passe ind i S15-formatet.
% Algoritme og casts/shifts er som udviklet i et tidligere afsnit.
% \\
% \begin{lstlisting}[style={C++}, caption={iir\_notch.c}]
% # define NATIVE_MAX 32767   /*  2^15 - 1 */
% # define NATIVE_MIN -32768  /* -2^15     */
% %\newline%
% /* The filter takes b and a coefficients, and input from line-in */
% signed int filter_iir_notch(const signed int * b, 
%                             const signed int * a, signed int input) {
% %\newline%
%     /* Delay line as static variables with persistence between calls */
%     static signed int dx[2] = {0, 0};    /* x(n-1), x(n-2) */
%     static signed int dy[2] = {0, 0};    /* y(n-1), y(n-2) */
% %\newline%
%     /* Accumulator 32-bit (8 guard bits for overflow) */
%     long acc = 0;
% %\newline%
%     /* difference equation, coerce all data into
%      * sign extended 32-bit words during calculation */
%     acc =  ( (long) b[0] * input );     /* b0 x(n)*/
%     acc += ( (long) b[1] * dx[0] );     /* b1 x(n-1) */
%     acc += ( (long) b[1] * dx[0] );     /* added twice due to scaling */
%     acc += ( (long) b[2] * dx[1] );     /* b2 x(n-2) */
%     acc += ( (long) a[1] * dy[0] );     /* a1 y(n-1) */
%     acc += ( (long) a[1] * dy[0] );     /* added twice due to scaling */
%     acc += ( (long) a[2] * dy[1] );     /* a2 y(n-2) */
% %\newline%
%     /* coerce back into 16-bit word size */
%     acc >>= 15;
% %\newline%
%     /* check for overflow and use saturation logic */
%     if (acc > NATIVE_MAX) {
%         acc = NATIVE_MAX;   /* Saturate instead of overflow */
%     } else if (acc < NATIVE_MIN) {
%         acc = NATIVE_MIN;   /* Saturate instead of underflow */
%     }
% %\newline%
%     /* Update delay line */
%     dx[1] = dx[0]; /* x(n-2) = x(n-1) */
%     dx[0] = input; /* x(n-1) = x(n) */
%     dy[1] = dy[0]; /* y(n-2) = y(n-1) */
%     dy[0] = (short) acc; /* y(n-1) = y(n) */
% %\newline%
%     /* Return value */
%     return (short) acc;
% }
% \end{lstlisting}
% </latex>

%%
% <latex>
% \chapter{Opgave 4: Test p� target}
% Nedenst�ende opstilling er benyttet til test p� target DSP-hardware.
% Analog Discovery's signalgenerator (AWG) er sluttet til
% line-in. Line-out er forbundet til oscilloskop.
% Hvide stik er AWG1 og scope CH1, som b�rer h�jre lydkanal.
% Forsyning til eZDSP-kittet er med p�sat ferrit for at d�mpe evt. 
% h�jfrekvent st�j fra bl.a. computerens str�mforsyning.
% \begin{figure}[H]
% \centering
% \includegraphics[width=10cm]{../img/testopstilling2.jpg}
% \caption{Testopstilling\label{fig:testopstilling}}
% \end{figure}
% AWG benyttes til at afspille musiksignalet eller lave sweeps. 
% Spektrumanalysator kan analysere frekvensindhold i output fra target.
% Netv�rksanalysator kan bruges til at lave en frekvenskarakteristik.
% \\�\\
% Line level for ``consumer''-udstyr er \SI{-10}{dBV} dvs. 316 mV
% RMS\footnote{
%  \SI{0}{dBV} er \SI{1}{\volt} RMS.
%  \SI{-10}{dBV} svarer til et sinussignal med peak-amplitude 0.447 VPK.
% }\cite{nominallevels}.
% Mic-level er typisk meget lavere, fx \SI{-40}{dBV}.
% For at undg� clipping (eller at br�nde ADC'en i line-in af), 
% holdes amplituden fra AWG p� maks. 50 mV (\SI{-29}{dBV})\footnote{
%  Peak-amplitude p� 50 mV svarer cirka til 35 mV RMS, som er \SI{-29}{dBV}.
% }.
% \\�\\
% </latex>

%%
% <latex>
% \section{Test 1: Musik med sinustone og frekvenssweep}
% Det filtrerede musiksignal er aflyttet med en h�jttaler for at bekr�fte,
% at lydkvaliteten stadig er som forventet, og at sinustonen er d�mpet.
% Fors�get kan ses/h�res her: \url{https://youtu.be/urbXrjlm0hs}.
% \\ \\
% Et sweep fra 700-\SI{1050}{\hertz} er ogs� blevet fors�gt.
% Det auditive indtryk er, som forventet, at frekvenserne t�t omkring centerfrekvensen d�mpes.
% Fors�get kan ses/h�res her: \url{https://youtu.be/BOKc1OGQojs}.
% \\ \\
% Baseret p� test 1 konkluderes, at filteret virker.
% </latex>


%%
% <latex>
% \section{Test 2: Musiksignal og spektrumanalysator}
% Musiksignalet afspilles igen fra AWG1 (50 mV peak-amplitude). 
% Spektrumanalysatoren benyttes til m�le og sammenligne frekvensindhold i 
% hhv. et filtreret og et ikke-filtreret outputsignal for
% frekvensomr�det 700-\SI{1000}{\hertz}.
% CH1 (orange) er filtreret og CH2 (bl�) er ikke-filtreret.
% \begin{figure}[H]
% \centering
% \includegraphics[width=16cm]{../img/spektrumanalysator2.png}
% \caption{Sammenligning af filtreret og ikke-filtreret output
% \label{fig:spektrumanalysator}}
% \end{figure}
% Figuren viser, at det ikke-filtrerede signal har en ren tone
% omring \SI{876}{\hertz}, og at tonen er d�mpet i det filtrerede
% signal. Som forventet :-) De to spektra er ikke sammenfaldende, bl.a.
% fordi det filtrerede signal er forsinket gennem filteret.
% Det ses ogs�, at niveauet for den rene tone ligger lidt under det
% beregnede maksniveau: \SI{-34}{dBV} ift. \SI{-29}{dBV} beregnet.
% </latex>

%%
% <latex>
% \section{Test 3: Frekvenskarakteristik}
% Frekvenskarakteristikken optages med Waveforms' netv�rksanalysator.
% Igen unders�ges frekvensomr�det 700-\SI{1000}{\hertz}.
% Der optages 2000 samples over frekvensomr�det, og
% AWG er sat op til at k�re 64 perioder for hver frekvens i sweep'et.
% \\�\\
% Figuren nedenfor viser en karakteristik, der som forventet ligner spektra
% beregnet i \MATLAB .
% Den maksimale d�mpning i notchet er p� ca. \SI{-60}{dB}, hvilket er
% h�jere end de ca. \SI{-40}{dB} d�mpning af sinustonen, der blev
% observeret i \MATLAB .
% Forklaringen er nok, at kvantisering har flyttet filterets
% centerfrekvens en lille smule, s� sinustonens \SI{876}{\hertz} ikke 
% bliver ``ramt'' med den fulde d�mpning.
% \begin{figure}[H]
% \centering
% \includegraphics[width=16cm]{../img/netvaerksanalysator.png}
% \caption{Frekvenskarakteristik
% \label{fig:netvaerksanalysator}}
% \end{figure}
% Selvom gain i hardware er sat til \SI{0}{dB} (for ADC'en), sker der en
% forst�rkning, som er urelateret til selve filteret, hvilket kan bekr�ftes
% ved niveau for det ikke-filtrerede (bl�) signal.
% H�jst sandsynligt sker forst�rkningen i DAC'en. 
% Jeg har ikke (endnu) fors�gt at sl� dette gain fra.
% \\�\\
% Baseret p� frekvenskarakteristikken konkluderes, at filteret virker, men
% at der kunne g�res mere for at ``tune'' det kvantiserede filter til den
% �nskede centerfrekvens.
% </latex>


%%
% <latex>
% \chapter{Opgave 5: Fri leg}
% Denne opgave blev der desv�rre ikke tid til denne gang :-(
% </latex>

%%
% <latex>
% \chapter{Forbedringsmuligheder}
% \sbul
% \item ``Tuning'' af det kvantiserede filter til mere pr�cist at ramme den
% �nskede centerfrekvens.
% \item ``Optimering'' af det kvantiserede filter til at v�re
% skarpere/stejlere.
% \item Lave en kaskade af 2. ordensfiltre til at f� et mere selektivt filter
% (smallere stop-b�ndbredde og h�jere d�mpning i centerfrekvensen).
% \item Benytte et adaptivt filter til \textit{kun} at fjerne sinustonen
% uden at d�mpe nogen omkringliggende frekvenser.
% \ebul
% </latex>

%%
% <latex>
% \chapter{Konklusion}
% I denne case er der designet og implementeret et 2. ordens IIR
% notch-filter i \MATLAB . Algoritmer og koefficienter er ogs� udarbejdet
% til implementering af filteret p� DSP-hardware. 
% Hardwareimplementeringen er testet med tre forskellige metoder, og
% det er verificeret, at filteret virker p� target, som �nsket.
% En r�kke forbedringsmuligheder er n�vnt til at f� et filter med endnu
% bedre performance.
% \\�\\
% Det har v�ret en interessant case - is�r fordi en r�kke hensyn skulle
% tages til ikke-ideelle forhold under implementering p� DSP-hardware.
% Bl.a. kvantisering til 16-bit, men ogs� andre hardware-faktorer.
% </latex>

%%
% <latex>
% \cleardoublepage
% \chapter{Kildehenvisning}
% \printbibliography[heading=none]
% </latex>

%%
%
xyzblabla = randn(1000); % Til at vente p� graferne...
%% 
% <latex>
% \newpage
% \chapter{Hj�lpefunktioner\label{sec:hjfkt}}
% Der er til projektet implementeret en r�kke hj�lpefunktioner.
% </latex>

%% setlatexstuff
%
function [] = setlatexstuff(intpr)
% S�t indstillinger til LaTeX layout p� figurer: 'Latex' eller 'none'
% Janus Bo Andersen, 2019
    set(groot, 'defaultAxesTickLabelInterpreter',intpr);
    set(groot, 'defaultLegendInterpreter',intpr);
    set(groot, 'defaultTextInterpreter',intpr);
end

%% spectrogram0
% Implementeret af Kristian Lomholdt, E4DSA.
% Let modificeret, Janus, feb. 2020.
% Baseret p� Manolakis m.fl., s. 416.
function S=spectrogram0(x,L,Nfft,step,fs,ylims)
% Spektrogram. Beregner og viser spektrogram
% Baseret p�: Manolakis & Ingle, Applied Digital Signal Processing, 
%             Cambridge University Press 2011, Figure 7.34 p. 416
% Parametre:  x:    inputsignal
%             L:    vinduesbredde ("segmentl�ngde")
%             Nfft: DFT st�rrelse. Der zeropaddes hvis Nfft>L
%             step: stepst�rrelse
%             fs:   samplingsfrekvens
% Forlkaring:
% x  |-------------------------------------------------------------------|
%    |----------|                                                       N-1
%              L-1
%          |----------|
%        step
%
% KPL 2019-01-30

% transpose if row vector
    if isrow(x); x = x'; end

    N = length(x);
    K = fix((N-L+step)/step);
    w = hanning(L);
    time = (1:L)';
    Ts = 1/fs;
    N2 = Nfft/2+1;
    S = zeros(K,N2);
    for k=1:K
        xw = x(time).*w;
        X  = fft(xw,Nfft);
        X1 = X(1:N2)';
        S(k,1:N2) = X1.*conj(X1); % samme som |X1|^2 - effektspektrum
        time = time+step;
    end
    S = fliplr(S)';
    S = S/max(max(S)); % normalisering
    
    
    
    tk = (0:K-1)'*step*Ts;
    F = (0:Nfft/2)'*fs/Nfft;
    
    colormap(jet);     % farveskema, pr�v ogs� jet, summer, gray, ...
    imagesc(tk,flipud(F),20*log10(S),[-100 10]);
    
    axis xy
    ylabel('$f$ [Hz]', 'Interpreter','Latex', 'FontSize', 12);
    ylim(ylims);
    
    xlabel('$t$ [s]', 'Interpreter','Latex', 'FontSize', 12);  
    
    title(['Spektrogram', newline, ...
            '$N_{FFT}=$' num2str(Nfft) ... 
            ', $L=$' num2str(L) ...
            ', step=' num2str(step) ...
            ', $f_s=$' num2str(fs)], ...
            'Interpreter', 'Latex', 'FontSize', 14)
end

%% smoothMag
% KPL E3DSB
function Y = smoothMag(X,M)
% Smoothing of signal. Eg. frequency magnitude spectrum. 
% X must be a row vector, and M must be odd.
% KPL 2016-09-19
    N=length(X);
    K=(M-1)/2;
    Xz=[zeros(1,K) X zeros(1,K)];
    Yz=zeros(1,2*K+N);
    for n=1+K:N+K
        Yz(n)=mean(Xz(n-K:n+K));
    end
    Y=Yz(K+1:N+K);
end
