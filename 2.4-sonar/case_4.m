%% E4DSA Case 4 - Sonar
%%
% <latex>
% \chapter{Indledning}
% Fjerde case i E4DSA omhandler sonar (SOund NAvigation Ranging).
% Ideen er at udsende et eller flere pulsede signaler, 
% der reflekteres på et target.
% De reflekterede signaler (ekkoer) opfanges og analyseres for at kunne
% bestemme fx targets
% (1) afstand, (2) hastighed (Doppler-effekt), (3) bevægelsesretning 
% eller (4) form/struktur/størrelse (signatur).
% \\ \\
% Sonar er nok ensbetydende med anvendelser \textit{under} vand og med 
% signaler båret i lydbølger.
% Det kendes f.eks. fra u-både \url{https://www.youtube.com/watch?v=jr0JaXfKj68}.
% Her kan sonar bruges til at kortlægge eller navigere ift. havbunden 
% - eller til at lokalisere skibe og andre objekter i vandet.
% På forsiden ses et eksempel af en Multibeam echosounder (MBES), der kan 
% kortlægge havbundens topografi vha. sonar-``stråler'' (vha. beamforming).
% Biosonar (ekkolokalisering), som hvaler og delfiner anvender til 
% kommunikation og jagt, er et interessant eksempel fra naturen.
% \\ \\
% Over vandet anvendes ideen fx i ultrasoniske sensorer i biler. 
% Fx som sensorer til at afstandbedømme og assistere ved parkering og bakning.
% Det er et billigt alternativ til LIDAR.
% Der sidder også en ultrasonisk sensor i bunden af min quadrotor-drone,
% som (sammen med et barometer) benyttes til højdemåling.
% I disse anvendelser benyttes luft som bæremedium, der naturligvis har 
% helt anderledes akustiske karakteristika end vand.
% \\ \\
% Radar-systemer er et parallelt eksempel, hvor signalet i stedet bæres af 
% elektromagnetiske bølger og med en meget højere udbredelseshastighed.
% Transduceren er også væsentlig mere kompliceret.
% \\ \\
% Summa summarum, der er rigtig mange interessante anvendelser og perspektiver
% :-)
% </latex>

%%
% <latex>
% \chapter{Opgave 1: Signalgenerering og simulering}
% Opgaven minder en del om Case 1 (FSK-transmission). 
% Men i denne case ønsker vi at lave detektion af et tidsforskudt signal i 
% \textit{tidsdomænet} i stedet for flere forskellige frekvenser i
% frekvensdomænet.
% Så vi benytter krydskorrelation i stedet for foldning\footnote{
% Hvilket så er ligesom foldning, hvis man pre-flipper det ene af 
% signalerne}. 
% I det følgende benyttes notationen samplingsfrekvens $f_s$ og 
% samplingstid $T_s = 1 / f_s$.
% \\ \\
% </latex>

%% 
% <latex>
% \section{Teori}
% </latex>

%%
% <latex>
% \subsection{Krydskorrelation}
% Krydskorrelation er givet ved \cite[kap. 7]{dspguide}
% \begin{equation}
% c(n) = \sum_{k=0}^{N_p-1} p(k) \cdot r(n+k)
% \end{equation}
% Her er $p(n)$ den afsendte puls med længden $N_p$ samples, 
% så tidslængde af $p$ er $N_p \cdot T_s$ [s]. 
% Signalet $p(n)$ forsøges detekteret i det reflekterede signal $r(n)$.
% Krydskorrelation til tidspunkt $n$ er som et indre 
% produkt af $p$ og et udvalgt interval af $r(n)$, 
% $n \ldots n+N_p$. Med tilpas zero-padding, hvis nødvendigt.
% \begin{equation}
% c(n) = \langle p, r_{n:n+N_p} \rangle(n)
% \end{equation}
% Hvis signalerne er ortogonale (helt uens) i det valgte interval er 
% korrelationen 0.
% En numerisk høj krydskorrelation angiver høj energi af signalet $p$ ved $r(n)$.
% Et højt negativt tal svarer til modfase.
% Detektionen kan afgøres ved at sætte en tærskel-værdi.
% \\ \\
% Rullende krydskorrelation giver en tidserie, der viser ved hvilke 
% tidsforskydninger $p$ kan detekteres i $r(n)$.
% Her er det ønskeligt at have så smalt et ``blip'' i krydskorrelationen
% som muligt, for at få en maksimalt præcis afstandsmåling.
% </latex>

%% 
% <latex>
% \subsection{Tidsforskydning, minimumsafstand og afstandsopløsning}
% Tidsforskydning mellem afsendt og modtaget puls er en funktion af afstand
% til target, $R$ [m], og signalets hastighed, $v$ [m/s] \cite{sonarintro}.
% Tidsforskydningen er $\tau$ [s], svarende i samples til $\tau=n_{\tau} \cdot T_s$. 
% \begin{equation}
% R = \frac{v \cdot \tau}{2} \Longleftrightarrow
% \tau = \frac{2R}{v}
% \end{equation}
% Med sampling (diskret tid)
% \begin{equation}
% R = \frac{v \cdot n_{\tau} \cdot T_s}{2} = \frac{v \cdot n_{\tau}}{2f_s}
% \Longleftrightarrow
% n_\tau = \frac{2R}{T_s \cdot v} = \frac{2R}{v} f_s
% \end{equation}
% </latex>

%%
% <latex>
% For vores sonar er $\tau$ tiden det tager signalet at tilbagelægge 
% rundturen ud til target og tilbage i fri luft.
% En lydbølges udbredelseshastighed i fri luft ved \SI{20}{°C} er $v=343$ m/s.
% \\ \\
% Så hvis der i vores system observeres tidsforskydning på $n_\tau = 1$ sample, 
% fx med samplingsfrekvens \SI{1}{\kilo\hertz}, så er afstanden til
% target på $R = \frac{343 \cdot 1}{2 \cdot 1000} = 0.172$ [m].
% \\
% </latex>

%%
% <latex>
% \textbf{Minimumsafstand:} Hvis afsendelse af signal skal være afsluttet 
% inden ekko returnerer, skal følgende gælde for en en puls med bredden
% $T_{\text{puls}}$ [s]:
% \begin{equation}
% T_{\text{puls}} < \tau = \frac{2R}{v}
% \end{equation}
% Det betyder, at hvis et objekt er på afstanden \SI{1.00}{\meter}, skal 
% $T_{\text{puls}} < \frac{2 \cdot 1.00 \text{m}}{343 \text{m/s}} = 0.00583 \text{s}$
% Altså en puls på maks. \SI{5.83}{\milli\second}.
% \\ \\
% For en ren sinustone kan en konstant lyttende modtager ved siden af senderen
% ikke adskille det afsendte signal fra et ekko.
% Det er fordi $p(n)$ korrelerer periodisk med sig selv (autokorrelation) og med ekko
% (krydskorrelation). Så her er $T_{\text{puls}} < \tau$ vigtigt!
% For et ikke-periodisk signal er relationen mindre væsentlig, antaget at
% der ikke sker destruktiv interferens.
% \\
% </latex>

%%
% <latex>
% \textbf{Afstandsopløsning:} 
% Opløsningen bestemmes af pulsbredden.
% Når to returpulser overlapper, kan to targets ikke længere adskilles.
% Dette er illustreret i figuren nedenfor \cite[s. 34]{sonarintro}.
% \begin{figure}[H]
% \centering
% \includegraphics[width=9cm]{../img/mindist.png}
% \caption{Opløsning for afstandsmåling\label{fig:resolution}}
% \end{figure}
% Så opløsningen på afstandsmåling, $\Delta R$, er 
% \begin{equation}
% \Delta R = \frac{v \cdot T_{\text{puls}}}{2}
% \end{equation}
% Med en varighed på fx $T_{\text{puls}}=0.1$ s er opløsningen
% $\Delta R = \frac{343 \text{m/s} \cdot 0.1 \text{s}}{2} = 17.2$ m.
% Med en frekvens i den høje ende af det hørbare område, fx $f_0 = 20$ kHz,
% kan man afsende $f_0 \cdot t = 100$ perioder på $t=$ \SI{5.0}{\milli\second} 
% og opnå en opløsning på \SI{0.86}{\meter}. 
% Det kræver så en transducer, der kan afsende og modtage dette 
% (måske et piezo-element) samt ADC der kan klare $f_s > 40$ kHz.
% </latex>

%% 
% <latex>
% \subsection{Indflydelse fra støj}
% Antag der afsendes en impuls med amplitude $A$, så $p(n)=A\delta(n)$.
% Så modtages der tidsforskudt en impuls, som pga. afstand og medium er
% dæmpet med faktor $K$ samt tillagt additiv støj.
% Lydtryk for en lydbølge falder af med $K=\frac{1}{R}$.
% Da bliver det modtagne signal $r(n)=A R^{-1} \delta(n-n_\tau) + B(n)$.
% Krydskorrelationen bliver
% \begin{equation}
% c(n) = \sum_{k=0}^{N_p-1} A \delta(k) \cdot A R^{-1} \delta(n-n_\tau + k)
% + \sum_{k=0}^{N_p-1} A \delta(k) \cdot B(n+k) =
% \begin{cases}
% \frac{A^2}{R} + A \cdot B(n), & \text{hvis } n = n_\tau \\
% A \cdot B(n),         & \text{hvis } n \neq n_\tau
% \end{cases}
% \end{equation}
% Så det afhænger af $\frac{A^2}{R}$, dvs. effekt af afsendt signal
% over afstand, set i forhold støjens størrelse, om signalet kan detekteres.
% Der skal altså afsendes med større effekt for at detektere på større
% afstand. Tilsvarende hvis støjen øges.
% \\ \\
% En ren impuls kan selvfølgelig ikke afsendes over en analog kanal.
% Det ville heller ikke være en god idé.
% Så der skal bruges en anden signaltype.
% </latex>

%%
% <latex>
% \section{Valg af afsendersignal}
% Overblik over typer og anvendelser:
% \sbul
% \item Hvis signalet skal bruges til \textit{hastighedsmåling} med 
% Doppler-effekten, så skal frekvensen være konstant.
% \item Hvis signalet skal bruges til præcis \textit{afstandsmåling}, 
% er det vigtigt at ``spike'' i krydskorrelationen er meget smal, hvilket
% kræver en (frekvens)modulation.
% \item Hvis signalet skal begge dele, så kan det nok komponeres
% (kodes), så der både er elementer til Doppler-beregning og til
% afstandsbedømmelse.
% \ebul
% </latex>

%%
% <latex>
% Tre oplagte muligheder til at implementere afsendersignal er derfor 
% pulser bestående af:
% \sbul
% \item Rene sinustoner ($\to$ Dopplerberegning). \textit{MEN:} 
%  $p(n)$ krydskorrelerer med sit ekko for hver periode i 
%  sinussignalet, så det giver et bredt ``blip''.
% \item Chirps, frekvensmoduleret sinus ($\to$ afstandsmåling). 
%  Korrelerer kun væsentligt når ``forkanterne'' på signal og ekko flugter.
%  Det giver et smalt og kraftigt ``blip''. 
%  \textit{MEN:} frekvensen er moduleret, så Doppler-beregning er vanskelig.
% \item Et kodet signal (fx FSK, dog uden for scope i denne case). 
%  Kunne gøre begge dele.
% \ebul
% </latex>

%%
% <latex>
% Trade-off på længden af pulsen:
% \sbul
% \item Lang nok til at få en detekterbár og ikke falsk-positiv effekt 
%  i krydskorrelationen (støjimmunititet).
% \item Tilpas kort, så der fås en høj opløsning (lav minimumsafstand).
% \ebul
% </latex>

%%
% <latex>
% Trade-off på frekvensen i pulsen:
% \sbul
% \item Højere frekvenser $\to$ mange perioder sendes afsted på kort tid: 
% Flere datapunkter til krydskorrelation, bedre afstandsopløsning 
% $\Delta R$. \textit{MEN:} luften har tendens til at lavpasfiltrere, så højere
% frekvenser vil opleve større dæmpning.
% \item Lavere frekvenser: Dæmpes ikke nær så meget i luften, så kan opnå 
% større afstande. \textit{MEN:} Behov for at sende længere puls $\to$ 
% dårligere frekvensopløsning og minimumsafstand.
% \ebul
% </latex>

%%
% <latex>
% Til afstandsmåling i denne case er \textbf{chirp-signalet} mest velegnet.
% Der vælges et setup som nedenfor.
% \\
% </latex>

clc; clear all; close all;
rng(0);                     % seed så vi får samme resultater hver gang
setlatexstuff('latex');

%%
%
fs = 44100;         % Samplingsfrekvens [Hz]
Tp = 0.1;           % Pulsbredde [s]
v = 343;            % Lydbølges udbredelseshastighed i luft [m/s]

dR = v * Tp / 2;    % Opløsning for afstandsmåling
disp(['Opløsning til afstandsmåling: ' num2str(dR) ' m.'])

%%
% <latex>
% \section{Simulering af sonar}
% I dette afsnit simuleres en chirp-puls. Den sammenlignes med en ren
% sinus, for at se forskelle i krydskorrelationen og få et indblik i
% støjimmuniteten.
% Chirp-pulsen er en lineært frekevensmoduleret puls, der genereres som
% beskrevet i \cite[s. 414]{manolakis}.
% Frekvensen moduleres op fra \SI{0}{\hertz} til \SI{500}{\hertz} over
% pulsbredden.
% For den rene sinus benyttes \SI{500}{\hertz} til hele pulsen.
% \\
% </latex>

A = 10;             % Amplitude for puls
F1 = 500;           % Signalfrekvens [Hz] (slutfrekvens for chirp)
L = Tp * fs;        % Pulslængde (4410 samples)   
n = (0:L-1);        % Samplevektor (0..4409)

nsq = n.^2;
p_chirp = A*sin(pi* (F1/fs) * (nsq/L) );  % Lineær FM, (Manolakis, s. 414)

p_sin = A*sin(2*pi*F1/fs*n);        % Ren sinus

t_puls = (0:L-1)/fs;                % Tilhørende tidsakse

%%
% <latex>
% Modtagne signaler, hvori ekko skal spores, er \SI{0.5}{s} lange.
% Ekkoet optræder ved $\tau = 0.25$ s, ca. $R=$ \SI{43}{m}.
% Der er additiv gaussisk støj med $\sigma_r=0.1$ (øges senere).
% \\
% </latex>
Tr = 0.5;           % Længde af modtaget signal [s]
Nr = Tr*fs;         % Antal samples i modtaget signal

tau = 0.25;         % Tidsforskydning [s]
n_tau = tau*fs;     % Tilsvarende sample starter ekko (11025)

R = v*tau/2;        % Simuleret afstand [m] (ca. 43 m)
sigma_r = 0.1;      % Std.afv. for støj i optaget signal

rn = randn([1 Nr]);             % Gaussisk støj, genbruges senere
r = sigma_r*rn;                 % Gaussisk støj med ønsket std.afv.
tr = (0:Nr-1)/fs;               % Tilhørende tidsakse

%%
% <latex>
% Begge signaler benytter samme samplede støjvektor. De dæmpede 
% ekkopulser lægges ind svarende til en tidsforskydning på $\tau = 0.25$ s.
% Her inkluderes også dæmpning med $K=R^{-1}$ pga. afstand.
% \\
% </latex>

r_chirp = r;                    % Optaget signal med chirp-puls
r_chirp(1,n_tau:n_tau+L-1) = r_chirp(1,n_tau:n_tau+L-1) + p_chirp/R;

r_sin = r;                      % Optaget signal med sinus-puls
r_sin(1,n_tau:n_tau+L-1) = r_sin(1,n_tau:n_tau+L-1) + p_sin/R;

%%
% <latex>
% Krydskorrelationen beregnes med indre produkter, som beskrevet i 
% teori-afsnittet. \MATLAB s \texttt{xcorr}-funktion kunne også benyttes, 
% denne metode giver bare mere føling med beregningen.
% \\
% </latex>

% Tomme vektorer til resultater af rullende krydskorrelation
c_chirp = zeros([1 length(r_chirp)-length(p_chirp)]);
c_sin = zeros([1 length(r_sin)-length(p_sin)]);

% Lav krydskorrelation for både chirp og sinus
for n=1:length(c_chirp)
    c_chirp(n) = p_chirp*r_chirp(n:n+L-1)';     % Regn indre produkter
    c_sin(n) = p_sin*r_sin(n:n+L-1)';
end

tc = (0:length(c_chirp)-1)/fs;   % Tilhørende tidsakse

%%
% <latex>
% Grafisk sammenligning foretages nedenfor.
% \\
% </latex>

figure();
sgtitle(['Simulering af sonar' newline ...
         '$A=$' num2str(A) ', $R=$' num2str(round(R)) ' [m]' ... 
         ', $\sigma_r=' num2str(sigma_r) '$'], ...
         'Interpreter', 'Latex', 'FontSize', 14);
subplot(321)
plot(t_puls, p_chirp); grid on;
title('Chirp-puls', 'FontSize', 12);
xlabel('Tid [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);

subplot(322)
plot(t_puls, p_sin); grid on;
title('Sinus-puls', 'FontSize', 12);
xlabel('Tid [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);

subplot(323)
plot(tr, r_chirp); grid on;
title('Modtaget signal inkl. chirp-puls og gaussisk', 'FontSize', 12);
xlabel('Tid [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
xlim([0 Tr])

subplot(324)
plot(tr, r_sin); grid on;
title('Modtaget signal inkl. sinus-puls og gaussisk', 'FontSize', 12);
xlabel('Tid [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
xlim([0 Tr])

subplot(325)
plot(tc, c_chirp); grid on;
title('Krydskorr. med chirp-puls', 'FontSize', 12);
xlabel('Tidsforskydning $\tau$ [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
xlim([0 Tr])
ax = gca; ax.YAxis.Exponent = 3;

subplot(326)
plot(tc, c_sin); grid on;
title('Krydskorr. med sinus-puls', 'FontSize', 12);
xlabel('Tidsforskydning $\tau$ [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
xlim([0 Tr])
ax = gca; ax.YAxis.Exponent = 3;

%%
% <latex>
% Figurerene viser, som forventet, at maksimal effekt i krydskorrelationen
% optræder ved $\tau = 0.25$ s ($R=43$ m).
% Den grafiske sammenligning dokumenterer fordelen ved chirp-pulsen 
% (og andre frekvensmodulerede pulser):
% Der sker \textit{puls-kompression} i krydskorrelationen, og al energien
% afsættes over meget kort tid.
% Det skyldes responset af den frekvensmodulerede puls
% i krydskorrelationen (et matched filter). 
% Se fx \cite{radartutorial} eller \cite{wikipulsecompression}.
% Det er, som beskrevet tidligere, fordi krydskorrelationen kun slår ud, 
% når puls og ekko ``aligner'' perfekt.
% \\ \\
% Der er aliasering i figurerne med krydskorrelation. Når der zoomes ind,
% kan det ses, at:
% \sbul
% \item Krydskorrelation af chirp med lagget chirp giver en
% sinc-funktion.
% \item Krydskorrelation af sinus med lagget sinus giver noget,
% der minder om en sinus med trekantet indhyldning.
% \ebul
% </latex>

%%
% <latex>
% \subsection{Simulering med mere støj}
% Fastholdes effekten fra afsenderen ($A=10$) men med faktor 10 højere
% støjniveau, $\sigma_r=1$, fås nedenstående.
% \\
% </latex>

sigma_r = 1.0;       % Std.afv. for støj i optaget signal
r = sigma_r*rn;      % Genbrug samme støjvektor til sammenligning, std.afv.

% Genberegn modtagede signaler
r_chirp = r;                    % Optaget signal med chirp-puls
r_chirp(1,n_tau:n_tau+L-1) = r_chirp(1,n_tau:n_tau+L-1) + p_chirp/R;
r_sin = r;                      % Optaget signal med sinus-puls
r_sin(1,n_tau:n_tau+L-1) = r_sin(1,n_tau:n_tau+L-1) + p_sin/R;

% Genberegn krydskorrelation
for n=1:length(c_chirp)
    c_chirp(n) = p_chirp*r_chirp(n:n+L-1)';     % Regn indre produkter
    c_sin(n) = p_sin*r_sin(n:n+L-1)';
end

% Plot
figure();
sgtitle(['Simulering af sonar' newline ...
         '$A=$' num2str(A) ', $R=$' num2str(round(R)) ' [m]' ... 
         ', $\sigma_r=' num2str(sigma_r) '$'], ...
         'Interpreter', 'Latex', 'FontSize', 14);

subplot(221)
plot(tr, r_chirp); grid on;
title('Modtaget signal inkl. chirp-puls og gaussisk', 'FontSize', 12);
xlabel('Tid [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
xlim([0 Tr])

subplot(222)
plot(tr, r_sin); grid on;
title('Modtaget signal inkl. sinus-puls og gaussisk', 'FontSize', 12);
xlabel('Tid [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
xlim([0 Tr])
     
subplot(223)
plot(tc, c_chirp); grid on;
title('Krydskorr. med chirp-puls', 'FontSize', 12);
xlabel('Tidsforskydning $\tau$ [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
xlim([0 Tr])
ax = gca; ax.YAxis.Exponent = 3;

subplot(224)
plot(tc, c_sin); grid on;
title('Krydskorr. med sinus-puls', 'FontSize', 12);
xlabel('Tidsforskydning $\tau$ [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
xlim([0 Tr])
ax = gca; ax.YAxis.Exponent = 3;

%%
% <latex>
% Figuren viser, at signalet nu indeholder væsentlig støj: I tidsdomænet 
% kan pulsen ikke længere direkte ses for støj.
% Med pulskompression kan afstanden bedømmes præcist selv med væsentlig støj.
% For sinus-pulsen er billedet noget mere ``mudret''.
% \\
% </latex>

%%
% <latex>
% \subsection{Simulering med lavpasfiltrering}
% Som tidligere nævnt, giver en højere frekvens i pulserne generelt bedre 
% performance for ``sonar''-systemet.
% Så sidste del af simuleringen er at indarbejde effekt fra luftens 
% LP-filtrering af ``sonar''-pulserne.
% \\ \\
% Ideen er at få et blik på hvor højt man kan presse puls-frekvensen 
% for de to forskellige sonar-typer givet usikkerhed på luftens knækfrekvens.
% Den kunne jo fx ændre sig med temperatur, luftfugtighed, barometrisk
% tryk, ved forskellige typer nedbør, osv.
% \\ \\
% Antag, at knækfrekvensen i luften ligger omkring $F_1$ men med 10 pct.
% usikkerhed. LP-filteret får så en worst-case knækfrevens på på $0.9 F_1$.
% \\ \\
% Her benyttes \MATLAB s \texttt{fir1}-funktion til at designe et filter
% med vinduesfunktion. Der er valgt et FIR-filter for at undgå ikke-lineær
% fase (har ``atmosfærens'' LP-filter ikke-lineær fase ?).
% \\
% </latex>

fc = F1*0.9;
b_luft = fir1(750, 2*fc/fs);        % LP FIR-filter med 450 Hz knæk

% Lavpas-filtrér ekko-pulserne
p_chirp_lp = filter(b_luft,1,p_chirp);
p_sin_lp = filter(b_luft,1,p_sin);

% Genberegn modtagede signaler
r_chirp_lp = r;                    % Samme std.afv. som før, chirp
r_chirp_lp(1,n_tau:n_tau+L-1) = ...
    r_chirp_lp(1,n_tau:n_tau+L-1) + p_chirp_lp/R;

r_sin_lp = r;                      % Samme std.afv. som før, sinus
r_sin_lp(1,n_tau:n_tau+L-1) = r_sin_lp(1,n_tau:n_tau+L-1) + p_sin_lp/R;

% Genberegn krydskorrelation
for n=1:length(c_chirp)
    c_chirp(n) = p_chirp*r_chirp_lp(n:n+L-1)';     % Regn indre produkter
    c_sin(n) = p_sin*r_sin_lp(n:n+L-1)';
end

% Plot
figure();
sgtitle(['Simulering af sonar' newline ...
         '$A=$' num2str(A) ', $R=$' num2str(round(R)) ' [m]' ... 
         ', $f_c=$' num2str(fc) ' [Hz]' ... 
         ', $\sigma_r=' num2str(sigma_r) '$'], ...
         'Interpreter', 'Latex', 'FontSize', 14);

subplot(321)
plot(t_puls, p_chirp_lp); grid on;
title('LP-filtreret chirp-puls', 'FontSize', 12);
xlabel('Tid [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);

subplot(322)
plot(t_puls, p_sin_lp); grid on;
title('LP-filtreret sinus-puls', 'FontSize', 12);
xlabel('Tid [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
     
subplot(323)
plot(tr, r_chirp_lp); grid on;
title('Modtaget inkl. chirp-puls, gaussisk og LP', 'FontSize', 12);
xlabel('Tid [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
xlim([0 Tr])

subplot(324)
plot(tr, r_sin_lp); grid on;
title('Modtaget inkl. sinus-puls, gaussisk og LP', 'FontSize', 12);
xlabel('Tid [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
xlim([0 Tr])
     
subplot(325)
plot(tc, c_chirp); grid on;
title('Krydskorr. med chirp-puls', 'FontSize', 12);
xlabel('Tidsforskydning $\tau$ [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
xlim([0 Tr])
ax = gca; ax.YAxis.Exponent = 3;

subplot(326)
plot(tc, c_sin); grid on;
title('Krydskorr. med sinus-puls', 'FontSize', 12);
xlabel('Tidsforskydning $\tau$ [s]', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
xlim([0 Tr])
ax = gca; ax.YAxis.Exponent = 3;

%%
% <latex>
% Figuren viser, at den frekvensmodulerede puls stadig præcist detekterer
% afstanden til target.
% \\ \\
% Ikke overraskende går LP-filtrering værst ud over sinus-pulsen, som ikke
% længere kan give et præcist estimat på targets afstand. 
% Den giver i stedet en ``falsk-positiv'' for denne samplede støjvektor.
% Med peak-detektion på sinus-systemet, ville man måle $\tau=0.12$ s, 
% svarende til $R=21$ m. 
% Dvs. en målefejl på \SI{22}{\meter} eller cirka 51 pct. for lavt.
% \\ \\
% Hvis der er usikkerhed omkring eller variationer i knækfrekvensen i 
% bæremediet (her luften), er et frekvensmoduleret signal mere støjimmunt 
% end en ren sinuspuls er.
% </latex>


%%
% <latex>
% \chapter{Konklusion}
% Denne case har illustreret, hvordan digital signalanalyse kan benyttes i
% forbindelse med et sonar-system, der skal måle afstande til et target.
% Det er vist, hvordan forskellige signalparametre har indflydelse på 
% et sonar-systems mulighed for præcist at måle afstande og at kunne skelne
% mellem forskellige targets (afstandsopløsning).
% Der er desuden diskuteret fordele og ulemper ved forskellige signaltyper.
% En række simuleringer er gennemført, med konklusionerne at:
% \sbul
% \item Et frekvensmoduleret signal (fx chirp) udviser puls-kompression, 
% når det korreleres med et ekko af ``sig selv'', hvilket giver høj
% præcision i afstandsmåling.
% \item Selv ved en væsentlig mængde støj er krydskorrelation en stærk
% og robust metode til at finde ét signal i et andet signal.
% \item Et frekvensmoduleret signal er mere støjimmunt end et rent
% sinussignal.
% \item Når der er usikkerhed omkring hvorledes en kanal (her
% luften) vil filtrere et pulset signal, giver et frekvensmoduleret signal
% den bedste / sikreste performance. Fokus er vel ofte på at få maksimal
% performance ud af et ``sonar''-signal, så det vigtigt at kunne presse
% systemet uden at risikere væsentlige fejl.
% \ebul
% Der blev desværre ikke tid til at implementere et sonar-system i hardware 
% (eller rettere: det blev nedprioriteret).
% \\ \\
% Det var en rigtig interessant case, med materiale der har mange 
% interessante anvendelser.
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
% \chapter{Funktioner\label{sec:hjfkt}}
% Der er til projektet benyttet følgende hjælpefunktioner.
% </latex>

%% setlatexstuff
%
function [] = setlatexstuff(intpr)
% Sæt indstillinger til LaTeX layout på figurer: 'Latex' eller 'none'
% Janus Bo Andersen, 2019
    set(groot, 'defaultAxesTickLabelInterpreter',intpr);
    set(groot, 'defaultLegendInterpreter',intpr);
    set(groot, 'defaultTextInterpreter',intpr);
    set(groot, 'defaultGraphplotInterpreter',intpr); 

end

