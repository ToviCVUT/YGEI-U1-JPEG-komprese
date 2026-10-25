# U1 JPEG komprese rastrových dat – YGEI
Úloha 1 z předmětu Geoinformatika (155YGEI) na Fakultě stavební ČVUT.

## Popis projektu (DWT)
Součástí programu je resamplování obrazu, kvantizace, ZIG-ZAG uspořádání, Huffmanovo kódování a zpětná rekonstrukce obrazu.

## Spuštění
Otevřete soubor `uloha_1.m` v prostředí MATLAB a spusťte skript. Parametry komprese lze nastavit pomocí funkce `compression_test`.
Program zobrazuje původní a rekonstruovaný rastr a vypisuje hodnoty RMSE jednotlivých barevných složek.

Implementace ztrátové komprese rastrových dat v prostředí MATLAB. Program umožňuje porovnání tří transformačních metod:
- Diskrétní kosinová transformace (DCT)
- Diskrétní Fourierova transformace (DFT)
- Haarova diskrétní vlnková transformaceadovaný kompresní poměr.

## Dokumentace
Podrobný popis algoritmu, pseudokódy a výsledky jsou uvedeny v technické zprávě `U1.pdf`.

