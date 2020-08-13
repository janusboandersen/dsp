%% E4DSA Case 3 - Midling af sensordata
%%
% <latex>
% \chapter{Indledning}
% Tredje case i E4DSA er behandling og analyse af st�jfyldt data fra en fysisk sensor. 
% I dette tilf�lde en vejecelle, dvs. en transducer fra kraftbelastninger 
% til elektriske signaler. 
% En vejecelle installeres, s� p�virkning er enten fra kompression eller tension.
% P� forsiden vises forskellige typer af vejeceller \cite{loadcells}.
% \\�\\
% Fokus i denne case er at:
% \sbul
% \item Fjerne u�nsket st�j. Dette g�res vha. midlingsfiltre (lavpas).
% \item Kvantificere m�leusikkerhed ved deskriptive statistiske m�l.
% \ebul
% Det er et hyppigt problem, at sensorm�linger er overlejret med st�j.
% Kilderne kan v�re mange:
% \sbul
% \item Processt�j: �ndringer i temperatur, lufttryk, vibrationer i 
% omgivelserne, osv. under optagelse af m�linger.
% \item Instrumentets m�leusikkerhed: Drevet at sensitivitet i den analoge 
% del af sensoren. Ved brug af en vejecelle over l�ngere tid sker 
% desuden et ``drift'' i output over tid \cite[s. 1]{refdes}.
% \item Non-lineariteter og non-ideelle komponenter.
% \item Eletromagnetisk st�j, feltkoblet eller ledningsb�ret: Vil
% forstyrre optagelse af m�linger.
% \item Kvantiseringsst�j i A/D converter: Effektiv outputst�j er
% kombinationen af forst�rkning, samplingsfrekvens og 
% ADC'ens opl�sning \cite[s. 2, fig. 4]{refdes}.
% \ebul
% Reduktion af u�nsket st�j er n�dvendigt for at f� et bedre estimat p�
% underliggende data og variable.
% Kvantificering af usikkerhed i m�linger kan evt. henf�res til forskellige 
% kilder, s�fremt der antages modeller for hhv. signalkomponenter og st�j.
% \\�\\
% Der er yderligere motivation til st�jreduktion, hvis data bruges videre 
% i en regulator eller et feedback-kontrolsystem. 
% D�r vil st�j forringe kontrolkarakteristikken.
% </latex>

%%
% <latex>
% \chapter{Opgave 1: Analyse af inputsignal}
% Inputsignalet er data optaget fra en vejecelle med samplingsfrekvensen 
% \SI{300}{\hertz}. 
% Data er ikke omregnet til en masseenhed, dvs. data er de r� ADC-koder.
% Vejecellen p�virkes med et stepinput: Belastes med en masse
% p� \SI{1}{\kilo\gram}. R� m�ledata vises i figuren nedenfor.
% \\
% </latex>

%%
clc; clear all; close all;
setlatexstuff('latex');
load('vejecelle_data.mat');
x = vejecelle_data;

%%
%
N = length(x);
t_vec = (0:N-1)/fs;
figure();
plot(t_vec, x); grid on;
xlabel('Tid, $t$ [s]', 'FontSize', 12);
ylabel('ADC-kode', 'FontSize', 12);
title('Steprespons for vejecelle', 'FontSize', 14);

%%
% <latex>
% Figuren viser, at kraftp�virkningen sker ved ca. \SI{3.5}{\second}.
% Ubelastet tilstand er ca. ADC-koden 1100.
% Vi ved ikke noget om kalibrering af vejecelle inden m�ling, s� det
% antages, at dette niveau er \SI{0}{\kilo\gram}.
% Belastet tilstand er ca. ADC-koden 1400, svarende til \SI{1}{\kilo\gram}.
% Der er v�sentlig st�j i data.
% Rise-time fra zero-state tager ca. \SI{70}{\milli\second}.
% Pga. st�j kan evt. h�jere ordens indsvingning efter stepinput ikke ses.
% </latex>

%%
% <latex>
% \section{Adskilning af tilstande}
% Her implementeres en kort algoritme til at detektere niveauskifte.
% Antag, at stepinput sker ved tiden $t=t^*$, svarende til $n=n^*$.
% Antag at st�jen (m�lefejl) er normalfordelt som 
% $\epsilon(n) \sim i.i.d. N(0, \sigma)$.
% Alts� uafh�ngige, identisk fordelte (i.i.d.) stokastiske variable med 
% varianshomogenitet\footnote{D.s.s. homoskedasticitet, 
% spredningen er uafh�ngig af $n$ og $\mu_i$.}. 
% Antag, at st�jen er additiv.
% Antag ogs�, at et st�jfrit signal fra ADC'en ville v�re ren DC.
% S� er $x(n) =\mu_0 + \epsilon(n)$ for $n=0 \ldots n^*$ og
% $x(n) =\mu_1 + \epsilon(n)$ for $n=n^*+1 \ldots N-1$.
% $\mu_0$ og $\mu_1$ er DC-amplituder i hhv. zero-state og med belastning.
% S� l�nge systemet er i zero-state skal 99 pct. af alle observationer
% ligge i intervallet $\hat{\mu}_0 \pm z_{\alpha/2} \cdot \hat{\sigma}_n$, 
% hvor fx $z_{1\%/2}=2.58$ er 99.5 pct.-fraktilen i 
% standardnormal-fordelingen\footnote{Her burde man have
% brugt den lidt bredere T-fordeling, fordi vi bruger estimat p� b�de
% middelv�rdi $\hat{\mu}$ og varians $\hat{\sigma}^2$.}.  
% N�r mere end et par observationer i tr�k er uden for intervallet, s�
% m� systemets tilstand v�re skiftet.
% \\�\\
% $\mu_0$, $\mu_1$ og $\sigma$ estimeres vha. glidende gennemsnit.
% Den samlede model kan skrives:
% $$ x(n) = \mu_0(u(n)-u(n-n^*)) + \mu_1 u(n-n^*) + \epsilon(n) $$
% Hvor $u(n)$ er stepinput, $n^*$ er det ukendte steptidspunkt og 
% $\epsilon \sim N(0, \sigma)$ er gaussisk st�j.
% \\
% </latex>

MA_len_bk = 100;                   % benyt 100 historiske obs. til MA og SD
MA_len_fw = 0;                     % ingen fremtidige obs.
percentile = 1.0 - 1.0/100/2;      % 99.5 pct. fraktil (0.5 pct hver side)
sd = movstd(x, [MA_len_bk MA_len_fw]);  % beregn sigma(n)
ma = movmean(x, [MA_len_bk MA_len_fw]); % beregn estimat p� A_0 el. A_1
ub = ma + norminv(percentile)*sd;       % Statistisk �vre gr�nse
lb = ma - norminv(percentile)*sd;       % Statistisk nedre gr�nse
t_trans = 0.1;                      % Ansl�et transienttid [s]


num_above = 3;                      % N�r 3 obs. i tr�k ligger over => step
tstar = find((movmean((x > ub), [num_above 0]) >= 1), 1, 'first') / fs;

figure();
plot(t_vec, x); grid on; hold on;
plot(t_vec, ub, 'k:', t_vec, lb, 'k:');
plot(t_vec, ma, 'k-');
xline(tstar-t_trans/2, 'r'); xline(tstar+t_trans/2, 'r');
hold off;
xlabel('Tid, $t$ [s]', 'FontSize', 12);
ylabel('ADC-kode', 'FontSize', 12);
title('Detektion af niveauskifte ved belasting', 'FontSize', 14);
%%
% <latex>
% Figuren viser, at zero-state er t.v. for f�rste vertikale r�de markering.
% Belastet tilstand (steady state) er t.h. for anden vertikale r�de markering.
% Mellem de r�de markeringer er transientresponset.
% Denne opdeling benyttes i de f�lgende sp�rgsm�l.
% \\ \\
% Figuren bekr�fter ogs�, at spredningen tiln�rmet er homoskedastisk
% (ekskl. transientrespons).
% \\
% </latex>

N0end = (tstar-t_trans/2)*fs;       % 50 ms p� hver side af t*
N1begin = (tstar+t_trans/2)*fs;
x0 = x(1:N0end);                    % dataserie for ubelastet vejecelle
x1 = x(N1begin:end);                %  -- || --      belastet  -- || -- 

%%
% <latex>
% \section{Q1.1. Deskriptiv statistik for de to tilstande}
% Deskriptiv statistik regnes nedenfor.
% Disse funktioner benytter stikpr�ve-beregning (Bessel-justering, 
% division med $N-1$ i stedet for $N$) for at f� en unbiased estimator.
% Estimater og estimatorer er\footnote{Benyttet notation er s�ledes: 
% En estimator, fx $\bar{x}$ eller $s^2$, er en matematisk funktion af en
% eller flere stokastiske variabler til at bestemme en ukendt parameter.
% Givet en fordeling af stokastiske inputvariable, findes en 
% sandsynlighedsfordeling for estimatoren. En estimator kan v�re unbiased
% (middelret) eller biased.
% Et estimat, fx $\hat{\mu}$ eller $\hat{\sigma}^2$, er en enkelt 
% realisering p� en tiln�rmelse til den sande parameterv�rdi. Givet et s�t
% observationer er estimatet deterministisk. Indhentes et nyt s�t 
% observationer f�s et nyt, muligvis anderledes, estimat. Osv.}:
% \sbul
% \item Middelv�rdi, $\hat{\mu}$: $\bar{x}=\frac{\sum_{n=0}^{N-1} x(n)}{N-1}$.
% \item Varians, $\hat{\sigma}^2$: $s^2 = \frac{\sum_{n=0}^{N-1} (x(n)-\bar{x})^2}{N-1}$.
% Dvs. gennemsnitlig effekt i st�jen.
% \item Standardafvigelse (spredning), $\hat{\sigma}$: $s = \sqrt{s^2}$.
% Dvs. RMS-v�rdi for st�jen.
% \ebul
% Beregninger er foretaget med \MATLAB s funktioner.
% \\
% </latex>

means = [round(mean(x0)) round(mean(x1))];      % mu_hat
stddevs = [std(x0) std(x1)];                    % sigma_hat
vars = stddevs.^2;                              % sigma_hat^2
T = table(means', stddevs', vars', [length(x0) length(x1)]');
T.Properties.RowNames = {'x_0', 'x_1'};
T.Properties.VariableNames = {'Mid', 'Std', 'Var', 'N'};
disp(T)

%%
% <latex>
% Tabellen viser middelv�rdier for ADC-koderne i de to tilstande, svarende
% til belastning med hhv. \SI{0}{\kilo\gram} og \SI{1}{\kilo\gram}.
% Det giver ingen mening at have decimaler p� disse v�rdier (ADC-kode er
% heltal).
% Tabellen viser ogs�, at standardafvigelserne er tiln�rmelsesvis ens.
% Det er alts� rimeligt fortsat at antage, at st�jen i de to dele af 
% signalet er fordelt med samme spredningsparameter $\sigma$.
% Man kunne evt. udf�re en hypotesetest (F-test) for at teste det 
% statistisk, men det er uden for scope her.
% </latex>
%%
% <latex>
% \section{Q1.2. Histogrammer}
% Det er rimeligt at arbejde videre med antagelsen, 
% at modellerne er $x_0(n) = \mu_0 + \epsilon(n)$ og 
% $x_1(n) = \mu_1 + \epsilon(n)$, hvor $\epsilon \sim N(0, \sigma)$. 
% Dvs. vi har to station�re stokastiske processer 
% $x_i \sim N(\mu_i, \sigma)$, hvor $i=\{0,1\}$ angiver enten zero-state
% eller belastet tilstand.
% \\�\\
% Det betyder, at hele m�leusikkerheden betragtes udelukkende som station�r
% gaussisk st�j nu. Det er naturligvis ikke helt sandt\footnote{Det er jo 
% summen af kvantiseringsfejl, instrumentets m�lefejl, processt�j, osv.}.
% Nedenfor unders�ges antagelsen om normalfordeling n�rmere ved at 
% plotte histogrammer samt fittede t�thedsfunktioner, 
% under antagelsen at data er normalfordelt.
% Observerede fejlled, $\hat{\epsilon}(n)=x(n)-\hat{\mu}$, 
% normaliseres til $z(n)=\frac{\hat{\epsilon}(n)}{\hat{\sigma}}$ og 
% plottes imod en standardnormalfordeling.
% Det er igen en tilsnigelse, for ADC-koderne er heltalsv�rdier.
% \\
% </latex>

figure();
sgtitle('Fordeling af observationer', 'FontSize', 14);
subplot(221)
histfit(x0);
title('Ubelastet vejecelle (0 kg)', 'FontSize', 12);
xlabel('ADC-kode', 'FontSize', 10);
ylabel('Antal og forv. densitet', 'FontSize', 10);
subplot(222)
histfit(x1);
title('Belastet vejecelle (1 kg)', 'FontSize', 12);
xlabel('ADC-kode', 'FontSize', 10);
ylabel('Antal og forv. densitet', 'FontSize', 10);
subplot(223)
histfit( (x0-means(1))/stddevs(1) );
title('Gaussisk fejlled, normaliseret (ubelastet)', 'FontSize', 12);
xlabel('Norm. fejlled', 'FontSize', 10);
ylabel('Antal og forv. densitet', 'FontSize', 10);
subplot(224)
histfit( (x1-means(2))/stddevs(2) );
title('Gaussisk fejlled, normaliseret (belastet)', 'FontSize', 12);
xlabel('Norm. fejlled', 'FontSize', 10);
ylabel('Antal og forv. densitet', 'FontSize', 10);

%%
% <latex>
% Det ser tiln�rmelsesvist normalfordelt ud.
% For at f� en lidt mere robust konklusion, suppleres ovenst�ende figurer
% med QQ-plots, dvs. fordelingssammenligning af normaliserede observationer
% ($ z(n) = \frac{x(n)-\hat{\mu}}{\hat{\sigma}} $) versus forventede fraktiler 
% givet en standardnormalfordeling.
% Ved en perfekt normalfordeling af data, ville alle punkter i plottet
% ligge p� en ret linje, oven i den r�de linje.
% \\
% </latex>

figure();
sgtitle('Fordeling af fejlled versus standardnormalfordeling', ...
    'Interpreter', 'Latex', 'FontSize', 14);
subplot(211)
qqplot((x0-means(1))/stddevs(1));
title('QQ-plot fejlled (ubelastet)', 'FontSize', 12);
xlabel('Kvantiler $N(0,1)$', 'FontSize', 12);
ylabel('Kvantiler $\hat{\epsilon}$ (ubelastet)', 'FontSize', 12);
subplot(212)
qqplot((x1-means(2))/stddevs(2));
title('QQ-plot fejlled (belastet)', 'FontSize', 12);
xlabel('Kvantiler $N(0,1)$', 'FontSize', 12);
ylabel('Kvantiler $\hat{\epsilon}$ (belastet)', 'FontSize', 12);

%%
% <latex>
% QQ-plots bekr�fter, hvad der kunne anes i histogrammer:
% Fordelingen af m�lefejl har ``fede haler'', dvs. en bredere
% fordeling med flere observationer langt fra middelv�rdien, end man ville 
% forvente givet normalfordelingen.
% Dog viser b�de histogrammer og QQ-plots, at fordelingen stadig kan 
% betragtes som tiln�rmelsesvist normal.
% S� det er rimeligt at konkludere, at st�jled (fejlled) er 
% tiln�rmelsesvist normalfordelte, og at de samlede signaler er liges�. 
% Vi kan derfor godt, uden at beg� store regnefejl, benytte antagelsen, 
% at m�leusikkerheder p� m�linger foretaget med vejecellen vil v�re 
% normalfordelte i b�de belastet og ubelastet tilstand.
% \\�\\
% Hvis vi havde behov for at v�re sikre, ville det give mening at
% foretage et hypotesetest, fx vha. et Kruskal-Wallis-test.
% </latex>

%%
% <latex>
% \section{Q1.3. Effektspektra (spektralt�thed) for hvid st�j}
% Hvid st�j forst�es som et signal, der har samme intensitet af alle
% frekvenser, eller mere pr�cist: Hvid st�j har konstant spektralt�thed (PSD)
% for alle frekvenser, praktisk set dog kun inden for en vis b�ndbredde.
% De fejlled $\epsilon \sim i.i.d. N(0,\sigma)$ vi har analyseret tidligere
% er en type hvid st�j \cite{wikiwhite}: Additiv gaussisk hvid st�j.
% \\�\\
% Spektral estimation benyttes til at estimere et effektspektrum for en 
% station�r stokastisk proces, der per definition har en periode p� $T \to \infty$.
% Det giver et estimat p� gennemsnitlig effekt over et frekvensb�nd.
% Principielt divergerer Fourier-integralet for en uendelig lang hvid
% st�j-proces ($T \to \infty$)\footnote{Additiv gaussisk hvid st�j 
% har uendelig energi over intervallet $-\infty$ til $+\infty$, 
% s� er ikke i $L^2$, dvs. 
% $\int_{t=-\infty}^{\infty} |f(t)|^2 dt$ divergerer og eksisterer ikke.
% I diskret tid vil det sige, at $\sum_{n=-\infty}^{\infty} |f(n)|^2$ er
% uendelig.}.  
% Se estimation g�res med gentagen sampling af udsnit med finit l�ngde 
% $T$ fra den stokastiske proces. 
% Der bruges s� en estimator, som \textit{vil} eksistere i gr�nsen 
% $T \to \infty$:
% \sbul
% \item For en enkelt samplingperiode regnes: $\frac{|X_T(f)|^2}{T}$
% \item Som middelv�rdi (forventet v�rdi) efter gentagen sampling:
% $\text{E}\{ \frac{|X_T(f)|^2}{T} \}$
% \item I gr�nsen $T \to \infty$: $S_{xx}(f)=\text{PSD}_{xx}(f) = \lim_{T \to \infty} \text{E}\{ \frac{|X_T(f)|^2}{T} \}$
% \item I diskret tid med DFT \cite{wikipsd}: $S_{xx}(f) = \frac{(\Delta t)^2}{T}
% |X(f)|^2$. Med $\Delta t = \frac{1}{f_s}$ og $T = N \Delta t$, bliver
% ensidet skalerinsfaktor $\frac{2}{N \cdot f_s}$.
% \ebul
% Det er et avanceret emne. Her estimeres med kun
% en enkelt sampleperiode, inspireret af \cite{psdestimates}. Alternativt
% kunne man have delt den tilg�ngelige data op i flere segmenter
% og lavet gentagen estimation, som ved STFT.
% \\�\\
% DC-komponenten i sensordata er her uinteressant og tr�kkes ud. 
% Dvs. vi kigger kun p� spektralindhold i fejlled: 
% $\hat{\epsilon}_i(n) = x_i(n) - \hat{\mu}_i$, hvor $i=\{0,1\}$ som 
% tidligere angiver enten zero-state eller belastet tilstand.
% \\ \\
% Med samplingsfrekvens p� \SI{300}{\hertz} tillader samplingss�tningen at 
% kigge p� spektral densitet op til Nyquist-frekvensen \SI{150}{\hertz}.
% \\
% </latex>

e0 = x0 - means(1);     % fejlled for m�linger i ubelastet tilstand
e1 = x1 - means(2);     %      -- || --           belastet tilstand

Nfft = 2^nextpow2( max( length(e0), length(e1) ));     % Zero-padding
psd_scale = 2/(fs*Nfft);             % Skalering for at approximere PSD
f_vec = (0:Nfft-1)*(fs/Nfft);                          % Frekvensvektor

E0 = fft(e0, Nfft);     % Beregn FFT'er (zero-padded)
E1 = fft(e1, Nfft);

E0S = psd_scale * (E0 .* conj(E0));    % Effektspektrum og skalering
E1S = psd_scale * (E1 .* conj(E1));   

figure();
sgtitle('Estimeret spektral densitet for fejlled', 'FontSize', 14);
subplot(211)
plot(f_vec, 10*log10(E0S) );
xlim([0 fs/2]); ylim([-50 20]); grid on;
title('Ubelastet vejecelle', 'FontSize', 12);
xlabel('Frekvens $f$ [Hz]', 'FontSize', 12);
ylabel('Effekt/frekvens [dB/Hz]', 'FontSize', 12);
subplot(212)
plot(f_vec, 10*log10(E1S) );
xlim([0 fs/2]); ylim([-50 20]); grid on;
title('Belastet vejecelle', 'FontSize', 12);
xlabel('Frekvens $f$ [Hz]', 'FontSize', 12);
ylabel('Effekt/frekvens [dB/Hz]', 'FontSize', 12);

%%
% <latex>
% Figuren viser, at spektralt�theden er tiln�rmelsesvis konstant for 
% alle frekvenser. Det er ensbetydende med, at st�jen er hvid st�j.
% Denne konklusion g�lder for b�de ubelastet og belastet tilstand.
% Det er frekvensdom�nets sidestykke til at vi tidligere erkl�rede
% m�lefejlene for $i.i.d. N(0, \sigma)$.
% </latex>

%%
% <latex>
% \section{Q1.4. ADC-opl�sning}
% Frekvensopl�sning i en ADC (eller DAC) afg�res af v�rdiomr�de ift.
% antal niveauer i enkodering af I/O sp�nding.
% For en N-bit ADC er opl�sningen $\frac{V_{max}-V_{min}}{2^N}$ 
% \cite[12-7, s. 634]{lyons}.
% \\�\\
% Vi kender ikke v�rdiomr�det for ADC'en og ej heller antallet af bits. 
% Men, vi ved hvor mange niveauer i ADC-kode, der kr�ves til at d�kke 
% intervallet fra \SI{0}{kg} til \SI{1}{kg}. Dvs. vi kan beregne
% opl�sningen i gram ved:
% $$ \text{resolution} = \frac{\Delta \text{masse i [g]}}{\Delta \text{ADC-kode}} $$
% \\
% </latex>

d_mass = 1000 - 0;                              % gram [g]
d_ADC_niv = round(means(2)) - round(means(1));  % 1406 - 1106 = 300
resolution = round(d_mass / d_ADC_niv,2);       % 3.33 g/niv.

disp([ num2str(d_ADC_niv) ' ADC-niv. ml. 0 [g] og 1000 [g]' newline ...
      '=> afstand ml. bit-niv. ' num2str(resolution) ' [g/niv.]' ]);

%%
% <latex>
% Givet dette resultat, er v�rdien af LSB i ADC'en \SI{3.33}{g}. 
% Hvis vi antager, at det er en 16-bit line�r ADC, kan det fulde 
% v�rdiomr�de estimeres ved en line�r ekstrapolation med lidt algebra,
% hvor $\lambda$ er ADC-kode og $f(\lambda$) er v�gt i gram:
% $ f(\lambda) - f(\lambda_0) = b_1 (\lambda-\lambda_0)$, som ogs� skrives
% $ f(\lambda) = b_0 + b_1 \lambda $, med $b_0 = f(\lambda_0) - b_1 \lambda_0$.
% H�ldningen $b_1$ er opl�sningen, vi regnede ovenfor.
% \\
% </latex>

lam_0 = round(means(1));        % 1106 (ADC-kode, ubelastet)
f_lam_0 = 0;                    % 0.0 [g]
b_1 = resolution;               % h�ldning (opl�sning)
b_0 = f_lam_0 - b_1*lam_0;      % sk�ring
lam_max = 2^16 - 1;             % maks. ADC-kode (65535)
lam_min = 0;                    % min. ADC-kode (0)

f_max = b_0 + b_1*lam_max;
f_min = b_0 + b_1*lam_min;

disp(['Fuld ADC-bitbredde svarer til ' num2str(round(f_min)) ... 
     ' [g] til ' num2str(round(f_max)) ' [g].' ]);
 
%%
% <latex>
% S� under antagelsen, at strain-gauge i vejecellen er line�r i hele
% intervallet mellem \SI{-3.6}{\kilo\gram} og \SI{214.5}{\kilo\gram}, s�
% svarer vejecellens funktionsomr�de til en udvidet personv�gt :)
% Selvom en strain-gauge sikkert ogs� virker ved negativ kraftp�virkning,
% s� giver det umiddelbart kun mening at have det negative interval, s� der
% er noget ``spillerum'' til digitalt enten at kalibrere vejecellen til 
% \SI{0.0}{\kilo\gram} eller s�tte ``tare''.
% </latex>

%%
% <latex>
% \chapter{Opgave 2: Design af midlingsfilter}
% For at reducere st�jen i signalet fra vejecellen, 
% dvs. opn� et bedre estimat p� den sande m�lev�rdi, eksperimenteres her 
% med midlingsfiltre (MA-filtre).
% Som set ovenfor, kan et glidende gennemsnit benyttes som en rullende
% estimator p� en middelv�rdi jf. de store tals lov, da $\bar{x}$
% vil konvergere mod $\mu$.
% \\ \\
% Ved udtagning af $N$ stikpr�ver af en normalfordelt stokastisk variabel 
% med \textit{ukendt varians}, som er tilf�ldet for $x$, 
% bruges den centrale gr�nsev�rdis�tning til at opstille et 
% $1-\alpha$-konfidensinterval for den sande middelv�rdi $\mu$.
% Med sikkerhed p� $1-\alpha$ kan siges, at parameteren er 
% indeholdt i f�lgende interval \cite[s. 90]{notesamling}:
% $$\mu = \bar{x} \pm t_{N-1, \alpha/2} \cdot \frac{s}{\sqrt{N}}$$
% Hvor $s$ er estimator p� standardafvigelsen for $x$, 
% $\frac{s}{\sqrt{N}}$ er standardfejlen, dvs. std.afv. p� $\hat{\mu}$ og 
% $t_{N-1, \alpha/2}$ er en to-sidet fraktil fra T-fordelingen med 
% $N-1$ frihedsgrader.
% \\�\\
% Det v�sentlige her er, at for $N \to \infty$ konvergerer
% usikkerheden p� estimatet mod $0$.
% Dvs. variansen p� estimatet konvergerer mod $0$.
% Jo l�ngere vi laver MA-filteret, jo sikrere et estimat f�r vi.
% Formuleret anderledes; Givet inputvarians p� data ind i filteret p� 
% $\text{var}(x) = \hat{\sigma}_{\text{input}}^2$, 
% s� bliver variansen p� output fra filteret:
% $$\text{var}(\hat{\mu}) = \hat{\sigma}_{\text{output}}^2 = \frac{\hat{\sigma}_{\text{input}}^2}{N}$$
% Et MA(100)-filter ville fx teoretisk give 100 gange d�mpning af st�jens
% AC-effekt.
% \\�\\
% Omkostningen er l�ngere indsvingningstid grundet flere delays.
% Transientrespons er f�rst ``slut'', n�r filterets delay line er fyldt op
% med \textit{aktuelle} v�rdier. S� for et $\text{MA}(N)$-filter er
% transientresponset $N-1$ samples langt,
% svarende til $t_{\text{trans}} = \frac{N-1}{f_s}$.
% </latex>

%%
% <latex>
% \section{Q2.1. Forskellige midlingsfiltre}
% Nedenfor opstilles FIR (ikke-rekursive) midlingsfiltre med l�ngderne
% $N=10$, $N=50$ og $N=100$.
% \\�\\
% Filtrene designes i tidsdom�net via impulsresponset, dvs. 
% koefficienterne i foldningssummen for $\text{MA}(N)$:
% $$y_{\text{MA}(N)}(n)=\frac{1}{N} \sum_{k=0}^{N-1} x(n-k)$$
% Typisk vil $x(n)$-v�rdier med negativt indeks udg� (erstattes med nul),
% hvilket giver en meget markant indsvingning. 
% \MATLAB s \texttt{movmean}-funktion justerer i stedet filterl�ngden 
% fra $0$ til $N$, som tilg�ngelige samples stiger. 
% Det giver en mindre tydelig/stejl indsvingning.
% \\ \\
% Filtrering foretages p� data fra belastet vejecelle, $x_1(n)$ for at
% f� estimaterne $\hat{\mu}_1$ og $\hat{\sigma}^2$.
% \\
% </latex>

h_MA10 = ones([1 10])/10;               % MA(10)
h_MA50 = ones([1 50])/50;               % MA(50)
h_MA100 = ones([1 100])/100;            % MA(100)

y_MA10 = filter(h_MA10, 1, x1);         % Filtrering af x1       
y_MA50 = filter(h_MA50, 1, x1);
y_MA100 = filter(h_MA100, 1, x1);

N = length(x1);
t_vec = (0:N-1)/fs;

f = figure();
sgtitle('Sammenligning af MA-filtre', 'FontSize', 14);
s1 = subplot(211);
p1 = plot(t_vec, y_MA10, 'Color', [81, 45, 168]/255, 'LineWidth', 2);
grid on; hold on;
p2 = plot(t_vec, y_MA50, 'Color', [76, 175, 80]/255, 'LineWidth', 2);
p3 = plot(t_vec, y_MA100, 'Color', [231, 76, 60]/255, 'LineWidth', 1);
hold off;
xlim([0 1]);
legend({'MA(10)', 'MA(50)', 'MA(100)'}, 'Location', 'southeast');
title('Sammenligning af transienttid', 'FontSize', 12);
xlabel('Tid $t$ [s]', 'FontSize', 12);
ylabel('ADC-kode', 'FontSize', 12);

s2 = subplot(212);
copyobj([p3 p2 p1], s2);
grid on; box on; xlim([0.33 5]);
legend({'MA(10)', 'MA(50)', 'MA(100)'}, 'Location', 'southeast');
title('Sammenligning af variabilitet', 'FontSize', 12);
xlabel('Tid $t$ [s]', 'FontSize', 12);
ylabel('ADC-kode', 'FontSize', 12);

%%
% <latex>
% F�rste figur viser tydeligt den v�sentlige forskel i indsvingningstid for
% forskellige filterl�ngder. Anden figur viser reduktion i
% variabilitet for l�ngere MA-filtre, som forventet.
% \\�\\
% Det ses p� figuren, at der efter ca. \SI{4}{\second} er en l�ngerevarende
% sekvens af outliers. 
% Disse punkter er tydelige outliers ift. standardnormalfordelingen, 
% s� de skyldes sandsynligvis ikke normal m�lefejl / st�j.
% Det kunne skyldes ber�ring af vejecellen. Denne data fjernes i de videre 
% sammenligninger.
% \\ \\
% For at lave en fair sammenligning af filtrenes evne til at reducere st�j,
% regnes standardafvigelser efter fuldendt indsvingning for det 
% langsommeste filter, MA(100), dvs. fra $n=100$, $t=0.33$.
% \\
% </latex>

nb = 100;   % n_begin, fuldendt indsving., n=Filterl�ngde => t=n/fs=0.33
ne = 1200;  % n_end, t=4.0 => n=t*fs=1200    
bm = var(x1(nb:ne));   % ufiltreret benchmark for effekt i st�j

% Regn varians (effekt) af st�j i filtrerede signaler
var_errs = [var(y_MA10(nb:ne)), var(y_MA50(nb:ne)), var(y_MA100(nb:ne))];
       
% Regn reduktion af effekt (variansreduktions-faktor)
err_red = bm ./ var_errs;

% Reduktion i dB
err_red_dB = 10*log10(err_red);

% Forventede reduktioner
err_red_exp = [10 50 100];
err_red_exp_dB = 10*log10(err_red_exp);

rows = {'MA(10)', 'MA(50)', 'MA(100)'}';
columns = {'Varians', 'Eff_reduk', 'Forv_reduk', 'Reduk_dB', 'Forv_dB'};
T = table(var_errs', err_red', err_red_exp', ...
          err_red_dB', err_red_exp_dB');
T.Properties.RowNames = rows;
T.Properties.VariableNames = columns;
disp(T)

%%
% <latex>
% Tabellen viser, at filtrene tiln�rmet giver den teoretisk forventede
% reduktion i st�jeffekt for MA(10) og MA(50). Det er ikke helt tilf�ldet
% for MA(100). Det skyldes nok bl.a. outlieren ved omkring
% \SI{2.8}{\second}, der jo relativt set p�virker MA(100)-filteret i
% l�ngere tid end de to andre filtre.
% </latex>

%%
% <latex>
% \section{Q2.2. Maksimal indsvingningstid}
% Som n�vnt ovenfor er indsvingningstid for et $N$-tap FIR-filter 
% givet ved $t_{\text{trans}} = \frac{N-1}{f_s}$.
% Et muligt krav til maksimaltid er \SI{100}{\milli\second}.
% S� for $t_{\text{trans, max}} = 0.1$ l�ses for $N$:
% \\
% </latex>

t_transmax = 0.1;               % 100 ms
N_max = t_transmax * fs + 1;    % Maks. antal tappe

disp(['Maksimalt antal tappe for at overholde maks. transientrespons: ' ...
       num2str(N_max) '.']);

%%
% <latex>
% Dette resultat stemmer fint overens med figuren, da $N=31$ ligger ca. i
% midtpunktet mellem MA(10) og MA(50), og midtpunktet af deres transienttid
% er omkring \SI{0.1}{\second}.
% \\�\\
% Man kunne ogs� implementere filteret rekursivt, s� det f�r
% differensligningen
% $$y(n)=\frac{1}{N}(x(n) - x(n-N)) + y(n-1)$$
% Indsvingningstiden bliver naturligvis den samme, 
% fordi der stadig kr�ves $N$ delays for at holde $x(n-N)$.
% </latex>

%%
% <latex>
% \section{Q2.3. Eksponentielt midlingsfilter}
% Man kan bruge et eksponentielt midlingsfilter (IIR) i stedet. Det er
% rekursivt.
% Fordelene er, at karakteristikken nemt kan justeres i real-tid, 
% og at filtrering kr�ver f�rre beregninger og f�rre memory-elementer.
% Differensligningen er
% $$y(n) = \alpha x(n) + (1-\alpha) y(n-1)$$
% Hvor $0 < \alpha < 1$.
% Overf�ringsfunktionen er \cite[11-33, s. 612]{lyons}
% $$H(z) = \frac{\alpha}{1-(1-\alpha)z^{-1}}$$
% Det kan vises, at d�mpning af st�jeffekten f�lger \cite[11-29, s. 610]{lyons}
% $$\frac{ \hat{\sigma}_{\text{output}}^2 }{ \hat{\sigma}_{\text{input}}^2 } = \frac{\alpha}{2-\alpha}$$
% S� en given v�rdi af $\alpha$ giver f�lgende faktor st�jreduktion, $R$:
% $$R = \frac{2-\alpha}{\alpha}$$
% Tilsvarende, givet en �nsket d�mpning af st�j med faktor $R$, kan $\alpha$ findes
% \cite[11-30, s. 611]{lyons}:
% $$\alpha = \frac{2}{R+1}$$
% Hvis man vil have hurtig indsvingning kan man jo starte med $\alpha$ t�t
% p� 1. Gradvist kan st�jd�mpning s� �ges ved at reducere $\alpha$.
% \\�\\
% Et MA(100)-FIR-filter, der teoretisk d�mper st�j med faktor $R=100$, 
% kan emuleres som f�lger:
% \\
% </latex>
R = 100;
alpha = 2/(R+1);          % Alpha: st�jreduktion som et MA(100) FIR

% Overf�ringsfunktion
b = alpha;
a = [1 -(1-alpha)];

y_exp = filter(b,a,x);      % Filtrering af hele signalet, inkl. steps
y_MA100 = filter(h_MA100, 1, x);

N = length(x);              % Hele signall�ngden
t_vec = (0:N-1)/fs;

figure();
plot(t_vec, x); grid on; hold on;
plot(t_vec, y_MA100, 'Color', [230, 126, 34]/255, 'LineWidth', 3);
plot(t_vec, y_exp, 'Color', [88, 214, 141]/255, 'LineWidth', 2);
xline(tstar-t_trans/2, 'r'); xline(tstar+t_trans/2, 'r');
hold off;
xlabel('Tid, $t$ [s]', 'FontSize', 12);
ylabel('ADC-kode', 'FontSize', 12);
tit = 'Eksponentielt midlingsfilter, $\alpha=0.02 \sim$ MA(100)';
title(tit, 'Interpreter', 'latex', 'FontSize', 14);
legend({'Ufiltreret ADC-kode', 'MA(100)', 'Eksponentiel midling'}, ...
    'Location', 'east');

%%
% <latex>
% Figuren viser, at det nye filter i hastighed er langsommere end MA(100).
% Den rigtige sammenligning er nok p� stigetid, fx. fra 10 pct. til 90 pct. af steph�jden.
% Det langsomme repsons er fordi $\alpha$ er sat s� lavt.
% \\ \\
% Den anden vigtige del af testen er selvf�lgelig p� st�jreduktion.
% Samme metode benyttes som ved MA-filtrene.
% Grundet at eksponential-filteret er langsommere, forskydes
% starttidspunktet for testen. 
% Hvis dette ikke g�res, har eksponentialfilteret en meget ringere
% gennemsnitlig d�mpning af effekt fra st�j (vi regner jo varians p� en del
% transientresponset s�).
% \\
% </latex>

nb = 250;
bm = var(x1(nb:ne));            % Genberegn benchmark

% Genberegn filtrering p� kun x1
y_exp100 = filter(b,a,x1);
y_MA100 = filter(h_MA100, 1, x1);

% Genberegn med R=10
R = 10; alpha = 2/(R+1);
b10 = alpha; a10 = [1 -(1-alpha)];

y_exp10 = filter(b10,a10,x1);
y_MA10 = filter(h_MA10, 1, x1);

% Sammenlign!
var_errs = [var(y_exp100(nb:ne)), var(y_MA100(nb:ne)) , ...
            var(y_exp10(nb:ne)), var(y_MA10(nb:ne))];

err_red = bm ./ var_errs;
err_red_dB = 10*log10(err_red);
err_red_exp = [100 100 10 10];
err_red_exp_dB = 10*log10(err_red_exp);

columns = {'Varians', 'Eff_reduk', 'Forv_reduk', 'Reduk_dB', 'Forv_dB'};
T = table(var_errs', err_red', err_red_exp', ...
          err_red_dB', err_red_exp_dB');
T.Properties.RowNames = {'exp(a=0.02)', 'MA(100)', 'exp(a=0.18)', 'MA(10)'};
T.Properties.VariableNames = columns;
disp(T)

%%
% <latex>
% Tabellen viser, at filtrene under ``steady state'' fungerer nogenlunde
% som forventet.
% St�jd�mpningen for det f�rste eksponentielle midlingsfilter er 
% marginalt d�rligere end sammenligneligt MA-filter, 
% grundet det uendelige impulsrespons.
% Samme udfordring som f�r ses, hvor de l�ngere filtre p�virkes 
% relativt mere af enkelte outliers. Det er v�rst for IIR-filteret.
% \\�\\
% Der kan allerede drages tre konklusioner om denne filtertype:
% \sbul
% \item Prisen for f�rre beregninger og memory-elementer er et
% langsommere filter og marginalt d�rligere st�jd�mpning.
% \item Et eksponentielt filter (IIR) er mere f�lsomt over for outliers end
% et FIR-filter, fordi det principielt p�virkes uendeligt af impulser.
% Jo kraftigere outliers, jo v�rre. Jo lavere $\alpha$, jo l�ngere tid er
% effekten fra en outlier om at ``d� ud''.
% \item N�r man har betalt ``prisen'', s� b�r man ogs� udnytte den
% fleksibilitet, man f�r fra filteret, navnlig at $\alpha$ kan justeres.
% \ebul
% Herunder sammenlignes respons fra 2 eksponentielle midlingsfiltre: 
% Filter med $\alpha=0.18$, svarende til MA(10), som netop er testet, 
% og et nyt, der best�r af 3 sektioner, hvor $\alpha$ l�bende justeres.
% \\
% </latex>

% Datas�t med step
xs = x(N0end:end);
N = length(xs);
t_vec = (0:N-1)/fs;

% Del 1-3
R = 5; alpha1 = 2/(R+1);            % alpha = 0.33
R = 10; alpha2 = 2/(R+1);           % alpha = 0.18
R = 50; alpha3 = 2/(R+1);           % alpha = 0.04

% startv�rdibetingelser
y_exp = zeros([1 N]);               % pre-allocate
dy = 0;                             % delay line

% De f�rste n=50 filtreres med del 1 
alpha = alpha1;                     % alpha for denne sektion
nstart = 1; nend = nstart + 50;
for n = nstart:nend
    y = alpha*xs(n) + (1-alpha)*dy; % differensligning
    dy = y;                         % gem i delay line
    y_exp(n) = y;                   % gem nyeste output
end

% De n�ste n=50 filtreres med del 2
alpha = alpha2;                     % alpha for denne sektion
nstart = nend + 1; nend = nstart + 50;
for n = nstart:nend
    y = alpha*xs(n) + (1-alpha)*dy; % differensligning
    dy = y;                         % gem i delay line
    y_exp(n) = y;                   % gem nyeste
end

% De resterende filtreres med del 3
alpha = alpha3;                     % alpha for denne sektion
nstart = nend + 1; nend = N;
for n = nstart:nend
    y = alpha*xs(n) + (1-alpha)*dy; % differensligning
    dy = y;                         % gem i delay line
    y_exp(n) = y;                   % gem nyeste
end

% sammenligninger, filter med alpha=0.18, svarende til MA(10)
y_exp10 = filter(b10,a10,xs);

% Plot sammenligning
figure();

s1 = subplot(211);
p1 = plot(t_vec, xs); hold on; grid on;
p2 = plot(t_vec, y_exp10, 'Color', [230, 126, 34]/255, 'LineWidth', 2); 
p3 = plot(t_vec, y_exp, 'Color', [34, 153, 84]/255, 'LineWidth', 2); 
hold off;
xlim([0 1]);
title('Steprespons', 'FontSize', 12);
xlabel('Tid, $t$ [s]', 'FontSize', 12);
ylabel('ADC-kode', 'FontSize', 12);
legend({'Ufiltreret ADC-kode', ...
        'Eksp. ($\alpha=0.18$)', 'Eksp. (variabel $\alpha$)'}, ...
        'Location', 'east');

s2 = subplot(212);
copyobj([p3 p2 p1], s2);
grid on; box on; xlim([3 3.5]);
title('Steady state', 'FontSize', 12);
xlabel('Tid, $t$ [s]', 'FontSize', 12);
ylabel('ADC-kode', 'FontSize', 12);

sgti = 'Test af eksponentielle midlingsfiltre';
sgtitle(sgti, 'Interpreter', 'latex', 'FontSize', 14);

%%
% <latex>
% Ovenst�ende figurer viser styrken ved denne filtertype.
% Den gr�nne kurve viser, at man kan f� ``best of both worlds'':
% Hvis man benytter en strategi, hvor $\alpha$ gradvist s�nkes, 
% s� opn�s et filter, der \textit{b�de} stabiliseres hurtigt 
% (kort steprespons) \text{og} har h�j st�jd�mpning (lav varians).
% </latex>

%%
% <latex>
% \section{Q2.4. Manglende observationer, outliers}
% ``Korrupt'' data, fx outliers eller ``missing values'', betyder at
% filteret skal stabiliseres (indsvinges) igen, og at output fra filteret
% er ``korrupt'' i et stykke tid.
% \\ \\
% Nettobetydningen afh�nger af filtertype og filterl�ngde, og er et
% trade-off i design af filteret:
% \sbul
% \item Langt filter (lav $\alpha$-v�rdi): Betydning af en outlier er
% relativt lille ift. summen af alle de andre samples. Men, en ``Black
% Swan''-outlier eller mange ``missing values'' vil betyde d�rligt output i
% lang tid / mange samples. I et FIR-filter falder fejlen(e) ud p� et
% tidspunkt. I et IIR-filter ``lever'' de videre for evigt.
% \item Kort filter (h�j $\alpha$-v�rdi): Filteret tilpasser sig hurtig
% igen, dvs. fejlen ``d�r ud'' hurtigt. Til geng�ld er betydningen en 
% relativt meget st�rre fejl i outputtet, fordi en enkelt d�rlig v�rdi
% v�gter meget i et kort filter.
% \ebul
% Valg af filterl�ngde ift. korrupt data afh�nger af systemets mulighed 
% for at pre-processere data, fx fjerne outliers (real-tid eller ej) 
% samt systemets krav til robusthed versus hurtig reaktion/tilpasning.
% \\�\\
% Fix:
% Det er vigtigt, at justeringer til signalet bibeholder en konstant
% samplingsfrekvens, s� statistik og spektrum stadig kan regnes uden for
% meget bias. Mulige m�der at fikse ``korrupt'' data er:
% \sbul
% \item Start/afslutning af signal kan trimmes v�k.
% \item Et lille antal ``Missing values'' kan ``erstattes'': 
% Fx med median, middelv�rdi eller interpolation.
% \item Med en model for data (fx en regressionsmodel), kan estimerede
% v�rdier inds�ttes.
% \item Hvis en st�rre m�ngde data mangler, kan decimering/resampling
% benyttes, og lavere frekvenser vil da stadig v�re ``tilg�ngelige'' spektralt.
% \ebul
% Der findes uden tvivl mere intelligente metoder inden for specifikke
% anvendelsesomr�der.
% </latex>

%%
% <latex>
% \chapter{Opgave 3: Systemovervejelser}
% Det er interessant at designe systemet, s� m�leinstrumentet p� et
% display kan udl�se et bestemt antal betydende, p�lidelige cifre.
% Det er en helt oplagt designparameter til et m�lesystem.
% \\�\\
% Vi antager, at den ``r�'' m�lefejl (uanset kilden) er additiv og 
% udviser varianshomogenitet (alts� er uafh�ngig af m�lingens st�rrelse).
% Det forhold er allerede illustreret i tidligere afsnit.
% Vi ved s�, at hvis m�lev�rdien er en station�r stokastisk proces med
% tidsinvariant middelv�rdi (dvs. ingen step mens vi m�ler), 
% s� kan vi nedbringe variansen (fejlen) p� m�leestimatet ved at inkludere 
% flere samples i beregning af middelv�rdien.
% \\�\\
% Designudfordringen er s� at nedbringe spredningen p� estimatet s� tilpas 
% meget, at instrumentet har den �nskede pr�cision. Vi tager nu 
% udgangspunkt i et system, hvor designet allerede er fastlagt. Der er et
% MA(100)-filter, s� vi ved, at
% $$\hat{\sigma}_{\text{MA(100)}} \approx \frac{\hat{\sigma}_{\text{input}}}{\sqrt{100}}$$
% Fra opgave 1.1 ved vi, at $\hat{\sigma}_{\text{input}}=28.1$ [ADC-koder].
% Vi ved ogs� fra opgave 1.4, at niveauer i ADC'en er 3.33 [g/ADC-kode].
% S� enheden for spredningen p� middelv�rdien kan regnes om til vores 
% �nskede enhed til pr�sentation p� displayet [kg]:
% $$\hat{\sigma}_{\text{MA(100)}} =
% \frac{\hat{\sigma}_{\text{input}}}{\sqrt{100}} [\text{ADC-koder}] \cdot
% 3.33 [\frac{\text{g}}{\text{ADC-kode}}] \cdot 10^{-3}
% [\frac{\text{kg}}{\text{g}}] = 9.36 \cdot 10^{-3} [\text{kg}]$$
% Det vil alts� sige en spredning p� \SI{9.36}{\gram} efter
% MA(100)-filteret.
% \\�\\
% Vi vil nu gerne sikre, at den udl�ste m�lev�rdi ligger inden for 10
% standardafvigelser p� estimatet, hvilket er en ekstremt h�j grad af
% konfidens. For det mindst betydende ciffer p� displayet skal g�lde:
% $$\text{LSB} > 10 \cdot \hat{\sigma}_{\text{MA(100)}} = 93.6 \cdot 10^{-3} [\text{kg}]$$
% S� hvis vi lader displayet vise m�leresultater i steps af $100 \cdot 10^{-3}
% [\text{kg}] = 0.1 [\text{kg}]$, dvs. \SI{100}{\gram}, s� holder vi os p� den sikre side.
% \\�\\
% Desuden b�r man implementere en algoritme til at undg� flicker p�
% displayet, som forel�et i \cite[s. 5]{refdes} :)
% </latex>

%%
% <latex>
% \chapter{Konklusion}
% I denne case er der behandlet data fra en fysisk sensor, med fokus p�
% reduktion af st�j vha. midlingsfiltre og p� at forst� og kvantificere
% st�jen gennem simpel deskriptiv statistik.
% \\�\\
% Der er desuden lavet sammenligninger af forskellige typer midlingsfiltre
% og forskellige filterordener. Der er diskuteret fordele og ulemper ved
% hver type, og der er fremvist en l�sning med et eksponentielt
% midlingsfilter med variabel parameter, hvor man kan 
% ``f� det bedste fra begge verdener'': Hurtig stigetid og h�j d�mpning af st�j.
% \\�\\
% Det har v�ret en interessant og relevant case, med mange videre
% anvendelser i indlejret systemudvikling, reguleringsteknik, m.v.
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
% \chapter{Funktioner\label{sec:hjfkt}}
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
    set(groot, 'defaultGraphplotInterpreter',intpr); 

end

