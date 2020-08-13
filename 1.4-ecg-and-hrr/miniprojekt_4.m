%% E3DSB miniprojekt 4 - Digital signalbehandling af elektrokardiogrammer
%%
% <latex>
% \chapter{Indledning}
% Fjerde miniprojekt i E3DSB er frit og udarbejdet individuelt med teori og metoder fra hele kurset.
% Ud over E3DSB er der bl.a. fundet inspiration til projektet i ST2PRJ2 fra ASE \cite{st2prj2}.
% </latex>

%%
% <latex>
% \section{Valgt emne}
% Elektrokardiografi er medicinsk signalbehandling til at m�le et hjertes elektriske aktivitet. 
% Signalet behandles f�rst analogt og s� digitalt for at danne et elektrokardiogram (EKG).
% EKG'er bruges til at screene, diagnosticere og monitorere hjertepatienter, og fx til r�d og vejledning i hjertestartere.
% \\ \\
% EKG'er er interessante, fordi analysemetoderne fra E3DSB er velegnede.
% Der er meget information i b�de tids- og frekvensdom�net for et EKG-signal.
% Der er desuden st�j og andre signalkomponenter, der skal filtreres bort, samt udfordrende tekniske problemstillinger.
% </latex>

%%
% <latex>
% \section{Form�l, metode og struktur}
% Projektet demonstrerer, hvordan v�rkt�jer fra E3DSB i \MATLAB~kan anvendes p� EKG-signaler.
% Dvs. hvordan information udtr�kkes fra EKG-signalet i b�de tids- og frekvensdom�net.
% Metoden er at sammenligne resultater fra raske (kontrolgruppe) og diagnosticerede patienter (ekspertvurdering).
% Fokus er p� arytmier.
% \\�\\
% \textbf{Analyse} redeg�r kort for EKG-signalet og anvendelser.
% \textbf{Design} udarbejder og karakteriserer filtre.
% \textbf{Implementering og test} demonstrerer analyser p� EKG-signaler fra raske og sammenligner med diagnosticerede patienter.
% En del kode er implementeret i hj�lpefunktioner, som ses til sidst i~\textbf{\nameref{sec:hjfkt}}.
% F�lgende figur opsummerer flow for signalbehandlingen.
% \begin{figure}[H]
% \centering
% \includegraphics[width=14cm]{../img/minipro4.png}
% \caption{Design og implementering\label{fig:design}}
% \end{figure}
% </latex>

%%
% <latex>
% \section{Datakilder}
% PhysioNet (\url{https://physionet.org/}) er et arkiv med medicinske, fysiologiske og biologiske signaler.
% Der findes ogs� gode v�rkt�jer, og bl.a. ATM (\url{https://archive.physionet.org/cgi-bin/atm/ATM}) er nyttig til at finde og downloade data.
% Projektet benytter derfra serier fra to datas�t.
% Det simulerede signal er benyttet til eksperimenter og algoritmeudvikling ej inkluderet i rapporten.
% </latex>

%%
% <latex>
% \begin{table}[H]
% \centering
% \begin{tabular}{|p{1cm}|p{3cm}|p{6cm}|p{5cm}|} \hline
% Kilde & Navn & Beskrivelse & Benyttede datas�t \\ \hline
% \cite{ptb}
%  & PTB Diagnostic ECG Database
%  & Klinisk data fra 268 patienter i forskellige diagnostiske klasser
%  & Pt.104, 116 (kontrol); Pt.113 (atrieflim.); Pt.126 (palpitation) \\ \hline
% \cite{challenge2011}
%  & PhysioNet Challenge 2011
%  & Simuleret EKG-data til udvikling af computerbaseret diagnostik
%  & Sim. \#2: Normal 80 BPM. Kun til udvikling. \\ \hline
% \end{tabular}\caption{Datas�t benyttet i projektet}
% \label{tab:datasets}
% \end{table}
% </latex>

%%
% <latex>
% \section{Software, data og kildekode}
% Rapport, databehandling og grafer er udarbejdet i \MATLAB{} R2018b update 5.
% \TeX-kode er dannet fra \MATLAB-kode vha. en tilpasset XSL-template.
% Lua\LaTeX{} er benyttet til at compile en PDF.
% \MATLAB-kode, data og template findes p� \url{https://github.com/janusboandersen/E3DSB}.
% </latex>

%%
% <latex>
% \chapter{Analyse}
% F�rst opridses (kort) baggrund for EKG-signalet.
% S� gennemg�s et par indikationer og analysemetoder p� relevante kardiovaskul�re lidelser.
% Endelig diskuteres problemer ifm. signalbehandling p� EKG-data.
% </latex>

%% EKG-m�ling
% <latex>
% EKG'et tages med 10 elektroder p� patientens krop:
% 4 placeres p� arme og ben (ekstremiteter), 6 p� brystkassen (thorax) \cite{absalon}.
% Elektrisk potentiale m�les mellem 12 forskellige kombinationer af elektroderne.
% Hver kombination kaldes en \textbf{afledning}.
% \begin{figure}[H]
% \centering
% \includegraphics[width=5cm]{../img/ecg-lead-angles.png}
% \caption{De 12 afledninger fra et EKG\label{fig:afledninger}}
% \end{figure}
% En afledning er et vektorsignal, som viser hjertets aktivitet i bestemt retning/vinkel. 
% Ovenst�ende figur illustrerer de 12 afledninger \cite{ecgbasics}.
% I dette projekt benyttes kun \textbf{afledning-\texttt{II}}.
% \texttt{II} giver det st�rste signal, da m�leretningen vektorielt er alignet med den l�ngste akse i hjertet.
% Dette er ogs� udbredelsesretning for depolariseringsimpulsen, der giver hjertemuskulaturens sammentr�kning,
% samt for den f�lgende repolariseringsimpuls \cite[ca. 13m36s]{st2prj2}.
% </latex>

%% EKG-signalet
% <latex>
% Den elektriske impuls, der starter en hjertecyklus, udg�r fra sinusknuden i h�jre forkammer (atrium).
% Den normale hjerterytme kaldes derfor en sinusrytme.
% En periode af signalet repr�senterer en hjertecyklus. 
% EKG'et viser flere ``takker'' og ``intervaller'', som har fysiologisk relevans.
% Afstanden mellem flere f�lgende perioder afg�r hjertets rytme. 
% Dette er illustreret i f�lgende figur \cite{realtimeecg}.
% \begin{figure}[H]
% \centering
% \includegraphics[width=14cm]{../img/ekg-graf.png}
% \caption{EKG-signalets ``takker'' og ``intervaller''\label{fig:signal}}
% \end{figure}
% Hjertets sammentr�kning (systole) begynder ved P-takken, hvor forkamrene (atrierne) tr�kker sig sammen.
% Hjertekamrene (ventriklerne) tr�kker sig derefter sammen ved QRS-komplekset.
% Her pumpes blod ud i kroppen.
% R-takken er det h�jeste positive udslag i denne sammentr�kning (for afledning-\texttt{II}).
% T-takken viser ventriklernes repolarisering og start p� hjertets afslapning og udvidelse (diastole) \cite{absalon}.
% RR-intervallet m�ler afstanden i tid mellem to R-takker og kan bruges til at m�le pulsen.
% De flade linjesegmenter mellem takkerne kaldes baseline.
% ``Afstande'' og ``h�jder'' for forskellige komponenter har relevans i forskellige kliniske analyser.
% </latex>

%%
% <latex>
% \subsection{Hjerterytme, frekvenser og filtre}
% EKG'er tages i hviletilstand, hvor pulsen ligger fra \SI{50}{\per\minute} til \SI{100}{\per\minute} \cite{absalonrytme}.
% Alle signalkomponenter inden for en cyklus ligger derfor over \SI{0.8}{\hertz} (\SI{50}{\per\minute} omregnet). 
% Forventeligt ligger hvilepulsen omkring \SI{60}{\per\minute}, dvs. f�rste komponent ved \SI{1}{\hertz}.
% Harmoniske heraf vil ogs� optr�de.
% Sygdomme kan tilf�je mere h�jfrekvent flimren i signalet (se beskrivelse n�ste afsnit).
% Klinisk udstyr b�r kunne m�le frekvenser i intervallet fra \SI{0.5}{\hertz} til \SI{150}{\hertz} for at opn� ``full fidelity'' \cite{emsfilter}.
% Til dette projekt er der ikke behov for frekvenser over \SI{40}{\hertz}.
% \\�\\
% Sygdom kan give meget lav puls (brakykardi) eller meget h�j puls (takykardi).
% Pulsen kan da ligge fra \SI{30}{\per\minute} til \SI{300}{\per\minute}.
% Det ligger dog udenfor analyserne i projektet.
% \\�\\
% Filtre kan nemt �del�gge information, der har klinisk relevans.
% S� principielt b�r alle filtre have line�r fase af diagnostisk grund (konstant group delay, ingen faseforvr�nging).
% \\�\\
% Analyseform�l og situation bestemmer de relevante frekvensb�nd til analyse og st�jfiltrering.
% EKG-maskiner tilbyder forskellige filtre og indstillinger (monitorering, diagnostik, 50/\SI{60}{\hertz}, osv.).
% </latex>

%% Indikationer p� hjerteproblemer og diagnostiske analyser
% <latex>
% Et EKG giver indikation p� en r�kke hjerteproblemer. 
% Her omtales kort hjerteproblemer relateret til arytmi (uregelm�ssig rytme), som kan detekteres i et EKG-signal. 
% Afsnittet opridser to anvendte analyser med baggrund i metoder fra E3DSB.
% </latex>

%%
% <latex>
% \subsection{Arytmi}
% Arytmi er uregelm�ssig hjerterytme.
% Det er normalt, at puls varierer med �ndedr�t (og fysiologiske processer).
% Men det er unormalt, n�r pulsen varierer \textit{uregelm�ssigt}, \textit{for meget} eller \textit{for lidt}.
% �rsagerne til arytmi er mange, fx stress eller hjerteproblemer.
% Konsekvenser varierer fra minimale til livstruende.
% </latex>

%%
% <latex>
% \subsubsection{Palpitationer}
% En type arytmi er hjertebanken (palpitationer), der kan f�les som om at hjertet springer slag over, eller sl�r for hurtigt.
% I tidsdom�net er en indikation p� arytmi, at det l�ngste RR-interval er minimum \SI{0.16}{\second} l�ngere end det korteste
% \cite{st2prj2syg}\cite{bioelectric19}. 
% I en spektralanalyse vil arytmi give en bredere fordeling af energi i spektret, end tilf�ldet for en normal hjerterytme.
% </latex>
%%
% <latex>
% \subsubsection{Atrieflimren} 
% Atrieflimren (AF) (forkammerflimren, eng.: atrial fibrillation) er hyppigt, is�r hos �ldre.
% AF skyldes forstyrrelser i hjertets ledningsnet, og kan v�re f�lgelidelse til andre sygdomme.
% Impulsen fra sinusknuden forlader ikke atriet, men cirkulerer rundt som en ``impulskarrusel'' \cite{absalonrytme}.
% S� atriemuskulaturen laver mange sammentr�kninger per pulsslag.
% Atriefrekvensen er kraftigt forh�jet og uregelm�ssig p� mellem \SI{350}{\per\minute} og \SI{600}{\per\minute} \cite{atrieff}.
% Pulsen svinger uregelm�ssig mellem \SI{50}{\per\minute} og \SI{100}{\per\minute} \cite{absalonafli}.
% \\�\\
% H�jfrekvente fluktuationer (flimrelinje) p� baseline p� EKG'et er et tegn \cite{absalonafli}.
% Som ved palpitationer vil AF vise en bredere fordeling af energi i spektrum.
% Det forventes, at der er mere energi ved h�jere frekvenser end er tilf�ldet ved palpitationer.
% </latex>
%%
% <latex>
% \subsection{Analyse 1: Powerspektrum}
% F�rste analyse viser, hvordan energien i signalet fordeler sig som en funktion af frekvens.
% Det relaterer til indikationer p� arytmier fra forrige afsnit.
% \\�\\
% \textbf{Power-spektrum}: Power-spektrum beregnes via FFT'en.
% Iflg. Parsevals s�tning kan energi og effekt i tidsdom�net regnes fra Fourier-koefficienter i frekvensdom�net.
% Gennemsnitseffekt for alle $N$ bins er:
% $$ P = \frac{1}{N}\frac{2}{N}\sum_{k=0}^{N/2} X(k) \cdot X^*(k) $$
% Her konjugeres frem for at kvadrere og tage modulus. 
% For at skalere FFT'en divideres med $N$. 
% For at regne effekt (ligesom $P=\frac{\Delta E}{\Delta t}$) divideres med $N$ igen.
% Der skaleres med $2$ for at g� fra dobbeltsidet til enkeltsidet analyse (summationsgr�nse $N/2$).
% </latex>

%%
% <latex>
% \subsection{Analyse 2: Heart-rate variability}
% Heart-rate variability (HRV) giver et m�l p� pulsens variabilitet.
% I litteraturen beskrives, at HRV bruges som risikomark�r for 
% kardiovaskul�re sygdomme og for nervesystemets funktion \cite{taskforcehrv}.
% HRV-analyser regnes klinisk fra EKG'et \cite{hrvhistory}.
% Fitness-entusiaster kan se HRV p� nyere pulsure og fitness-trackers.
% HRV kan anskues b�de i tidsdom�net (statistisk) og frekvensdom�net.
% Projektet fokuserer p� frekvensdom�net. 
% \\ \\
% HRV beregnes via spektralanalyse p� l�ngden af RR-intervallerne = IBI (inter-beat interval).
% Visning af udviklingen af IBI over tid kaldes et tachogram.
% Med et Powerspektrum p� IBI (normaliseret) vises, hvor energien (variansen) er.
% \\�\\
% \textbf{Resampling og detrending:}
% Pointen er at analysere den uregelm�ssige rytme, 
% men metodisk er det en udfordring, at IBI-signalet er
% samplet uregelm�ssigt (en "sample" per pulsslag).
% \MATLAB-funktionen \texttt{resample} bruges til at resample og 
% interpolere IBI-signalet til et regelm�ssigt samplet signal med en h�jere
% samplingsfrekvens \cite{resampling}. 
% Der v�lges en ny samplingsfrekvens p� 10 gange forventet pulsfrekvens.
% Resampling stemmer overens med metodeanbefalinger \cite{taskforcehrv}.
% IBI normaliseres til middelv�rdi p� \SI{0}{\second}.
% \\�\\
% Litteraturen n�vner mange mulige diagnostiske m�l. 
% Et eksempel p� et diagnostisk m�l, der g�r igen flere steder, er \textbf{LF/HF}-ratioen for relativ energi i 2 frekvensb�nd, hvor 
% \textbf{LF}-b�ndet er \SI{0.04}{\hertz} til \SI{0.15}{\hertz}, og \textbf{HF} er \SI{0.15}{\hertz} til \SI{0.4}{\hertz}. 
% </latex>

%% Signalbehandling p� EKG-data
% <latex>
% P�virkning fra st�j under m�lingerne giver u�nsket p�virkning af EKG'et og det spektrale indhold.
% Fysiologiske signaler har ``af natur'' variabilitet; dog er kun noget af variabiliteten brugbar.
% </latex>

%%
% <latex>
% \subsubsection{St�jkilder og st�jfilter}
% Der forventes en r�kke st�jartefakter ved opm�ling af EKG:
% \sbul
%  \item Lavfrekvent st�j fra patientens bev�gelser og
%   vejrtr�kning (< \SI{50}{\per\minute} = \SI{0.8}{\hertz}).
%  \item DC-st�j fra kontaktpotentiale ved elektrode/hud-forbindelsen
%   (op til 200-\SI{300}{\milli\volt}). Forv�rres af bev�gelser og 
%   perspiration. \cite{emsfilter}.
%  \item Baseline vandrer (driver) sfa. ovenst�ende el.lign. (ukendt frekvens).
%  \item Muskelst�j i frekvensomr�det 5-\SI{50}{\hertz}. Sv�rt at filtrere \cite{emsfilter}.
%  \item AC-st�j fra elforsyning (\SI{50}{\hertz} i 
%     europ�isk data og \SI{60}{\hertz} i amer.) samt harmoniske.
%  \item Andre instrumenter og apparater i lokalet, fx mobiltelefoner.
% \ebul
% Der burde v�re common-mode-rejection via A/D-converteren, men elektroder
% benyttet til opm�ling er muligvis ikke ens, hvilket reducerer CMRR.
% \\ \\
% I projektet ignoreres frekvenser over \SI{40}{\hertz}, da der ikke er relevante fysiologiske komponenter.
% Det tillader en simplificering af filteret til en lavere orden med bredere transitionsomr�de.
% Dermed undg�s ogs� et b�ndstop-filter (notch), der skal flyttes alt efter datas�ttets oprindelsesland.
% \\�\\
% \textbf{Alt i alt:} St�jfilteret skal fungere som et \textbf{b�ndpasfilter}, 
% der lukker frekvenser fra \SI{0.8}{\hertz} op til \SI{45}{\hertz} igennem 
% (regnet s� der er \SI{5}{\hertz} transition op til powerline-st�j, og \SI{5}{\hertz} ned til relevante frekvenser).
% P� den m�de kan ovenn�vnte st�jkilder frasorteres, og ``interessante'' frekvenser n�vnt i tidligere afsnit stadig passere.
% </latex>
%%
% <latex>
% \subsubsection{Periodicitet og stationaritet}
% DFT'en (FFT'en) er non-parametrisk, og foruds�tter at signalet er �n periode af et periodisk signal.
% EKG-signalet er en \textit{ikke}-station�r proces og er ikke periodisk.
% Fordelingsegenskaber er ikke stabile over tid, og amplitude, frekvens og fase vil ikke v�re konstante over tid. 
% \\ \\
% Ikke-periodicitet h�ndteres med \textbf{vinduesfunktioner} i filterdesign og FFT'er for at f� bedre kontrol over leakage og ripples.
% \\ \\
% Ikke-stationaritet g�r fortolkning sv�rere, n�r en fysiologisk komponent optr�der i flere bins pga. variation over tid.
% I dette projekt g�res ikke noget for at h�ndtere dette.
% En mulig metode er et glidende vindue, hvor signalsektioner analyseres separat.
% Short-Time Fourier Transform (STFT) er et bud.
% </latex>
%%
% <latex>
% \chapter{Design}
% </latex>

%%
% <latex>
% \section{Filterdesign og pre-processering}
% Filterbehov blev diskuteret tidligere. 
% Her designes og karakteriseres filter og pre-processering.
% \\ \\
% St�jfilteret er FIR-typen og har cut-off-frekvenser ved hhv. \SI{0.8}{Hz} og \SI{45}{Hz}.
% Filteret skal have gain p� \SI[per-mode=symbol]{1}{\volt\per\volt} i pasb�ndet.
% Der benyttes et Hann-vindue for at f� hurtig transition og smal main lobe.
% ``Prisen'' er, at sidelobe-d�mpning ``kun'' er omkring -50 dB for de f�rste par bins.
% \\ \\
% For at f� et hurtigt roll-off, og d�mpning p� \SI{6}{\decibel} ved \SI{0.8}{Hz}, skal filterorden for et h�jpasfilter v�re omkring 2000.
% S� b�ndpas er designet som 2000.-ordens h�jpas foldet med et 200.-ordens lavpas.
% \\�\\
% Modsat et realtidssystem \textit{beh�ver} filtrene i projektet ikke at v�re kausale.
% FIR-filtre designet efter metoder fra E3DSB er dog kausale.
% For at undg� h�j filterorden kunne ``forward-backward-filtering'' (IIR) give samme eller bedre respons med lavere filterorden og med zero-phase.
% Et alternativ kunne v�re at fjerne lavfrekvente st�jkomponenter med cubic-splines i tidsdom�net i stedet for at filtrere.
% Begge dele dog udenfor projektets omfang.
% \\�\\
% Filteret fjerner gennemsnitligt DC-niv., men baseline er p� medianen.
% S� efter filtrering justeres DC-niveauet yderligere s� baseline rykkes til \SI{0}{\milli\volt}.
% \\�\\
% Endelig fjernes outliers, her prim�rt indsvingning (transiente) indtil delay-line er fyldt op.
% \\�\\
% </latex> 

%%
%
clc; clear all; close all;
%%
% Specific�r og byg filteret og se impuls- og frekvensrespons.
% Alle dataserier har 1000 Hz samplingsfrekvens.

Fs = 1000;  % Hz          ord.  Fc   ord. Fc
h = ecg_noise_filter(Fs, [2000 0.8], [200 45]); % Som specificeret

% Respons i 4096-punkts FFT, 0-50 Hz p� frek. akse, impulsresp. 1000-1200
show_filter_response(h, 4096, Fs, [0 50], [1000 1200]);

%%
% Filterets pasb�nd er som �nsket, og der er line�r fase. Impulsrespons
% viser, at efter ca. 1200 samples vil indsvingning af filter n�sten v�re f�rdig (resterende koefficienter ``t�t p�'' 0).

%%
% <latex>
% \section{Test af filter og pre-processering}
% Filteret testes p� kontrolgruppen.
% Data loades og behandles, bl.a. justeres til r� v�rdier (data er lagret
% med gain \SI[per-mode=symbol]{2000}{\volt\per\volt}). Der oprettes ogs�
% hj�lpeserier i objektet (\texttt{ecg} er en \texttt{struct}).
% </latex>
A = 2000; B = 0;

% Patient 104: Kontrol (rask), mand 58, 60 s data, Fs=1000, A=2000, DC=0
ecg_ktr1 = ecg_load('data/kontrol/ktr1/s0306lrem.mat', 'Ktrl.1 (m/58)', ...
    'II', 'mV', A, B, Fs);

% Patient 116: Kontrol (rask), mand 54, 60 s data, Fs=1000, A=2000, DC=0
ecg_ktr2 = ecg_load('data/kontrol/ktr2/s0302lrem.mat', 'Ktrl.2 (m/54)', ...
    'II', 'mV', A, B, Fs);

d = {ecg_ktr1, ecg_ktr2};               % Gem p� en smart m�de til senere
%%
% Pre-process�r de to dataserier:
% Filtr�r med st�jfilter.
% Fjern indsvingning (fjernelse af f�rste 1200 samples koster 1.2 sek. data).
% Just�r baseline til 0 mV.
% Sammenlign f�r/efter-plots.
%
crop_samples = 1200;           % de f�rste 1200 samples fjernes (indsv.)

for e=1:2
    d{e} = ecg_filtered_cropped_moved(d{e}, h, crop_samples);
end
ecg_show_processing( d(1:2) );        % Sammenlign f�r/efter

%%
% Pre-processering virker som �nsket. Lavfrekvent st�j og vandring p�
% baseline fjernes. Signalets baseline ligger p� 0 mV efter justeringer.

%%
% <latex>
% \newpage
% \chapter{Implementering og test}
% I dette afsnit implementeres Analyse 1 og Analyse 2.
% Data for diagosticerede patienter loades og pre-processeres f�rst.
% </latex>

% Pt. 126: Sinusarytmi: Hjertebanken, mand 62, 38 s, Fs=1000, A=2000, DC=0
d{3} = ecg_load('data/arytmi/sa/s0154_rem.mat', 'Palpitat. (m/62)', ...
    'II', 'mV', A, B, Fs);

% Pt. 113: Arytmi: Atrieflimren, kvinde 65, 38 s, Fs=1000, A=2000, DC=0
d{4} = ecg_load('data/arytmi/af/s0018crem.mat', 'Atrieflim. (k/65)', ...
    'II', 'mV', A, B, Fs);

for e = 3:4      % Pre-processer signaler for de to diagnosticerede pat.
    d{e} = ecg_filtered_cropped_moved(d{e}, h, crop_samples);
end                                                 
ecg_show_processing( d(3:4) );            % Sammenlign f�r/efter

%%
% Igen bekr�ftes grafisk, at filtrering og anden pre-processeringen er g�et OK.

%%
% <latex>
% \section{Analyse 1: Powerspektrum}
% Analyse 1 udf�res ved at regne powerspektra p� de 4 serier, som beskrevet i analyseafsnittet.
% FFT'en regnes med et Hann-vindue.
% Med smoothing f�s et lidt p�nere spektrum (tak for funktionen, KPL!).
% Endelig sammenlignes de resulterende spektra grafisk.
% </latex>

%%
%
MA = 5;               % Smoothing af Powerspektrum glidende over MA bins
for e = 1:4           % Udf�r for alle 4 serier
    d{e} = ecg_powerspectrum(d{e}, MA);  
end
ecg_plot4_powerspectrum(d, [0 40]);         % Vis Powerspectrum fra 0-40 Hz 
%%
% <latex>
% Den f�rst spike i spektret repr�senterer patientents puls (for de raske, i hvert fald).
% For Ktrl.1 ligger den omkring \SI{1.05}{\hertz}.
% Det svarer til en normal hvilepuls p� \SI{63}{\per\minute}.
% Ktrl.2 har puls omkring \SI{61}{\per\minute}.
% \\�\\
% Det ses, at spektra for kontrolgruppe og diagnoser er v�sentligt forskellige.
% For raske patienter ligger det meste af energien under \SI{10}{\hertz} i et p�nt m�nster af puls og harmoniske.
% For Ktrl.2 ses der dog antageligt noget muskelst�j i omr�det 10-\SI{30}{\hertz}.
% \\�\\
% Spektra for palpitationer og atrieflimmer svarer til forventningen fra teoriafsnittet om arytmier:
% Der er \textit{v�sentligt} bredere fordeling af energi i spektra for patienter med diagnose end for kontrolgruppen.
% Der er intet p�nt m�nster af puls og harmoniske.
% Atrieflimren har, som forventet, den bredeste fordeling.
% \\ \\
% Analysen demonstrerer, hvordan powerspektra kan bruges til give indikationer p� hjertelidelser.
% Spektra viser ogs�, at der ikke er meget energi i b�ndet 30-\SI{40}{\hertz}.
% </latex>

%%
% <latex>
% \section{Analyse 2: Heart-rate variability}
% HRV-analyse kr�ver i princippet mere end 4 minutters observationer for at kunne give valide data p� relevante dele af spektre \cite{wikihrv}.
% EKG-signalerne valgt til dette projekt (mellem 38-60 s lange) er principielt ikke lange nok til at give h�ndfaste estimater.
% Men det er ok til at demonstrere analysen.
% \\�\\
% Med det ``in mente'' udf�res Analyse 2 med baggrund i teoriafsnittet.
% F�rst detekteres R-takkerne, og resultatet inspiceres grafisk.
% For at detektere R-takker algoritmisk, s�ttes der en t�rskelv�rdi manuelt.
% Den er sat ved inspektion af tidsserierne (ca. hvilket niveau i signalet overstiges kun af R-takker).
% Der kunne ogs� findes automatiske metoder.
% \MATLAB's \texttt{findpeaks} benyttes til at lokalisere peaks.
% Kriteriet er: En peak er en sample med h�jere v�rdi end sine to naboer og over t�rskelv�rdien.
% RR-intervallerne og IBI (normaliseret, i sek.) beregnes derefter.
% </latex>
%%
%
thresholds = [0.5, 0.5, 0.17, 0.25];    % T�rskelv�rdier per inspektion, mV

for e = 1:4                 % R-takker og IBI-intervaller for alle 4 serier
    d{e} = ecg_find_r_ibi(d{e}, thresholds(e));  
end
ecg_plot4_peaks(d, [0 60]);             % Vis R-takker for serierne, 0-60s

%%
% <latex>
% Diagrammerne bekr�fter, at algoritmen har detekteret alle R-takkerne ud fra de givne t�rskelv�rdier.
% Der vises ogs� beregnet puls over hele serien, som svarer fint til beregninger baseret p� frekvenser i Powerspektrum.
% Hjerterytmen for diagnosticerede patienter virker, helt forventeligt, ud fra diagrammet mere variabel og ``kaotisk'' end for de raske kontroller.
% Bem�rk, at patienten med atrieflimren har en forh�jet puls.
% \\�\\
% Tachogrammerne vises for at illustrere udsving ift. det gennemsnitlige inter-beat interval.
% </latex>

%%
ecg_plot4_tachogram(d);

%%
% <latex>
% Tachogrammerne viser ret tydeligt, at der er forskel p� variabilitet i hjerterytmen hos raske versus diagnosticerede,
% is�r for patienten diagnosticeret med atrieflimren. Sammenlign fx mindste
% og h�jeste v�rdi for IBI - i serien for palpitationer, er der mere end
% \SI{0.6}{\second} i forskel mellem korteste og l�ngste interval.
% For de raske patienter ses ogs� variabilitet. 
% Her er det overvejende mest sandsynligt, at st�rstedelen er drevet af vejrtr�kningen, hvilket er helt normalt.
% Hjerterytmen har h�j korrelation med respirationen, hvilket kaldes respiratorisk sinusarytmi (RSA).
% Variansen ($\sigma^2$) for hver serie er angivet i diagrammet. 
% Igen bekr�ftes, at de diagnosticerede har h�jest varians i hjerterytmen.
% \\�\\
% Fra tachogrammet ``f�les'' det n�rliggende at lave en spektralanalyse.
% Det er tydeligt fra figurer, at samplingen har v�ret uregelm�ssig.
% F�rst skal IBI-serien resamples \cite{resampling}.
% \\ \\
% Afstanden i tid mellem hver sample er givet fra
% \texttt{findpeaks}-algoritmen. 
% Splines-metoden benyttes til at interpolere mellem samples, fordi
% standardmedoden slet ikke kan fange al variabiliteten i IBI-signalet.
% </latex>

%%
%
                                   
%        Gns. puls for     K1 K2 SA AF                                   
desiredFs = round((10/60)*[61 60 72 103]); % 10 x gennemsnitspuls i Hz
                                           % som omtalt i teoriafsnit
for e = 1:4
    d{e} = ecg_ibi_resample(d{e}, desiredFs(e));    % Resample hvert IBI
end
ecg_show_resampling(d);                    % Vis resultater af resampling
%%
% <latex>
% Resultatet af resamplingen virker overordnet fornuftigt, bortset fra at
% den resamplede serie for palpitationer har lidt afvigelse omring 21-\SI{25}{\second}.
% \\�\\
% HRV-analysen regnes med de nye regelm�ssigt samplede serier.
% Powerspectrum beregnes, og samtidig regnes LF/HF-ratioen.
% Der benyttes \textit{ikke} et Hann-vindue i denne FFT.
% Powerspectrum udglattes til brug i grafer ved et glidende gennemsnit.
% \\�\\
% HRV-analysen er prim�rt relevant i frekvensomr�den 0-\SI{0.5}{\hertz}.
% Specifikt kigges p� intervallerne LF: 0.04-\SI{0.15}{\hertz} og 
% HF: 0.15-\SI{0.4}{\hertz}. Disse intervaller er markeret i diagrammet.
% Et udglattet powerspectrum plottes, og beregnede
% LF/HF-ratioer er vist for hver patient.
% \\�\\
% </latex>

%%
%
MA = 5;               % Smoothing af Powerspektrum glidende over MA bins
for e = 1:4
    d{e} = ecg_hrv_powerspectrum(d{e}, MA);  % Beregn HRV for hver patient
end
ecg_plot4_hrv(d, [0 0.5]);                   % Vis HRV for f op til 0.5Hz

%%
% <latex>
% Som n�vnt i indledningen til analysen lider resultatet under at
% dataserierne er relativt korte. 
% Desuden er der mange forskelllige mulige diagnostiske gr�nser for LF/HF.
% Ikke desto mindre er det interessant at observere, 
% at begge kontroller har LF/HF $> 1$, mens de to diagnosticerede
% patienter har LF/HF $< 1$. 
% Det fremg�r s�ledes, at energien i nervesystemets impulser er 
% mere h�jfrekvent for de to diagnosticerede patienter, relativt til
% kontrollerne.
% \\�\\
% Denne analyse har vist, hvordan Fourieranalyse kan benyttes til at 
% implementere en nyere diagnostisk teknik. L�ngere dataserier ville
% give analysen mere kraft.
% </latex>

%%
% <latex>
% \chapter{Konklusion}
% Denne rapport har demonstreret metoder fra E3DSB anvendt p� EKG-signaler.
% Det er vist, hvordan information, som kan have diagnostisk relevans for 
% sundhedspersonale, fx kardiologer, udtr�kkes fra EKG-signalet i 
% tids- og frekvensdom�net. Forbedringsforslag til metoder modtages meget gerne!
% \\ \\
% Projeket har ogs� demonstreret, hvordan en lidt st�rre datanalyse kan
% gribes an i \MATLAB. Gode r�d, tips og tricks modtages meget gerne.
% Det fremg�r nok af rapporten, at det var n�dvendigt at bruge en del 
% tid p� at oparbejde viden omkring fagomr�det \textit{og} 
% bruge en del tid p� at forbehandle data, f�r der egentlig kunne 
% udarbejdes analyser.
% </latex>

%%
%
x = randn(1000); % Til at vente p� graferne...
%% 
% <latex>
% \newpage
% \chapter{Implementerede hj�lpefunktioner\label{sec:hjfkt}}
% Der er til projektet implementeret en r�kke hj�lpefunktioner.
% </latex>

%% ecg_noise_filter
%
function [h] = ecg_noise_filter(Fs, highpass, lowpass)
% Lav et b�ndpasfilter. Specific�r hp, lp koeff. som [orden Fc]
% Janus Bo Andersen, 2019
    flag = 'scale';               % Normaliser koeff. til pasb�nd p� 0 dB
    win_hp = hann(highpass(1)+1); % Vinduesfkt. af Hann-typen
    win_lp = hann(lowpass(1)+1);  % Ditto  
    hp  = fir1(highpass(1), highpass(2)/(Fs/2), 'high', win_hp, flag); 
    lp  = fir1(lowpass(1), lowpass(2)/(Fs/2), 'low', win_lp, flag);
    h = conv(lp, hp);             % Fold lavpas og h�jpas sammen
end

%% show_filter_response
%
function [] = show_filter_response(h, N, Fs, flim, hlim)
% Viser filterrespons i dB
% Janus Bo Andersen, 2019
    setlatexstuff('Latex'); figure              % Figurindstillinger
    H = fft(h, N);                              % Frekvensrespons
    k = floor( flim(2)*(N/Fs) );                % H�jeste bin vi vil se
    
    subplot(2,2,1:2)                            % Impulsrespons
    stem(hlim(1):hlim(2), h( hlim(1)+1:hlim(2)+1 ))
    xlabel('$n$', 'Interpreter','Latex', 'FontSize', 15);
    ylabel('Impulsrespons', 'Interpreter','Latex', 'FontSize', 15);
    grid on;
    
    subplot(2,2,3)                              % Amplituderespons
    plot((1:k)*(Fs/N), mag2db(abs(H(1:k))) );  
    xlabel('$f$ [Hz]', 'Interpreter','Latex', 'FontSize', 15);
    ylabel('Amplitude [dB]', 'Interpreter','Latex', 'FontSize', 15);
    ylim([-40 5]);
    grid on;

    subplot(2,2,4)                              % Faserespons
    plot((1:k)*(Fs/N), angle(H(1:k))*180/pi );        
    xlabel('$f$ [Hz]', 'Interpreter','Latex', 'FontSize', 15);
    ylabel('Fase [deg]', 'Interpreter','Latex', 'FontSize', 15);
    grid on;

    sgtitle('Filterkarakteristik', 'Interpreter', 'Latex', 'FontSize', 20);
end

%% setlatexstuff
%
function [] = setlatexstuff(intpr)
% S�t indstillinger til LaTeX layout p� figurer: 'Latex' eller 'none'
% Janus Bo Andersen, 2019
    set(groot, 'defaultAxesTickLabelInterpreter',intpr);
    set(groot, 'defaultLegendInterpreter',intpr);
    set(groot, 'defaultTextInterpreter',intpr);
end

%% ecg_load
%
function [ecg] = ecg_load ( filename, name, lead, unit, gain, offset, Fs )
%load_ecg l�ser en fil og returnerer en datastruktur med ECG-data
%   filename: filnavn med (type .mat)
%   name: navn p� dataserien (bruges i plots)
%   lead: afledning ('I', 'II', 'III', osv.)
%   unit: enhed ('mV')
%   gain: forst�rkning i data (typisk 200-2000)
%   offset: 0 medmindre der er benyttet anden base end 0
%   Fs: samplingsfrekvens
% Janus Bo Andersen, 2019

    ecg = load(filename, 'val');
    ecg.meta.name = name;               % Dataseriens navn
    ecg.meta.lead = lead;               % Benyttet afledning (I, II, ...)
    ecg.meta.unit = unit;               % V�rdienhed for ECG-m�ling
    ecg.meta.gain = gain;               % Gain i data (.info-fil)
    ecg.meta.offset = offset;           % Base i date (.info-fil)
    ecg.Fs = Fs;                        % Samplingsfrekvens (.info-fil)

    % Afledte beregninger
    ecg.Ts = 1/ecg.Fs;                  % Sampleafst. p� 1/Fs [s]
    ecg.N = length(ecg.val);            % Antal samples
    ecg.resolution = ecg.Fs / ecg.N;    % Frekvensopl�sning [Hz/bin]
    ecg.T = ecg.N * ecg.Ts;             % Samlet tid i sek
    ecg.n = (0:ecg.N - 1);              % Vektor til samplenumre
    ecg.t = ecg.n * ecg.Ts;             % Vektor til tidsakse
    
    % R�data (r� mV f�r justeringer i lagret datas�t)
    ecg.raw = (ecg.val - ecg.meta.offset) ./ ecg.meta.gain;
end

%% ecg_filtered_cropped_moved
%
function [ecg] = ecg_filtered_cropped_moved(ecg, h, crop)
% Returnerer processeret ECG-objekt, samples der fjernes er 1:crop.
% Baseline flyttes fra median til 0 V.
% Janus Bo Andersen, 2019
    
    ecg.filt.filtered = filter(h, 1, ecg.raw);          % Filtrering
    
    ecg.filt.filtered = ecg.filt.filtered(crop+1:end);  % Cropping
    ecg.filt.N = length(ecg.filt.filtered);
    ecg.filt.T = ecg.filt.N * ecg.Ts;
    ecg.filt.n = (0:ecg.filt.N - 1);
    ecg.filt.t = ecg.filt.n * ecg.Ts; 
    ecg.h = h;                                          % Gem filteret     
    
    m = median(ecg.filt.filtered);                      % Flyt baseline
    ecg.filt.filtered = ecg.filt.filtered - m;
end

%% ecg_show_processing
%
function [] = ecg_show_processing(d)
% Plotter 2x2 plot med f�r/efter pre-processering
% d indeholder 2 ECG-objekter
% Janus Bo Andersen, 2019
    setlatexstuff('Latex'); figure                  % Figurindstillinger
    for p = 1:2
        subplot(2,2,p)                             % Ubehandlet EKG
        plot(d{p}.t, d{p}.raw);
        xlabel('$t$ [s]', 'Interpreter','Latex', 'FontSize', 10);
        ylabel(['Signal pre', ' [', d{p}.meta.unit, ']'], ...
            'Interpreter','Latex', 'FontSize', 10);
        grid on;
        title(d{p}.meta.name, 'Interpreter','Latex', 'FontSize', 15)

        subplot(2,2,p+2)                           % Processeret EKG
        plot(d{p}.filt.t, d{p}.filt.filtered);
        xlabel('$t$ [s]', 'Interpreter','Latex', 'FontSize', 10);
        ylabel(['Signal post', ' [', d{p}.meta.unit, ']'], ...
            'Interpreter','Latex', 'FontSize', 10);
        grid on;
        title('Efter pre-processering:', ...
            'Interpreter','Latex', 'FontSize', 15) 
    end
    sgtitle('Effekt af pre-processering', ...
        'Interpreter', 'Latex', 'FontSize', 20);
end

%% ecg_powerspectrum
%
function [ecg] = ecg_powerspectrum(ecg, smooth_bins)
% Regner Powerspectrum p� pre-processeret ECG-data
% Benytter Hann-vinduesfkt. og smoothing af Powerspektrum
% smooth_bins: Antal bins, i glidende gennemsnit (skal v�re ulige)
% Janus Bo Andersen, 2019

    x = ecg.filt.filtered;
    N = length(x);
    w = hann(N);                              % Hann-vinduesfkt.
    X = fft(x.*w');                           % Windowed FFT
    P = 2*(X.*conj(X))/(N^2);                 % Power for hver frekv.sample
    ecg.filt.Ps = smoothMag(P, smooth_bins);  % Glidende gennemsnit
    ecg.filt.Ps_sw = ecg.resolution*smooth_bins;  % Bredde af smoothing, Hz
end

%% ecg_plot4_powerspectrum
%
function [] = ecg_plot4_powerspectrum(d, flim)
% Plotter 2x2 figur med powerspektra, og s�tter xlim = flim
% d indeholder 4 ECG-objekter
% Janus Bo Andersen, 2019
    setlatexstuff('Latex'); figure              % Figurindstillinger
    
    for p = 1:4        
        subplot(2,2,p)                          % Plot figur nr. p
        plot((1:d{p}.filt.N/2)*(d{p}.Fs/d{p}.filt.N), ...
            d{p}.filt.Ps(1:d{p}.filt.N/2))
        xlim(flim)                              % Begr�ns udbredning i x
        xlabel('$f$ [Hz]', 'Interpreter','Latex', 'FontSize', 10);
        title(d{p}.meta.name, 'Interpreter','Latex', 'FontSize', 15)
        grid on;
        txt = ['Smooth.vindue: ', num2str(d{p}.filt.Ps_sw,2), '[Hz]'];
        yLimits = get(gca,'YLim');
        text(flim(2)*0.35, yLimits(2)*0.9, txt)
    end
    sgtitle('Powerspektra [$\propto$ V$^2$Hz$^{-1}$]', ...
        'Interpreter', 'Latex', 'FontSize', 20);
end

%% ecg_find_r_ibi
%
function [ecg] = ecg_find_r_ibi(ecg, threshold)
% Finder R-takker vha. findpeaks og t�rskelv�rdi
% Janus Bo Andersen, 2019
    ecg.filt.R.threshold = threshold;            % Gem t�rskelv�rdi
    [ecg.filt.R.pk, ecg.filt.R.lk] = ...         % R Peakv�rdi og Lokation
        findpeaks(ecg.filt.filtered, ...         % Find i filtreret data
        ecg.Fs, 'MinPeakHeight', threshold);

    ecg.filt.ibi = diff(ecg.filt.R.lk);          % IBI i sekunder
    ecg.filt.ibi_norm = ecg.filt.ibi - mean(ecg.filt.ibi); % normaliseret
    
    ecg.filt.HR = (60 / ecg.filt.T)*length(ecg.filt.R.pk); % puls i BPM
end

%% ecg_plot4_peaks
%
function [] = ecg_plot4_peaks(d, tlim)
% Plotter 4x1 figur med R-takker
% d indeholder 4 ECG-objekter
% Janus Bo Andersen, 2019
    setlatexstuff('Latex'); figure              % Figurindstillinger
    
    for p = 1:4        
        subplot(4,1,p)                          % Plot figur nr. p
        plot(d{p}.filt.t, d{p}.filt.filtered, ...
             d{p}.filt.R.lk', d{p}.filt.R.pk', 'ro')
        %xlabel('$t$ [s]', 'Interpreter','Latex', 'FontSize', 10);
        %ylabel(['Signal', ' [', d{p}.meta.unit, ']'], ...
        %    'Interpreter','Latex', 'FontSize', 10);
        txt = [d{p}.meta.name, '. ', ...
            'Threshold: ', num2str(d{p}.filt.R.threshold,2), ...
            ' [', d{p}.meta.unit, '].~', ...
            'Gns. puls:~', num2str(d{p}.filt.HR,3), ' min~$^{-1}$'];
        title(txt, 'Interpreter','Latex', 'FontSize', 10)
        grid on;
        xlim(tlim);
        if p == 1
            legend('EKG [mV]', 'Detekteret R-tak', ...
                'Location', 'SouthEast')
        end
    end
    xlabel('$t$ [s]', 'Interpreter','Latex', 'FontSize', 15);
    sgtitle('Detektion af R-takker i EKG-signaler i [mV]', ...
            'Interpreter', 'Latex', 'FontSize', 20);
end

%% ecg_plot4_tachogram
%
function [] = ecg_plot4_tachogram(d)
% Plotter 4x1 figur med tachogrammer
% d indeholder 4 ECG-objekter
% Janus Bo Andersen, 2019
    setlatexstuff('Latex'); figure              % Figurindstillinger
    
    for p = 1:4        
        subplot(4,1,p)                          % Plot figur nr. p
        N = length(d{p}.filt.ibi_norm);
        stem(0:N-1, d{p}.filt.ibi_norm)
        hold on
        plot(0:N-1, d{p}.filt.ibi_norm, 'b-')
        hold off
        %xlabel('$t$ [s]', 'Interpreter','Latex', 'FontSize', 10);
        %ylabel(['Signal', ' [', d{p}.meta.unit, ']'], ...
        %    'Interpreter','Latex', 'FontSize', 10);
        txt = [d{p}.meta.name, '.~', ...
            '$\sigma^2$~=~', num2str(var(d{p}.filt.ibi_norm),2)];
        title(txt, 'Interpreter','Latex', 'FontSize', 10)
        grid on;
        if p == 1
            legend('Norm. IBI [s]', '(lin. interpol.)', ...
                'Location', 'SouthEast')
        end
    end
    xlabel('Samples [m]', 'Interpreter','Latex', 'FontSize', 15);
    sgtitle('Tachogram viser normaliseret IBI i [s] per R-tak sample', ...
            'Interpreter', 'Latex', 'FontSize', 20);
end

%% ecg_ibi_resample
%
function [ecg] = ecg_ibi_resample(ecg, desiredFs)
% Resampler et uregelm�ssigt samplet IBI-signal til j�vnt samplede v�rdier
% Janus Bo Andersen, 2019

    x = ecg.filt.ibi_norm;              % Vi vil resample normaliseret IBI
    Tx = ecg.filt.R.lk(1:end-1);        % Regner �jeblikkelig puls fra m=0
                                        % og -1 fordider er regnet diff.

    [y, Ty] = resample(x, Tx, desiredFs, 'spline');     % Resampling med
                                                        % splines
    ecg.filt.resample.ibi_norm = y;     % Resamplet tidsserie
    ecg.filt.resample.t = Ty;           % Nye samplingstidspunkter
    ecg.filt.resample.Fs = desiredFs;   % Gem ny Fs
end

%% ecg_show_resampling
%
function [] = ecg_show_resampling(d)
% Viser 4x1 diagram over resultater af resampling
% Janus Bo Andersen, 2019
    setlatexstuff('Latex'); figure       % Figurindstillinger
    
    for e = 1:4
        subplot(4,1,e)
        x = d{e}.filt.ibi_norm;              % Oprindelig IBI
        Tx = d{e}.filt.R.lk(1:end-1);        % Oprindelige tidsp.
        y = d{e}.filt.resample.ibi_norm;     % Resamplet IBI
        Ty = d{e}.filt.resample.t;           % Nye samplingstidspunkter
        
        plot(Ty,y,Tx,x, 'ro')                % Plot sammenligning
        title(d{e}.meta.name, 'Interpreter','Latex', 'FontSize', 10)
        grid on;
        if e == 1
            legend('Resampled norm. IBI [s]', 'Oprind. norm. IBI [s]', ...
                'Location', 'SouthEast')
        end
    end
    xlabel('$t$ [s]', 'Interpreter','Latex', 'FontSize', 15);
    sgtitle('Resultat af resampling af normaliseret IBI, i [s]', ...
            'Interpreter', 'Latex', 'FontSize', 20);
end

%% ecg_hrv_powerspectrum
%
function [ecg] = ecg_hrv_powerspectrum(ecg, smooth_bins)
% Regner Powerspectrum p� resamplet IBI-data, regner LF/HF-ratio.
% Benytter smoothing af Powerspektrum
% smooth_bins: Antal bins, i glidende gennemsnit (skal v�re ulige)
% Janus Bo Andersen, 2019

    x = ecg.filt.resample.ibi_norm;
    N = length(x);
    w = ones(N,1);                % Mulighed for at udskifte til vinduesfkt
    X = fft(x.*w');                           % Windowed FFT
    P = 2*(X.*conj(X))/(N^2);                 % Power for hver frekv.sample
    ecg.filt.resample.ibi_Ps = smoothMag(P, smooth_bins);  % Gl. gennemsnit
    ecg.filt.resample.resolution = ecg.filt.resample.Fs / N; % Ny frekv.opl
    ecg.filt.resample.N = N; 
    
    f = (0:N-1) * ecg.filt.resample.resolution; % Frekvensakse
    ecg.filt.resample.f = f;
    
    % Beregning af LF og HF tager en genvej: Skaleringsfaktorer, der er ens
    % for HF og LF udelades (intervall�ngde, skalering til Hz, osv.) da
    % disse faktorer udg�r i ratioen.
    lfidx = [f > 0.04 & f <= 0.15];             % Frekvenser i LF
    hfidx = [f > 0.15 & f <= 0.4];              % Frekvenser i HF
    LF = sum(P(lfidx));                         % LF Energy
    HF = sum(P(hfidx));                         % HF Energy
    ecg.filt.resample.LF = LF;                  % Gem v�rdi
    ecg.filt.resample.HF = HF;                  % Gem v�rdi
    ecg.filt.resample.LFHF = LF / HF;           % Beregn LF/HF-ratio
end

%% ecg_plot4_hrv
%
function [] = ecg_plot4_hrv(d, flim)
% Plotter 2x2 figur med HRV powerspektra, og s�tter xlim = flim
% d indeholder 4 ECG-objekter
% Janus Bo Andersen, 2019
    setlatexstuff('Latex'); figure              % Figurindstillinger
    
    for p = 1:4        
        subplot(2,2,p)                          % Plot figur nr. p
        
        N = d{p}.filt.resample.N;
        Nmax = floor(N/2);
        X = d{p}.filt.resample.ibi_Ps(1:Nmax);
        f = (0:Nmax-1) * d{p}.filt.resample.resolution;
        LFHF = d{p}.filt.resample.LFHF;
       
        plot(f, X)
        xline(0.04); xline(0.15); xline(0.4);
        xlim(flim)                              % Begr�ns udbredning i x
        xlabel('$f$ [Hz]', 'Interpreter','Latex', 'FontSize', 10);
        %ylabel('Power [$\propto s^2$Hz$^{-1}$]', ...
        %    'Interpreter','Latex', 'FontSize', 10);
        title([d{p}.meta.name, '. LF/HF~=~', num2str(LFHF,3)], ...
            'Interpreter','Latex', 'FontSize', 15)
        grid on;
        txt = ['Oplsn.: ', ...
            num2str(d{p}.filt.resample.resolution, 2), '[Hz]'];
        yLimits = get(gca,'YLim');
        sc = 0.8;
        if p > 2
            sc = 0.1;   % Placering p� diagr. for diagnosticerede
        end
        text(flim(2)*0.35, yLimits(1)+(yLimits(2)-yLimits(1))*sc, txt)
    end
    sgtitle('HRV Powerspektra [$\propto$ s$^2$Hz$^{-1}$]', ...
        'Interpreter', 'Latex', 'FontSize', 20);
end

%% smoothMag (KPL)
% 
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