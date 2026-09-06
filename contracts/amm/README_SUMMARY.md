# Riepilogo Benchmark Verifica Formale (AMM)

Questo documento fornisce una mappatura completa dello stato dell'arte del benchmark di verifica formale applicato alla nuova architettura a "cascata" (V1-V6) del contratto AMM. Suddivide e classifica le versioni del contratto, le regole scritte per testarle, la copertura dei test pratici (Forge) e confronta i risultati dei due prover formali (Certora e SolCMC) rispetto alla Ground Truth.

---

## 1. Evoluzione delle Versioni del Contratto (Architettura a Cascata)

A differenza dei benchmark tradizionali, i difetti qui sono cumulativi. Ogni versione eredita le vulnerabilità della successiva (procedendo al contrario), partendo da una V6 completamente esposta fino ad arrivare alla V1 blindata.

| Versione | Profilo | Difetti / Vulnerabilità Principali |
| :--- | :--- | :--- |
| **AMM_v6** | *Colabrodo* | Bug 5 (Inflation Attack): Rimuove il lock della `MINIMUM_LIQUIDITY`. |
| **AMM_v5** | *Vulnerabile* | Bug 4 (Precision Loss): Rimuove lo scaling `1e18` dai calcoli dei prezzi. |
| **AMM_v4** | *Vulnerabile* | Bug 3 (Redeem Liveness): Usa `< supply` bloccando il prelievo del 100%. |
| **AMM_v3** | *Vulnerabile* | Bug 2 (Reentrancy): Rimuove il modificatore `nonReentrant`. |
| **AMM_v2** | *Ibrida* | Bug 1 (Donation DoS): Usa il controllo di uguaglianza stretta `require(balance == r0)`. |
| **AMM_v1** | *Sicura (Baseline)* | Risolve tutti i bug: sincronizza flessibilmente, aggiunge i lock e usa scalature corrette. |

---

## 2. I 4 Pilastri della Sicurezza Verificata

Le 16 proprietà testate non sono state scelte a caso, ma coprono sistematicamente i 4 pilastri delle vulnerabilità DeFi negli Automated Market Maker:

1. **Precisione Matematica e Scaling**: Verifica che la matematica intera della EVM non distrugga il valore economico tramite troncamenti a zero o overflow. Valida il corretto scaling (`1e18`) dei prezzi per prevenire furti di precisione.
2. **Sicurezza Economica e Tokenomics**: Garantisce che le regole finanziarie non siano manipolabili. Dimostra matematicamente la difesa contro l'Inflation Attack (tramite `MINIMUM_LIQUIDITY`), l'incremento rigoroso della fee e l'equità proporzionale dei prelievi.
3. **Vulnerabilità Operative e Blocchi (DoS & Liveness)**: Assicura che i fondi non possano rimanere bloccati (frozen) a causa di attacchi logici. Smaschera deadlock operativi e attacchi DoS causati dall'invio malevolo di token diretti al contratto.
4. **Integrità dello Stato Globale**: Dimostra che le fondamenta algebriche del contratto non possano mai collassare, garantendo che le riserve non possano mai essere drenate completamente e il mercato rimanga stabile (Prodotto Costante).

---

## 3. Tassonomia delle Proprietà

| # | Proprietà | Categoria | Tipo | Descrizione |
| :- | :--- | :--- | :--- | :--- |
| 1 | **constant-product** | Function Spec | Safety | Dopo uno swap, il prodotto matematico dei bilanci reali non deve mai diminuire. |
| 2 | **deposit-precision** | Function Spec | Safety | Assicura che i token coniati non eccedano la corretta proporzione matematica a causa di sbilanciamenti. |
| 3 | **deposit-precision-strict** | Function Spec | Safety | Dimostrazione che l'uso dell'uguaglianza stretta `==` fallisce a causa degli arrotondamenti EVM. |
| 4 | **donation-dos** | Function Spec | Liveness | Verifica che la funzione di prelievo non si blocchi per colpa di un invio malevolo diretto al contratto. |
| 5 | **minimum-liquidity** | State Invariant | Safety | Verifica che almeno 1000 token di liquidità siano bloccati all'address 0 contro gli attacchi di inflazione. |
| 6 | **minimum-liquidity-strict** | State Invariant | Safety | Versione con uguaglianza stretta del controllo di liquidità. |
| 7 | **price-bounds** | Function Spec | Safety | Valida la disuguaglianza relativa dei prezzi calcolati rispetto alle riserve. |
| 8 | **price-equality** | Function Spec | Safety | Se le riserve sono identiche, il prezzo calcolato deve essere identico per entrambi i token. |
| 9 | **price-symmetry** | Function Spec | Safety | Dimostra che il prodotto incrociato dei prezzi non ecceda `1e36`, evitando overflow. |
| 10 | **price-symmetry-strict** | Function Spec | Safety | Versione con uguaglianza stretta (fallisce sempre a causa della perdita di precisione). |
| 11 | **redeem-fairness** | Function Spec | Safety | Verifica che l'ammontare prelevato sia matematicamente proporzionale alla propria quota di supply. |
| 12 | **redeem-liveness** | Function Spec | Liveness | Garantisce che l'ultimo fornitore di liquidità possa prelevare il 100% della supply. |
| 13 | **redeem-precision** | Function Spec | Safety | Bruciando shares valide, l'utente deve ricevere sempre un ammontare > 0 di token. |
| 14 | **reserves-not-drained** | State Invariant | Safety | Assicura che le riserve di una pool inizializzata rimangano strettamente maggiori di 0. |
| 15 | **swap-fee** | Function Spec | Safety | Verifica che dopo uno swap il prodotto k aumenti rigorosamente a causa della tassa trattenuta. |
| 16 | **swap-precision** | Function Spec | Safety | Dimostrazione (fallimento atteso) che scambiare 1 wei restituisce sempre zero token per arrotondamento. |

---

## 4. Copertura Testing Concreto (Forge)

Tutti i bug associati all'architettura a cascata V1-V6 sono provvisti di Proof of Concept (PoC) funzionanti e allineati.

| # | PoC File (Forge) | Dettagli |
| :- | :--- | :--- |
| 1 | `deposit-precision-strict_v1.t.sol` | Dimostra il bug di precisione nell'arrotondamento EVM sulle divisioni. |
| 2 | `deposit-precision_v6.t.sol` | PoC dell'Inflation Attack che porta il deposito di quote a restituire 0 shares (V6). |
| 3 | `donation-dos_v2.t.sol` | Dimostra il freeze permanente (DoS) inviando fondi non richiesti al contratto (V2). |
| 4 | `minimum-liquidity_v6.t.sol` | Validazione diretta dell'assenza di liquidità minima bloccata (V6). |
| 5 | `price-equality_v2.t.sol` | Valida calcoli di prezzo asimmetrici dovuti a discrepanze nelle riserve. |
| 6 | `redeem-fairness_v1.t.sol` | Validazione della corretta restituzione proporzionale. |
| 7 | `redeem-liveness_v4.t.sol` | Dimostra il deadlock: impossibile per un utente bruciare il 100% delle sue quote (V4). |
| 8 | `redeem-precision_v6.t.sol` | Dimostra come i troncamenti a zero azzerino i fondi recuperati in situazioni limite (V6). |
| 9 | `reentrancy_v3.t.sol` | Classico attacco di Reentrancy sfruttando la mancanza di lock (V3). |
| 10 | `reserves-not-drained_v6.t.sol` | Dimostra il completo drenaggio della pool in assenza di salvaguardie matematiche. |
| 11 | `swap-fee_v1.t.sol` | Validazione del corretto incasso percentuale nello State. |
| 12 | `swap-precision_v1.t.sol` | Dimostra il "zero return" (furto di 1 wei a causa dell'arrotondamento). |

---

## 5. Matrice dei Risultati (Ground Truth vs Prover)

La tabella definitiva confronta le aspettative umane (Ground Truth) con le performance effettive dei due prover. I risultati dimostrano la superiorità di Certora nell'astrarre correttamente i path complessi DeFi e le chiamate esterne (Uninterpreted Functions), contro i limiti architetturali di SolCMC (State Havoc, Limiti Aritmetici, Assenza di Liveness nativa).

*(Legenda: ❌ = Proprietà Violata/Falsa ; ✅ = Proprietà Sicura/Vera)*

| Proprietà | Tool | v1 | v2 | v3 | v4 | v5 | v6 | Note Benchmark |
| :--- | :--- | :-: | :-: | :-: | :-: | :-: | :-: | :--- |
| **constant-product** | *Ground Truth* | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| | **Certora** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Perfettamente allineato. |
| | **SolCMC** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Fallisce per State Havoc sulle chiamate esterne. |
| **deposit-precision** | *Ground Truth* | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | V6 subisce l'Inflation Attack. |
| | **Certora** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Perfettamente allineato. |
| | **SolCMC** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Fallisce per Non-Linear Arithmetic / State Havoc. |
| **deposit-precision-strict** | *Ground Truth* | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Falso atteso a causa dei rounding error EVM. |
| | **Certora / SolCMC** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Entrambi allineati al fallimento atteso. |
| **donation-dos** | *Ground Truth* | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Bug introdotto nella V2 (Strict Equality). |
| | **Certora** | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Perfettamente allineato sulla Liveness. |
| | **SolCMC** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Liveness espressa con `.call()`, restituisce sempre Falsi Negativi. |
| **minimum-liquidity** | *Ground Truth* | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | V6 rimuove il lock. |
| | **Certora** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Perfettamente allineato. |
| | **SolCMC** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | State Havoc azzera la variabile simbolica simulando il fallimento. |
| **minimum-liquidity-strict**| *Ground Truth* | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | |
| | **Certora** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Perfettamente allineato. |
| | **SolCMC** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Stesso destino di minimum-liquidity. |
| **price-bounds** | *Ground Truth* | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| | **Certora** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Perfettamente allineato. |
| | **SolCMC** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Risolve le disuguaglianze lineari pure senza state havoc. |
| **price-equality** | *Ground Truth* | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| | **Certora** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Perfettamente allineato. |
| | **SolCMC** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Idem come sopra. |
| **price-symmetry** | *Ground Truth* | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| | **Certora / SolCMC**| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Entrambi allineati (Matematica pura senza state change). |
| **price-symmetry-strict** | *Ground Truth* | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Falso atteso (Rounding). |
| | **Certora / SolCMC**| ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Entrambi allineati al fallimento atteso. |
| **redeem-fairness** | *Ground Truth* | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| | **Certora** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Perfettamente allineato. |
| | **SolCMC** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Fallisce per via di Non-Linear Arithmetic. |
| **redeem-liveness** | *Ground Truth* | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Bug introdotto in V4 ma innescabile solo in V6 (rimozione lock). |
| | **Certora** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Falso Positivo in V4/V5: esplora stati irraggiungibili. |
| | **SolCMC** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Liveness supportata solo via `.call()`, restituisce sempre Falsi Negativi. |
| **redeem-precision** | *Ground Truth* | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | V6 soffre l'Inflation Attack. |
| | **Certora** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Perfettamente allineato. |
| | **SolCMC** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Fallisce ovunque per colpa di State Havoc sulle chiamate esterne. |
| **reserves-not-drained** | *Ground Truth* | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| | **Certora** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Perfettamente allineato. |
| | **SolCMC** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Falsi negativi generati da chiamate esterne e Havoc memory. |
| **swap-fee** | *Ground Truth* | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |
| | **Certora** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Perfettamente allineato. |
| | **SolCMC** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Fallisce a causa della mancanza di inlining (State Havoc). |
| **swap-precision** | *Ground Truth* | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Zero return atteso. |
| | **Certora / SolCMC**| ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Entrambi allineati al fallimento atteso. |
