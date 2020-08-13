%% E4DSA Case 2 - IIR notch-filter og real-time-implementering på TMS320C5535
%%
% <latex>
% \chapter{Indledning}
% Anden case i E4DSA er design og real-time-implementering af et IIR
% notch-filter på DSP-hardware.
% Filteret er designet og testet i \MATLAB . \MATLAB~er også brugt til at 
% kvantisere koefficienter og teste fixed-point filter-algoritmen. 
% Filteret er implementeret på DSP-hardware vha. Code Composer Studio
% (CCS). Target er TMS320C5535 (eZDSP kit).
% \MATLAB~og C-kode er gengivet med forskellige baggrundsfarver for lette
% genkendelighed i denne journal.
% \\ \\
% Beklager, at journalerne bliver lange; men det er også for at
% kunne have detaljerne til fremtiden.
% </latex>

%%
% <latex>
% \chapter{Opgave 1: Analyse af inputsignal}
% Inputsignalet er ``Bright Side of the Road'' af Van Morrison
% fra albummet ``Into the Music'' (1979).
% Signalet indeholder de første \SI{60}{\second} af nummeret.
% Signalet er i mono, 32-bit floating point, og samplingsfrekvensen er 
% \SI{48}{\kilo\hertz} (professionel standard).
% Nummeret er blevet saboteret med en ren sinustone, 
% der er ekstremt ubehagelig at lytte til i mere end et par sekunder.
% Så den skal fjernes.
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
% De første \SI{5}{\second} vises her, men 
% sinustonen er stationær i hele signalets længde.
% Hver FFT er zero-padded\footnote{Det giver pænere spektrum, ``sampler'' DTFT'en på flere punkter}.
% Vindueslængden på $L=\frac{f_s}{5}=9600$ samples giver et ok
% trade-off mellem frekvensopløsning og tidsopløsning.
% $\Delta f = \frac{f_s}{L} = 5.0$ Hz og tidsopløsning $T_{STFT} = \frac{L}{f_s} = 0.20$ sek.
% Steppet er sat, så der ikke er overlap på vinduer.
% Der laves 25 FFT'er\footnote{Der analyseres \SI{5}{\second} signal med \SI{5}{STFT\per\second}, så i alt 25 FFT'er beregnes}.
% \\
% </latex>

tl = 5;                              % tidslængde til analyse, sekunder
x_ = x(1:tl*fs)';                    % udvalgt sektion af signal
L = fs/5;                            % vindueslængde 9600 => 5 Hz opløsning
stepSize = L;                        % step er 1 vindue (0% overlap)
Nfft = 2^nextpow2(L);                % 2^14
figure();
spectrogram0(x_, L, Nfft, stepSize, fs, [0 5000]); % Vis kun op til 5 kHz

%%
% <latex>
% Spektrogrammet viser ved den røde vandrette streg en stationær ren tone 
% omkring \SI{875}{\hertz}.
% \\ \\
% Pga. lav grafikopløsning i figuren ser det også ud som om, at der er en 
% ren tone ved en lavere frekvens (100 Hz?).
% Hvis der zoomes ind, ses det dog, at denne hverken er stationær eller er 
% til stede konstant.
% \\ \\
% En enkelt FFT med 240000 samples benyttes for at pinpointe den eksakte 
% frekvens for den forstyrrende tone.
% Det giver en frekvensopløsning på $\Delta f = 0.2$ Hz.
% Der zero-paddes igen.
% Figuren nedenfor viser, at den forstyrrende tone er lokaliseret 
% ved $876 \pm$\SI{0.2}{\hertz}.
% \\
% </latex>

Nfft = 2^nextpow2(length(x_));      % 2^18 -> zero-padding med 22144 0'er 
X_ = fft(x_, Nfft);
X_pow = X_ .* conj(X_);             % Powerspektrum
f_vec = (fs / Nfft) * (0:Nfft-1);   % Tilhørende frekvensakse
[val, idx] = max(10*log10(X_pow));  % Find frekvenssample med højeste power
fidx = f_vec(idx);                  % Tilhørende frekvensbin

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
% Der optræder ingen harmoniske af de \SI{876}{\hertz} (det kunne jo sagtens have været tilfældet).
% Det kan ikke ses her, men det er undersøgt.
% Vi slipper derfor for at implementere noget mere avanceret, som fx et comb-filter. 
% Planen er nu at designe et notch-filter\footnote{Narrow-band båndstop}, der dæmper/filtrerer
% præcis frekvensen \SI{876}{\hertz} bort.
% </latex>
%%
% <latex>
% \chapter{Opgave 2: Filterdesign}
% Filteret skal være 2. orden af typen IIR, og skal designes vha. placering
% af poler og nulpunkter. Det kan man gøre manuelt for en lav filterorden.
% Vi kender allerede centerfrekvensen, som kan omregnes til vinklen for de
% kompleks-konjugerede nulpunkter (og tilhørende poler).
% \\
% </latex>

%%
% <latex>
% \section{Pol-nulpunktsplacering i et digitalt notch-filter}
% Et 2. ordens digitalt notch-filter har to ``pol-nulpunktspar''.
% Pol og nulpunkt i et par placeres på en radial, altså med samme vinkel, 
% hvilken netop afgør filterets centerfrekvens. 
% Et pol-nulpunktspar har et kompleks-konjugeret pol-nulpunktspar.
% Dvs. filteret alt-i-alt har to poler og to nulpunkter.
% Pol og nulpunkt skal ligge \textit{tæt} på hinanden.
% Nulpunktet kan ligge på enhedscirklen, 
% og modulus for polen skal være mindre end modulus for nulpunktet.
% Polerne skal ligge inden for enhedscirklen for at sikre stabilitet.
% \\ \\
% Ideen er, at ved evaluering af frekvensrespons $H(e^{j \omega})$ 
% rundt på enhedscirklen, vil pol og nulpunkt i et par ophæve hinanden 
% set for frekvenser relativt langt væk fra centerfrekvensen (fordi parret ligger tæt).
% For frekvenser tæt på centerfrekvensen vil nulpunktet blive 
% dominerende, fordi det ligger relativt tættere på enhedscirklen end polen.
% Nulpunktet giver netop dæmpningen i centerfrekvensen.
% \\ \\
% Så længe pol og nulpunkt ikke ligger oveni hinanden, vil det være sådan,
% at jo tættere de er på hinanden, jo skarpere bliver notchet.
% \MATLAB s \texttt{filterDesigner} kan bruges til analysen.
% \\ \\
% Der er en grænse for hvor skarpt/stejlt et filter, der
% kan implementeres på fixed-point. 
% Det er grundet den finitte præcision i kvantisering af koefficienter samt
% i beregninger.
% Modulus for polerne i filteret, der udvikles nedenfor, er fundet
% iterativt i et trade-off mellem at have et skarpt notch og at have et
% filter, som performer godt på target fixed-point platformen.
% </latex>

%%
% <latex>
% \section{Ligninger for et digitalt notch-filter}
% Centerfrekvensen for notch-filteret er $\omega_c$ [rad/s] med
% $\omega_c=\pi \frac{f_c}{f_s / 2}$.
% Modulus for nulpunkterne vælges til 1, og for polerne $r<1$.
% Da pol-nulpunktsparrene er komplekst konjugerede, fås følgende nulpunkter og poler:
% $z_0=e^{j\omega_c}$, 
% $z_1=e^{-j\omega_c}$, 
% $p_0=r e^{j\omega_c}$ og
% $p_1=r e^{-j\omega_c}$.
% Filterets overføringsfunktion findes i den faktoriserede form \cite[6-38 s. 285]{lyons}:
% \begin{equation}
%  H(z) = \frac{(z-z_0)(z-z_1)}{(z-p_0)(z-p_1)} 
%  = \frac{(z-e^{j\omega_c})(z-e^{-j\omega_c})}{(z-r e^{j\omega_c})(z-r e^{-j\omega_c})}
% \end{equation}
% Ganges paranteserne ud og benyttes Eulers relation
% $2\cos(\omega)=e^{j\omega}+e^{-j\omega}$, så har vi:
% \begin{equation}
% H(z) = \frac{z^2-2\cos(\omega_c)z+1}{z^2-2r\cos(\omega_c)z+r^2} 
% \end{equation}
% Overføringsfunktionen er altså en ratio af to polynomier med reale
% koefficienter, og svarer til \cite[ex. 6.14 s. 340]{lyons}.
% For nemheds skyld indføres nu en gain-faktor $G$ til at
% normalisere responset til et gain på 1 i pasbåndet, og der forkortes med
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
% Ovenstående omskrives til IIR-filterets output i z-domænet:
% \begin{equation}
% \begin{aligned}
% & Y(z)(1 - 2r\cos(\omega_c)z^{-1} + r^2 z^{-2}) = X(z)G(1-2\cos(\omega_c)z^{-1}+z^{-2}) \\
% \Longrightarrow Y(z) &= GX(z)-2G\cos(\omega_c)z^{-1}X(z)+Gz^{-2}X(z) + 2r\cos(\omega_c)z^{-1}Y(z)-r^2 z^{-2}Y(z)
% \end{aligned}
% \end{equation}
% Differensligningen findes via den inverse z-transformation heraf.
% Her benyttes delay-relationen: hvis
% $X(z)\longleftrightarrow x(n)$ så $z^{-k}X(z) \longleftrightarrow
% x(n-k)$. Dette giver differensligningen, og ved sammenligning med 
% standardformen kan koefficienterne bekræftes \cite[6-21 s. 276]{lyons}:
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
% Værdien for $r$ svarer til ``selectivity'' (Q-faktor) for et analogt
% notch-filter: Jo højere $r$, jo stejlere filter\footnote{Der må være en
% algebraisk sammenhæng via den bilineære transformation?}.
% For et analogt filter er Q-faktor givet ved $Q=\frac{\omega_c}{\text{Bandwidth}}$.
% Antaget nogenlunde tilsvarende for det digitale filter: båndbredden
% omkring notch-frekvensen mindskes som $r$ øges.
% Værdien $r$ er valgt til $r=0.99$ (ved iterative forsøg) for at få et 
% stejlt filter, der også fungerer godt på target.
% Dermed kan filterets koefficienter beregnes:
% \\
% </latex>

r = 0.99;                          % Modulus for poler ("Q-faktor")
wc = pi * round(fidx) / (fs / 2);   % Centerfrekvens [rad/s]
K = 1;                              % Til første iteration af DC gain

for iteration=1:2
    G = 1/K;                % Skalering så DC Gain = 1 (0 dB). G=0.9991.

    % Følgende koefficienter ift. differensligning.
    b0 = G;                 % z^0
    b1 = -2*cos(wc)*G;      % z^-1
    b2 = G;                 % z^-2
    a1 = 2*r*cos(wc);       % z^-1
    a2 = -r*r;              % z^-2

    % Følgende polynomier ift. overføringsfkt.
    b = [b0 b1 b2];         % B(z)
    a = [1 -a1 -a2];        % A(z)

    K = sum(b)/sum(a);      % DC gain (Lyons s. 300)
end

%%
% <latex>
% \section{Pol-/nulpunktsdiagram}
% Figuren nedenfor viser, hvad der indledningsvist blev beskrevet
% om pul-nulpunktsplacering:
% De ligger meget tæt, med nulpunkterne på enhedscirklen.
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
xlim([real(p(1))*0.9 real(p(1))*1.1]);      % Vis tæt udsnit af et pol-
ylim([imag(p(1))*0.8 imag(p(1))*1.2]);        % nulpunktspar

%%
% <latex>
% \section{Differensligning og systemfunktion}
% Differensligningen nedenfor er ikke til direkte implementering på DSP,
% da koefficienter skal skaleres og kvantiseres først.
% Overføringsfunktion er også opskrevet.
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

Hsys = tf(b, a, 1/fs)   % Vis fin overføringsfunktion

%%
% <latex>
% \section{Signalgraf (direkte form 1)}
% Filteret bliver implementeret på direkte form 1.
% Figuren nedenfor viser filterstrukturen.
% Værdien af koefficienterne er angivet i foregående afsnit.
% Disse er først endelige efter skalering og kvantisering til target.
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
% Det kræver 5 multiplikationer og 4 summationer at beregne et ouput.
% Hvis vi havde benyttet direkte form 2 (byttet om på sektionerne) kunne vi
% nøjes med i alt 2 memory elementer til hele delay-line \cite[s. 159]{kuo2013}.
% </latex>
%%
% <latex>
% \section{Frekvensrespons}
% Frekvensresponset (amplitude- og faserespons) regnes for IIR notch-filteret.
% Frekvensreponset $H(e^{j \omega})$ regnes vha. ratioen på to FFT'er
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
% Amplituderesponset viser, at filteret rammer den ønskede frekvens (rød,
% lodret linje), og at gain i hele pasbåndet er 0 dB.
% Filteret er dog \textbf{ikke} ideelt, da transitionen fra pas- til 
% stopbånd ikke er undelig skarp/hurtig (roll-off ikke uendeligt stejl).
% Punkterne for \SI{-3}{dB} ligger ved hhv. \SI{800}{\hertz} og 
% \SI{950}{\hertz}. Dvs. ca. \SI{150}{\hertz} båndbredde i stopbåndet.
% Filterets selektivitet (Q-faktor) er da ca. $\frac{876}{150}=6$.
% Det kan nok gøres bedre.
% \\ \\
% Faseresponset viser en kvalitet ved et IIR notch-filter: 
% Fasen er flad i det meste af pasbåndet (dvs. group-delay er 0), 
% og i det meste af pasbåndet vil der ikke opstå faseforvrængning. 
% Nærmere centerfrekvensen er fasen ikke-lineær, og der kan
% opstå faseforvrængning i området ca. 700-\SI{800}{\hertz} og 
% igen ved ca. 950-\SI{1050}{\hertz}.
% Det er altså en fordel at være mere selektiv i valg af frekvens; 
% forudsat at det kan håndteres med fixed-point på target, 
% at frekvensen kendes på forhånd og at frekvensen er stationær.
% \\ \\
% Et IIR-filter af højere orden (kaskade) kunne også give mening, og 
% det kunne designes ud fra yderligere krav til responset:
% Stejlhed (bandwidth el. Q-faktor), dæmpning i stopbånd, 
% faserespons/group delay, osv.
% Vi arbejder med lyd her, og kunne nok bruge et filter med maksimalt
% lineær fase (Bessel). Så det kunne fx også være et designkriterium.
% Design vha. et analogt prototypefilter og konvertering til digitalt 
% filter med den bilineære z-transformation ville give mening.
% \\ \\
% Det er ærgerligt, at der ændres på musiksignalet i de nævnte 
% frekvensområder, da der netop er meget god lyd her - bas, percussion, osv.
% En bedre tilgang ville være et adaptivt filter, der helt specifikt kunne
% fjerne sinustonen.
% </latex>

%%
% <latex>
% \section{Test af filter i \MATLAB}
% Filteret testes på lydklippet. For at påvise, at der ikke længere er
% en forstyrrende frekvens i signalet, beregnes igen et spektrogram, med
% samme indstillinger som tidligere.
% \\
% </latex>

xfilt = filter(b,a,x);               % filtrér lydklippet
% soundsc(xfilt,fs)                  % lyt til klippet

tl = 5;                              % tidslængde til analyse, sekunder
x_ = xfilt(1:tl*fs)';                % udvalgt sektion af filtreret signal
L = fs/5;                            % vindueslængde 9600 => 5 Hz opløsning
stepSize = L;                        % step er 1 vindue (0% overlap)
Nfft = 2^nextpow2(L);                % 2^14
figure();
spectrogram0(x_, L, Nfft, stepSize, fs, [0 5000]); % Vis kun op til 5 kHz

%%
% <latex>
% Spektrogrammet viser nu, at den rene tone er fjernet fra signalet. 
% Det samme er bekræftet ved at lytte til signalet.
% Spektrogrammet viser også tydeligt, at en del information er mistet pga.
% dæmpning i frekvensområdet omkring centerfrekvensen.
% Der ses et tydeligt ``dødt'' område omkring filterets centerfrekvens.
% Filteret virker altså - i hvert fald med 64-bit-præcision - som ønsket.
% </latex>

%%
% <latex>
% \chapter{Opgave 3: Algoritmeudvikling og implementering på signalprocessor}
% </latex>

%%
% <latex>
% \section{Kvantisering og algoritmeudvikling}
% Dette afsnit analyserer og tester kvantisering af filterkoefficienterne.
% Desuden testes algoritmen (floating-point $\longrightarrow$ fixed-point), 
% der implementeres på target DSP'en.
% Der foretages test af algoritmer \textit{og} koefficienter sammen, 
% før der implementeres på hardware.
% \\ \\
% Koefficientkvantisering ændrer filterets karakteristik / respons. 
% Så der er risiko for et anderledes respons end hvad fås med infinite
% precision:
% \sbul
% \item Ændrede koefficienter (afrunding) ændrer filterets respons: 
% Kritiske frekvenser flyttes - muligvis signifikant.
% I yderste konsekvens bliver IIR-filteret også ustabilt, hvis
% kvantisering (afrunding) flytter pol(er) uden for enhedscirklen \cite[s. 170]{kuo2013}.
% \item Kvantisering fra 64-bit \textit{floating-point} til 16-bit 
% \textit{fixed-point} finite precision giver løbende 
% afrundings-/trunkeringsfejl i filtrering:
% Fordi det er et IIR-filter, så feedes disse fejl tilbage ind filteret,
% og kan akkumulere. Det kan give oscillationer (limit cycles) \cite[s. 293]{lyons}.
% \item Filterorden og filterstruktur påvirker ovenstående risiko
% for ustabilitet forårsaget af kvantisering \cite[s. 293]{lyons}:
% Det kan være en bedre strategi at implementere kaskadekobling af 
% 1./2.ordenssystemer, end at have et
% filter af højere orden \cite[s. 78]{kuo2013} \cite{directforms}.
% Så det er fornuftigt nok at arbejde med et 2. ordens filter her, og så
% evt. kaskadere (og skalere), efter behov.
% \ebul
% Med \MATLAB s \texttt{fixed-point designer}, \texttt{filterDesigner} 
% og \texttt{fvtool} kan man analysere effekten af kvantisering af filteret.
% </latex>

%%
% <latex>
% \subsection{S15-kvantisering af filterkoefficienter}
% Værdiområdet for S15 er $1 \leq x < 1-2^{-15}$.
% Koefficienterne $b_1$ og $a_1$ er numerisk større end $1-2^{-15}$ 
% men numerisk mindre end $2$. Så ved division med $2$ nedskaleres til S15.
% Der er umiddelbart to metoder til at håndtere dette i differensligningen:
% \sbul
% \item Nedskalér \textit{kun} de to koefficienter med $2$, og ``opvej'' 
% skaleringen ved at indregne deres led dobbelt i differensligningen. 
% Dvs. $y(n) = \ldots + \frac{b_1}{2} x(n-1) + \frac{b_1}{2} x(n-1) + \ldots $.
% \item Nedskalér \textit{alle} koefficiencter med faktor 2. Skaleringen
% opvejes i differensligningen ved at akkumulere dobbelt, dvs. afsluttende 
% MAC-operation er \texttt{akk += akk}.
% Da både $B(z)$ og $A(z)$ skaleres, ændres frekvensresponset ikke.
% \ebul
% Førstnævnte vælges, da det påvirker færrest koefficienter. Herunder
% vises princippet i S15-kvantiseringen. I det følgende repræsenterer $b_n$
% bits og \textit{ikke} filterkoefficienter!
% \\ \\
% I S15 \textit{forestiller} vi os, at der er et binærkomma $k=15$ pladser
% fra højre (LSB), og at MSB repræsenterer tallets fortegn.
% S15 bitmønsteret med indsat binærkomma er
% $b_{0}.b_{1}b_{2}b_{3} \cdots b_{13}b_{14}b_{15}$.
% Mønsteret repræsenterer radix-10 kommatalsværdien
% $-b_{0} + \sum_{n=1}^{k=15} b_n 2^{-n}$.
% \\ \\
% Så for et tal $0 \leq u_1 < 1$ gælder repræsentationen
% $\sum_{n=1}^{k=15} b_n 2^{-n} \longleftrightarrow u_1$ som er ækvivalent
% til $b_1 2^{14} + b_2 2^{13} + \ldots + b_{15} \longleftrightarrow u_1
% 2^{15}$.
% Venstresiden er et heltal på binær form (radix-2 med 15-bits).
% En evt. overskydende kommadel i $u_1 2^{15}$ på højresiden trunkeres, 
% da der ikke er bits på venstresiden til at repræsentere den.
% \\ \\
% Derfor kan $u_1$ omregnes fra kommatal til S15 med
% \texttt{floor($u_1 2^{15}$)}. Tydeligvis fås en numerisk mindre fejl, 
% hvis vi i stedet benytter \texttt{round($u_1 2^{15}$)}, antaget at evt.
% oprunding kan indeholdes i wordlength uden overflow\footnote{
% Det kræver mange flere operationer at tage \texttt{round} end
% at tage \texttt{floor}, så mens det er OK til omregning af koefficienter
% i \MATLAB~, så duer det slet ikke til løbende MAC-beregninger på DSP.}.
% Lagring af dette i signed heltalsbitmønster lader vi compiler/\MATLAB~ 
% håndtere (det er 2-komplement).
% \\ \\
% Det negative tal $u_2 = -u_1$ repræsenteres ved
% $u_2 = -u_1 \longleftrightarrow$ \texttt{-round($u_1 2^{15}$)}
% $=$ \texttt{round($u_2 2^{15}$)}.
% For begge tal benyttes altså en skaleringsfaktor $K=2^k=2^{15}$,
% som svarer til bitshift og cast \texttt{(short) (u1 <\/< 15)}.
% Ved lagring som bits håndteres fortegnsbit med to-komplement. 
% Den binære repræsentation af $u_2$ kan fx\footnote{Alternativt 
% $2^{16}-1 - (u_1)_2 + 1$, hvilket er et-komplement og addering med 1.} 
% beregnes ved $(2^{16})_{2} - (u_1)_{2}$.
% Et negativt tal vil altid have $b_0=1$.
% \\ \\
% Regneeksempel: To tal, $u_1=0.9$ og $u_2=-0.9$, konverteres til S15
% og multipliceres som på en 16-bit fixed-point platform.
% \\
% </latex>

u1 = 0.9; u2 = -u1;
B = 16;                 % B er længden på hele binær-ordet (word length)
k = 15;                 % k er længden på brøk-delen (fraction length)
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
% Da skaleringsfaktoren også multipliceres, kræves 32-bit for
% repræsentere produktet $U_1 U_2=$ \texttt{round($u_1 u_2 2^{30}$)}.
% S15-formatet kan genetableres ved at dividere med skaleringsfaktoren, så
% i S15: $u_1 u_2 = \texttt{round(} U_1 U_2 2^{-15} \texttt{)} $.
% Decimatallet genetableres ved yderlige nedskalering med $2^{15}$ uden 
% afrunding.
% \\
% </latex>

disp( ['Multiplikation af u1 og u2 i S15 -> ' num2str(round(U1*U2/K)) ] );
disp( ['Resultat i decimal -> ' num2str(round(U1*U2/K)/K) ] );

%%
% <latex>
% På en fixed-point-platform caster man $u_1$ og $u_2$ til en bredere type,
% \texttt{U1U2 = (long) u1 * u2} og konverterer og trunkerer bagefter vha. 
% \texttt{(short) (U1U2 >\/> 15)}\footnote{Det giver selvfølgelig en anden
% fordeling for afrundingsfejl end eksemplerne med \texttt{round} vist her.}.
% Dette kan emuleres:
% \\
% </latex>

U1U2_Q30 = int32(U1)*int32(U2);                          % (long) U1*U2

% Manipulation af bitmønstrene:
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
% Hvilket demonstrerer, at det rigtige resultat også frembringes ved
% direkte bitmanipulationer.
% \\
% </latex>
%%
% <latex>
% \subsection{Test af effekt af kvantisering i \MATLAB}
% For at se effekt af kvantisering, oprettes et diskret filterobjekt som 
% direkte form 1, med kvantiserede koefficienter (fixed-point).
% Denne fremgangsmåde er inspireret af \cite[s. 125 ff.]{kuo2013}.
% \\ 
% </latex>

Hd = dfilt.df1(b,a);            % Ikke-kvantiseret filter
Hdq = copy(Hd);                 % Kopiér objekt så vi evt. kan sammenligne

% Kvantisér filteret
Hdq.Arithmetic='fixed';         % Fixed-point-filter
Hdq.RoundMode='floor';          % Trunkering
Hdq.CoeffAutoScale = false;
Hdq.CoeffWordLength = 16;
Hdq.DenFracLength = 14;         % Kan ikke redueres til S15 pga værdiomr.
Hdq.NumFracLength = 14;
Hdq.ProductMode='SpecifyPrecision';
Hdq.ProductWordLength = 32;     % (long) b0*x(n) ind i akkumulator
Hdq.InputWordLength = 16;
Hdq.InputFracLength = 15;
Hdq.OutputWordLength = 16;
Hdq.OutputFracLength = 15;
Hdq.CastBeforeSum = true;

x_filt_q = filter(Hdq, x);      % Filtrér med kvantiseret filter
x_filt_fp = double(x_filt_q);   % Konvertér filtreret sign. til floating pt
% soundsc(x_filt_fp, fs);           % Afspil filtreret lydsignal - OK!
% freqz(Hdq, 'half');           % åbner FVtool og viser frekvensrespons,
                                % pol-/nulpunktsdiagram mv.

%%
% <latex>
% Ovenstående forsøg bekræfter, at filteret også virker, når det er
% kvantiseret (med trunkering).
% \texttt{FVtool} viser et pol-/nulpunktsdiagram (ikke
% illustreret her), som bekræfter at polerne stadig ligger inden for
% enhedscirklen (stabilt).
% Der vises også et frekvensrespons, som bekræfter, at
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
% \item Den rene tone er dæmpet omkring 40 dB 
% (ingen uendelig dæmpning med kvantiseret filter).
% Dog er en del af signalet omkring tonen også blevet dæmpet i processen.
% \item Powerspektra matcher fint i pasbåndet, så kvantiseret filtrering 
% har ikke generelt ``ødelagt'' signalet.
% \item Når frekvensen nærmes centerfrekvensen, ændres signalet gradvist, 
% hvilket stemmer overens med de tidligere nævnte frekvensområder.
% \ebul
% </latex>

x_post_ = x_filt_fp(1:tl*fs);         % Udvælg 5s af filtreret signal 
Nfft = 2^nextpow2(length(x_post_));   % 2^18 -> zero-padding med 22144 0'er 
X_post_ = fft(x_post_, Nfft);
X_post_pow = X_post_ .* conj(X_post_);      % Powerspektrum
f_vec = (fs / Nfft) * (0:Nfft-1);           % Tilhørende frekvensakse

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
% Kvantiseringsfejlen (pga. præcision og trunkering) har et spektrum og 
% en sandsynlighedsfordeling.
% Men her antages bare, at denne fejl er jævnt fordelt hvidstøj med 
% middelværdi på 0, og at der ikke skal foretages yderligere.
% </latex>

%%
% <latex>
% \subsection{Output af \MATLAB -kvantiserede filterkoefficienter}
% Det indebyggede \texttt{filterDesigner}-værktøj kan eksportere 
% filterkoefficienterne til en C-header:
% \sbul
% \item \texttt{File > Import filter from Workspace > Filter object > Hdq}.
% \item \texttt{Targets > Generate C Header > Export as > Signed 16-bit integer > Export}.
% \ebul
% Da koefficienterne ligger i intervallet $-2 \leq x < 2-2^{-14}$, vil 
% \texttt{filterDesigner} eksportere som Q2.14, dvs. med kun 14 fractional 
% bits.
% \\ \\
% Bemærk også fortegn på $a_1$ og $a_2$ (DEN[1] og DEN[2]).
% Fortegnene er som i polynomiet $A(z)$, dvs. omvendt af
% hvad der bruges i differensligningen, som jeg har opskrevet den.
% \\ \\
% For koefficienterne i værdiområdet for S15, dvs. $b_0$, $b_2$ og $a_2$, 
% vil et venstre bitshift (<\/< 1) konvertere fra Q2.14 til S15.
% For koefficienter uden for værdiområde (dvs. $b_1$ og $a_1$), kan
% koefficienterne benyttes direkte jf. diskussionen omkring skalering med 2
% og efterfølgende dobbelt-addition.
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
% Der benyttes en lineær buffer. Det giver et par få ekstra operationer.
% Det giver ikke mening at implementere en cirkulær buffer i \MATLAB~ da
% der ikke findes pointers, og delay lines kun består af 2 elementer hver.
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
    % Implementér differensligning:
    y(n) = b0*in(n) + b1*delay_x(1) + b2*delay_x(2) + ...
            a1*delay_y(1) + a2*delay_y(2);
    
    % Opdatér delay line ved at shifte nyeste værdi ind
    delay_x = [in(n) delay_x(1)];
    delay_y = [y(n) delay_y(1)];
end

%%
% <latex>
% Ved aflytning af det filtrerede signal bekræftes det, at algoritmen har
% virket som ønsket. Der er også kørt en impuls igennem filteret, 
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
% Formålet er at forstå og analysere forskellene til floating-point, og at
% forberede implementering på target DSP'en.
% Der benyttes S15-kvantiserede koefficienter og input (16-bit præcision).
% ``Akkumulatoren'' i \MATLAB~ er 64-bit, mens DSP'ens egen 32/40-bit 
% akkumulator har 8 guard-bits, og kan håndtere 256 32-bit additioner uden 
% overflow. Så overflow-aspektet behøver vi ikke at simulere her.
% \\
% </latex>

K = 2^15;                   % Benyttes til <<15 og >>15 operationer

% Koefficienter i S15
b0_ = round(b0 * K);        % Svarer til (short) (b0 << 15)
b1_ = round(b1/2 * K);      % Bem. b1/2, så skal akkumuleres dobbelt
b2_ = round(b2 * K);
a1_ = round(a1/2 * K);      % Bem. a1/2, så skal akkumuleres dobbelt
a2_ = round(a2 * K);

% Kvantisér input. Dette skal ikke gøres i C.
% Først skaleres til værdiområde for S15
% -> der er meget få elementer |x|>1 , disse clippes i stedet for at
% re-skalere hele serien.
x_ = x;
x_(x_ >= 1) = 1-2^-15;      % Clippes til max-værdi for S15
x_(x_ < -1) = -1;           % Clippes til min-værdi for S15
x_ = round(x_*K);           % Kvantisering

N = length(x_);
y = zeros(1, N);

dx = [0 0];                 % Nulstil delay lines
dy = [0 0];

for n=1:N
    % Implementér differensligning med MAC-operationer
    acc = b0_*x_(n);
    acc = acc + b1_*dx(1);
    acc = acc + b1_*dx(1);  % Adderer 2 gange fordi koefficient er b1/2
    acc = acc + b2_*dx(2);
    acc = acc + a1_*dy(1);
    acc = acc + a1_*dy(1);  % Adderer 2 gange fordi koefficient er a1/2
    acc = acc + a2_*dy(2);
                   
    y(n) = round(acc/K);    % (short) (acc >>15),  Q2.30 -> Q1.15 (S15)
    
    % Opdatér delay line til næste iteration ved at shifte nyeste værdi ind
    dx = [x_(n) dx(1)];     % Bliver [x(n-1) x(n-2)]
    dy = [y(n) dy(1)];      % Bliver [y(n-1) y(n-2)]
    
end

y = y/K;                    % Omregn y tilbage til værdiområdet [-1;1[

%%
% <latex>
% Afspilning af nummeret efter filtrering bekræfter, at den forstyrrende
% tone er fjernet. Filteret virker altså også med fixed-point aritmetik.
% Det er oplagt at sammenligne tids- og frekvensserier hhv. før og efter
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
% Øverste figur over tidsdomænet viser, at bortfiltrering af tonen har 
% taget energi (amplitude) ud af signalet.
% Det er mest markant i starten af skæringen, 
% hvor der kun er sinustonen og ingen musik.
% For den filtrerede tidsserie ses i øvrigt en indsvingning af filteret.
% \\ \\
% I effektspektra (kun vist i intervallet 750-\SI{1000}{\hertz}, ses, at
% filtreringen har dæmpet den rene \SI{876}{\hertz}-tone med ca. \SI{40}{dB}.
% Kun i den nære omegn af notchet (notch båndbredde), er frekvensindholdet
% blevet ændret af filteret. Det er svært at høre, at ``der mangler
% noget'' i forhold til originaloptagelsen.
% \\ \\
% Ovenstående analyse giver noget vished om, at algoritme og koefficienter
% svarende til ovenstående burde virke på signalprocessoren.
% Næste skridt er implementering på hardware.
% </latex>

%%
% <latex>
% \section{Opsætning af projekt i CCS}
% Som udgangspunkt for kodeprojektet er opskriften ``Audio Loop Through''
% benyttet \cite{kplezdsp}.
% Da jeg i dette projekt driver input med wavegenerator, og ikke en
% mikrofon, er gain i ADC/DSP reduceret til \SI{0}{dB}.
% Samplingsfrekvens er fastholdt på \SI{48}{\kilo\hertz} da filteret er
% designet dertil, og der intet behov er for at ændre derpå. Opsætning
% i \texttt{main.c} ses herunder:
% \\
% </latex>

%%
% <latex>
% \begin{lstlisting}[style={C++}, caption={Opsætning i main.c}]
% printf("E4DSA Case 2 (Janus) - IIR notch filter DSP: ");
% %\newline%
% /* Setup sampling frequency and 0 dB gain for line in */
% set_sampling_frequency_and_gain(SAMPLES_PER_SECOND, 0);
% \end{lstlisting}
% </latex>

%%
% <latex>
% Desuden er bias af mikrofon slået fra (til fx mikrofoner i headset, 
% som skal have bias for at virke). Denne registerindstilling er nævnt i
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
% på funktion. I c-filen findes implementeringen. I \texttt{main.c} er
% der implementeret et uendeligt loop, der tager input fra ADC (line-in),
% kalder filterfunktion og sender resultat ud af DAC (line-out).
% Som det ses, benyttes kun højre kanal, for at kunne benytte den venstre 
% kanal til en anden filtrering eller til det ufiltrerede output i 
% forbindelse med tests.
% \\
% \begin{lstlisting}[style={C++}, caption={Uendelig løkke i main.c}]
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
% Som kan ses i koden, er der eksperimenteret med forskellige sæt
% koefficienter, der repræsenterer forskellige Q-faktor,
% for at se og høre forskel på filterets funktion og respons.
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
% lineære buffers (så få koefficienter, at det er en ligegyldig
% optimering at bruge en cirkulær buffer her).
% Filteret er i direkte form 1, 
% så der er delay lines for både $x(n)$ og $y(n)$.
% Bemærk også, at MAC-operation for $b_1$ og $a_1$ forekommer dobbelt, da
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
% \chapter{Opgave 4: Test på target}
% Nedenstående opstilling er benyttet til test på target DSP-hardware.
% Analog Discovery's signalgenerator (AWG) er sluttet til
% line-in. Line-out er forbundet til oscilloskop.
% Hvide stik er AWG1 og scope CH1, som bærer højre lydkanal.
% Forsyning til eZDSP-kittet er med påsat ferrit for at dæmpe evt. 
% højfrekvent støj fra bl.a. computerens strømforsyning.
% \begin{figure}[H]
% \centering
% \includegraphics[width=10cm]{../img/testopstilling2.jpg}
% \caption{Testopstilling\label{fig:testopstilling}}
% \end{figure}
% AWG benyttes til at afspille musiksignalet eller lave sweeps. 
% Spektrumanalysator kan analysere frekvensindhold i output fra target.
% Netværksanalysator kan bruges til at lave en frekvenskarakteristik.
% \\ \\
% Line level for ``consumer''-udstyr er \SI{-10}{dBV} dvs. 316 mV
% RMS\footnote{
%  \SI{0}{dBV} er \SI{1}{\volt} RMS.
%  \SI{-10}{dBV} svarer til et sinussignal med peak-amplitude 0.447 VPK.
% }\cite{nominallevels}.
% Mic-level er typisk meget lavere, fx \SI{-40}{dBV}.
% For at undgå clipping (eller at brænde ADC'en i line-in af), 
% holdes amplituden fra AWG på maks. 50 mV (\SI{-29}{dBV})\footnote{
%  Peak-amplitude på 50 mV svarer cirka til 35 mV RMS, som er \SI{-29}{dBV}.
% }.
% \\ \\
% </latex>

%%
% <latex>
% \section{Test 1: Musik med sinustone og frekvenssweep}
% Det filtrerede musiksignal er aflyttet med en højttaler for at bekræfte,
% at lydkvaliteten stadig er som forventet, og at sinustonen er dæmpet.
% Forsøget kan ses/høres her: \url{https://youtu.be/urbXrjlm0hs}.
% \\ \\
% Et sweep fra 700-\SI{1050}{\hertz} er også blevet forsøgt.
% Det auditive indtryk er, som forventet, at frekvenserne tæt omkring centerfrekvensen dæmpes.
% Forsøget kan ses/høres her: \url{https://youtu.be/BOKc1OGQojs}.
% \\ \\
% Baseret på test 1 konkluderes, at filteret virker.
% </latex>


%%
% <latex>
% \section{Test 2: Musiksignal og spektrumanalysator}
% Musiksignalet afspilles igen fra AWG1 (50 mV peak-amplitude). 
% Spektrumanalysatoren benyttes til måle og sammenligne frekvensindhold i 
% hhv. et filtreret og et ikke-filtreret outputsignal for
% frekvensområdet 700-\SI{1000}{\hertz}.
% CH1 (orange) er filtreret og CH2 (blå) er ikke-filtreret.
% \begin{figure}[H]
% \centering
% \includegraphics[width=16cm]{../img/spektrumanalysator2.png}
% \caption{Sammenligning af filtreret og ikke-filtreret output
% \label{fig:spektrumanalysator}}
% \end{figure}
% Figuren viser, at det ikke-filtrerede signal har en ren tone
% omring \SI{876}{\hertz}, og at tonen er dæmpet i det filtrerede
% signal. Som forventet :-) De to spektra er ikke sammenfaldende, bl.a.
% fordi det filtrerede signal er forsinket gennem filteret.
% Det ses også, at niveauet for den rene tone ligger lidt under det
% beregnede maksniveau: \SI{-34}{dBV} ift. \SI{-29}{dBV} beregnet.
% </latex>

%%
% <latex>
% \section{Test 3: Frekvenskarakteristik}
% Frekvenskarakteristikken optages med Waveforms' netværksanalysator.
% Igen undersøges frekvensområdet 700-\SI{1000}{\hertz}.
% Der optages 2000 samples over frekvensområdet, og
% AWG er sat op til at køre 64 perioder for hver frekvens i sweep'et.
% \\ \\
% Figuren nedenfor viser en karakteristik, der som forventet ligner spektra
% beregnet i \MATLAB .
% Den maksimale dæmpning i notchet er på ca. \SI{-60}{dB}, hvilket er
% højere end de ca. \SI{-40}{dB} dæmpning af sinustonen, der blev
% observeret i \MATLAB .
% Forklaringen er nok, at kvantisering har flyttet filterets
% centerfrekvens en lille smule, så sinustonens \SI{876}{\hertz} ikke 
% bliver ``ramt'' med den fulde dæmpning.
% \begin{figure}[H]
% \centering
% \includegraphics[width=16cm]{../img/netvaerksanalysator.png}
% \caption{Frekvenskarakteristik
% \label{fig:netvaerksanalysator}}
% \end{figure}
% Selvom gain i hardware er sat til \SI{0}{dB} (for ADC'en), sker der en
% forstærkning, som er urelateret til selve filteret, hvilket kan bekræftes
% ved niveau for det ikke-filtrerede (blå) signal.
% Højst sandsynligt sker forstærkningen i DAC'en. 
% Jeg har ikke (endnu) forsøgt at slå dette gain fra.
% \\ \\
% Baseret på frekvenskarakteristikken konkluderes, at filteret virker, men
% at der kunne gøres mere for at ``tune'' det kvantiserede filter til den
% ønskede centerfrekvens.
% </latex>


%%
% <latex>
% \chapter{Opgave 5: Fri leg}
% Denne opgave blev der desværre ikke tid til denne gang :-(
% </latex>

%%
% <latex>
% \chapter{Forbedringsmuligheder}
% \sbul
% \item ``Tuning'' af det kvantiserede filter til mere præcist at ramme den
% ønskede centerfrekvens.
% \item ``Optimering'' af det kvantiserede filter til at være
% skarpere/stejlere.
% \item Lave en kaskade af 2. ordensfiltre til at få et mere selektivt filter
% (smallere stop-båndbredde og højere dæmpning i centerfrekvensen).
% \item Benytte et adaptivt filter til \textit{kun} at fjerne sinustonen
% uden at dæmpe nogen omkringliggende frekvenser.
% \ebul
% </latex>

%%
% <latex>
% \chapter{Konklusion}
% I denne case er der designet og implementeret et 2. ordens IIR
% notch-filter i \MATLAB . Algoritmer og koefficienter er også udarbejdet
% til implementering af filteret på DSP-hardware. 
% Hardwareimplementeringen er testet med tre forskellige metoder, og
% det er verificeret, at filteret virker på target, som ønsket.
% En række forbedringsmuligheder er nævnt til at få et filter med endnu
% bedre performance.
% \\ \\
% Det har været en interessant case - især fordi en række hensyn skulle
% tages til ikke-ideelle forhold under implementering på DSP-hardware.
% Bl.a. kvantisering til 16-bit, men også andre hardware-faktorer.
% </latex>

%%
% <latex>
% \cleardoublepage
% \chapter{Kildehenvisning}
% \printbibliography[heading=none]
% </latex>

%%
%
xyzblabla = randn(1000); % Til at vente på graferne...
%% 
% <latex>
% \newpage
% \chapter{Hjælpefunktioner\label{sec:hjfkt}}
% Der er til projektet implementeret en række hjælpefunktioner.
% </latex>

%% setlatexstuff
%
function [] = setlatexstuff(intpr)
% Sæt indstillinger til LaTeX layout på figurer: 'Latex' eller 'none'
% Janus Bo Andersen, 2019
    set(groot, 'defaultAxesTickLabelInterpreter',intpr);
    set(groot, 'defaultLegendInterpreter',intpr);
    set(groot, 'defaultTextInterpreter',intpr);
end

%% spectrogram0
% Implementeret af Kristian Lomholdt, E4DSA.
% Let modificeret, Janus, feb. 2020.
% Baseret på Manolakis m.fl., s. 416.
function S=spectrogram0(x,L,Nfft,step,fs,ylims)
% Spektrogram. Beregner og viser spektrogram
% Baseret på: Manolakis & Ingle, Applied Digital Signal Processing, 
%             Cambridge University Press 2011, Figure 7.34 p. 416
% Parametre:  x:    inputsignal
%             L:    vinduesbredde ("segmentlængde")
%             Nfft: DFT størrelse. Der zeropaddes hvis Nfft>L
%             step: stepstørrelse
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
    
    colormap(jet);     % farveskema, prøv også jet, summer, gray, ...
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
