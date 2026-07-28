# UTCI-Kachel — Berechnungsvorschrift

Fusion aus Badge-Sensorik (SHTC3, TSL2591, AS7331, LSM6DSOX) und externen Wetterdaten, gesteuert durch die Innen/Außen-Erkennung.

---

## 1. Architektur

Der ESP32-H2 hat **kein WLAN** (nur BLE + 802.15.4) und keine FPU. Die UTCI-Berechnung gehört deshalb vollständig in die App, nicht in die Firmware:

```
Badge (H2)                        App (Phone)                    Netz
──────────                        ───────────                    ────
SHTC3   T_a, RH        ──BLE──►   Rohwerte                
TSL2591 E_v, R_IR      ──BLE──►   Kontext-Zustand      ◄──HTTP──  GeoSphere / Open-Meteo
AS7331  UVA/UVB        ──BLE──►   Sonnenstand (GPS+RTC)          v₁₀, G_h, T₂ₘ, RH₂ₘ
LSM6DSOX Neigung, met  ──BLE──►   ↓
ctx_state              ──BLE──►   T_mrt-Modell → UTCI-Polynom → Kachel
```

Zwei Betriebsarten, bewusst getrennt:

| | Live-Kachel | Retrospektive Auswertung |
|---|---|---|
| Zweck | aktueller Wert, jetzt | 14-Tage-Log neu durchrechnen |
| Wetterquelle | TAWES `current` / Nowcast | **INCA** (1 km, stündlich, Analyse) |
| Latenz | < 10 min | Tage — egal |
| Ort | App | App oder Backend |

Der Badge loggt **nur Rohwerte**, nie abgeleitete Indizes. Damit lässt sich das gesamte Log später mit besseren Wetterdaten und korrigierten Modellparametern neu rechnen — bei einem Messgerät mit unsicherem T_mrt-Modell ist das nicht optional.

---

## 2. Eingangsgrößen des UTCI

UTCI = f(T_a, T_mrt, v₁₀, p_a). Vier Größen, vier sehr unterschiedliche Zuverlässigkeiten:

| Größe | Primärquelle | Fallback | Unsicherheit |
|---|---|---|---|
| T_a [°C] | SHTC3, körperwärme-korrigiert | API `T2M` | ±0.5 K korrigiert, ±5 K unkorrigiert |
| p_a [kPa] | SHTC3 RH + T_a | API `RH2M` | ±0.05 kPa |
| v₁₀ [m/s] | Wetter-API (Abschnitt 6) | 1.0 m/s Konstante | Faktor 0.4–2 |
| T_mrt [°C] | Modell aus G_h + Sonnenstand + Beschattungsgrad | T_a | ±5 K gut, ±25 K bei Schattenfehler |

---

## 3. Schritt 1 — Dampfdruck

Magnus-Formel über Wasser (WMO-Koeffizienten):

```
e_s(T_a) = 6.112 · exp( 17.62 · T_a / (243.12 + T_a) )     [hPa]
p_a      = (RH / 100) · e_s(T_a) / 10                       [kPa]
```

Das UTCI-Polynom erwartet **kPa**, die Magnus-Formel liefert hPa — die Division durch 10 ist die häufigste Fehlerquelle bei Erstimplementierungen. Ein UTCI, der bei plausiblen Eingaben systematisch 3–4 K daneben liegt, hat meist genau diesen Bug.

Gültigkeitsgrenze des Polynoms: `p_a ≤ 5 kPa`. Bei T_a > 33 °C und RH > 90 % wird das erreicht → clampen und flaggen.

### 3.1 Körperwärme-Korrektur von T_a

Das ist der größte Einzelfehler der ganzen Kette. Selbstkalibrierender Ansatz, ohne Referenzthermometer:

```
ΔT_body = median{ T_badge(t) − T2M_api(t) }
```

über die letzten 24 h, aber **nur** über Samples, die alle folgenden Bedingungen erfüllen:

- `ctx_state == OUTDOOR` (kein Innenraum-Bias)
- Nacht (`E_v < 5 lux`) — schließt solare Aufheizung des Gehäuses aus
- `v₁₀ > 1.5 m/s` — sorgt für Konvektion am Gehäuse
- `|dT_badge/dt| < 0.02 K/s` — eingeschwungen, kein Übergang

Dann `T_a = T_badge − ΔT_body`. Typisch ergibt sich ΔT_body ≈ 1.5–4 K, je nach Trageweise und thermischer Entkopplung. Wenn weniger als 30 gültige Samples in 24 h zusammenkommen (Winter, Innenraumnutzung), letzten gültigen Wert weiterverwenden und die Kachel auf Qualitätsstufe B setzen.

**Tagsüber in der Sonne** kommt zur Körperwärme die Strahlungsaufheizung des Gehäuses. Zusatzterm, gegen den AS7331-Temperaturkanal kalibriert:

```
T_a = T_badge − ΔT_body − k_sol · G_p          k_sol ≈ 0.004 K/(W/m²)
```

k_sol wird bestimmt, indem man das Gerät bei bekanntem T_a (Referenzthermometer im Schatten daneben) in die Sonne legt.

---

## 4. Schritt 2 — Sonnenstand

Benötigt: Sonnenhöhe `h` und Azimut `A_sun`, aus Zeit (RTC/Phone) und Position (GPS).

Für diesen Zweck reicht der **PSA-Algorithmus (Blanco-Muriel et al.)** mit ~0.01° Genauigkeit und ~30 Zeilen Code. NOAA SPA ist Overkill. Fertige Implementierungen:

- Kotlin/Java: `net.e175.klaus:solarpositioning` (Grena/SPA)
- Swift: `SwiftAA`
- JS/TS: `suncalc`
- Python (Validierung): `pvlib.solarposition.get_solarposition`

Nur `h > 0` zählt; nachts ist die kurzwellige Bilanz null und T_mrt hängt allein an der langwelligen Bilanz.

---

## 5. Schritt 3 — T_mrt

### 5.1 Strahlungsbilanz (VDI 3787 Bl. 2, vereinfachte Form für stehende Person)

```
K_abs = f_p(h) · I_n · f_sun  +  F_sky · D_h  +  F_grd · ρ_g · G_h
L_abs = F_sky · ε_sky · σ · T_aK⁴  +  F_grd · ε_grd · σ · T_grdK⁴

S_str = α_k · K_abs + ε_p · L_abs

T_mrt = ( S_str / (ε_p · σ) )^0.25 − 273.15
```

| Konstante | Wert | Bedeutung |
|---|---|---|
| `α_k` | 0.70 | kurzwelliger Absorptionsgrad des bekleideten Menschen |
| `ε_p` | 0.97 | Emissionsgrad des Menschen |
| `σ` | 5.670e-8 | Stefan-Boltzmann |
| `F_sky`, `F_grd` | 0.5 / 0.5 | Winkelfaktoren obere/untere Hemisphäre, stehend |
| `ρ_g` | 0.20 | Bodenalbedo (Asphalt 0.12, Gras 0.20, Schnee 0.70) |
| `ε_grd` | 0.95 | Emissionsgrad Boden |

**Projektionsflächenfaktor** nach Fanger, `h` in Grad:

```
f_p(h) = 0.308 · cos( h · (0.998 − h²/50000) · π/180 )
```

**Himmelsemissivität** nach Brutsaert, mit Bewölkungskorrektur (`c` = Bewölkungsgrad 0…1, aus der API):

```
ε_clear = 1.24 · ( p_a[hPa] / T_aK )^(1/7)
ε_sky   = ε_clear + (1 − ε_clear) · c
```

**Bodentemperatur**, einfachster brauchbarer Ansatz:

```
T_grd = T_a + k_grd · G_h          k_grd ≈ 0.02 K/(W/m²)
```

`G_h` already reflects local shading (via Open-Meteo and the f_sun-weighted exposure model), so **do not** multiply by `f_sun` again here — that would double-count shading and break the plausibility table in 5.2.

k_grd ist stark oberflächenabhängig (Asphalt in praller Sonne erreicht T_a + 25 K, Wiese + 5 K). Als Modellparameter behandeln, nicht als Naturkonstante.

**Strahlungsaufteilung:** `G_h = D_h + I_n · sin(h)`. Liefert die API nur `G_h` (INCA `GL`), muss mit einem Separationsmodell (Erbs oder Reindl) in Direkt- und Diffusanteil zerlegt werden. Open-Meteo liefert `direct_radiation` und `diffuse_radiation` bereits getrennt — ein guter Grund, es als Primärquelle für die Strahlung zu nehmen, selbst wenn der Wind von GeoSphere kommt.

### 5.2 Zahlenbeispiel (Plausibilitätsprüfung der Implementierung)

Sommermittag, klar, T_a = 30 °C, RH = 50 %, h = 60°, I_n = 900, D_h = 70, G_h = 850 W/m², ρ_g = 0.2, c = 0:

| Zwischenwert | volle Sonne (`f_sun`=1) | Schatten (`f_sun`=0, D_h=150, G_h=150) |
|---|---|---|
| `f_p(h)` | 0.174 | 0.174 |
| `K_abs` | 277 W/m² | 90 W/m² |
| `ε_sky` | 0.848 | 0.848 |
| `T_grd` | 47.0 °C | 33.0 °C |
| `L_abs` | 486 W/m² | 440 W/m² |
| `S_str` | 665 W/m² | 489 W/m² |
| **`T_mrt`** | **58.5 °C** | **34.0 °C** |

Der Unterschied Sonne/Schatten beträgt **24.5 K in T_mrt** und rund 8 K in UTCI. Wer die Implementierung testet und hier deutlich abweicht, hat einen Fehler; wer die Sonnen-/Schattenerkennung falsch macht, produziert einen Fehler, gegen den jede Verfeinerung der Konstanten irrelevant ist.

### 5.3 Beschattungsgrad `f_sun` — die eigentliche Aufgabe des TSL2591

Hier ist die zentrale Design-Entscheidung: **Der TSL2591 misst nicht die Bestrahlungsstärke, er entscheidet Sonne gegen Schatten.**

Der Grund ist die fehlende Azimutinformation. Der LSM6DSOX ist ein 6-Achser ohne Magnetometer — aus dem Schwerevektor kennt man die Neigung der Badge-Ebene gegen die Horizontale, aber nicht, in welche Himmelsrichtung sie zeigt. Ohne Azimut lässt sich der gemessene Lux-Wert nicht auf die Horizontale umrechnen. Eine am Körper getragene, unbekannt orientierte Fläche liefert prinzipiell keine Bestrahlungsstärke.

Drei Merkmale entscheiden Sonne/Schatten trotzdem, und zwar **orientierungsunabhängig**:

| Merkmal | Physik | in der Sonne | im Schatten |
|---|---|---|---|
| `σ_lux = E_v / (K · G_h,api)` | Pegelvergleich mit dem Erwartungswert | 0.3 – 1.2 | < 0.15 |
| `R_IR = CH1/CH0` | Direktstrahlung ist IR-reicher als Himmelslicht | 0.40 – 0.48 | 0.26 – 0.34 |
| `k_UV = UVA / E_v` | Himmelslicht ist relativ UV-reicher als Direktstrahlung | niedriger | höher |

`σ_lux` allein ist unbrauchbar: ein von der Sonne weggedrehter Badge liest auch in praller Sonne wenig. `R_IR` und `k_UV` sind dagegen Spektralmerkmale — sie ändern sich beim Drehen kaum, weil sich die *Zusammensetzung* des einfallenden Lichts nicht ändert, nur seine Menge. Deshalb tragen sie die Entscheidung.

```
f_sun = clamp( 0.5·ramp(σ_lux, 0.15, 0.40)
             + 0.3·ramp(R_IR,  0.34, 0.42)
             + 0.2·ramp(-log10(k_UV), 2.4, 2.9) , 0, 1 )
```

Zusätzlich: `f_sun` über 5 Minuten mit einem **Maximum-Filter** glätten, nicht mit einem Mittelwert. Wer 5 Minuten in der Sonne steht, dreht sich irgendwann einmal so, dass der Badge die Sonne sieht — der Maximalwert ist repräsentativer als der Durchschnitt über alle Körperdrehungen.

`K` = Lichtausbeute des Tageslichts ≈ 110 lm/W. Genauer: 105 lm/W bei klarem Himmel mit Direktanteil, 115–125 lm/W bei Bewölkung. Konditionierung auf `R_IR` möglich, bringt aber wenig, weil `σ_lux` ohnehin nur als grober Pegelvergleich dient.

### 5.4 Ausbaustufe: Magnetometer

Mit Azimutwissen wird aus der Schattenerkennung eine echte Bestrahlungsstärkemessung auf der Körperoberfläche — physiologisch sogar aussagekräftiger als der horizontale Wert, weil er die tatsächlich vom Körper empfangene Strahlung abbildet.

Der LSM6DSOX hat einen **Sensor-Hub** (Mode-4-Master), der einen externen Magnetometer über die Hilfs-I²C-Leitungen selbstständig ausliest und in den FIFO einbettet — der H2 muss dafür nicht aufwachen. Passender Partner: **LIS2MDL** (ST, 2×2 mm, I²C `0x1E`, ~50 µA bei 10 Hz). Das ist die vorgesehene Kombination und kostet BOM-seitig fast nichts.

Alternativ, ohne Bauteil: Ist `G_h` aus der API bekannt und die Sonne sichtbar, lässt sich aus dem gemessenen Lux-Wert der Azimut *invertieren* (eine Unbekannte, eine Gleichung). Funktioniert nur bei klarem Himmel und ist mehrdeutig (zwei Lösungen symmetrisch zur Sonnenrichtung). Als Notlösung brauchbar, nicht als Design.

---

## 6. Schritt 4 — Windgeschwindigkeit

UTCI verlangt `v₁₀`, also die Windgeschwindigkeit in **10 m Höhe**, gültig von **0.5 bis 17 m/s**.

### 6.1 Recherchierte Quellen

| Quelle | `resource_id` / Endpoint | Auflösung | Latenz | Abdeckung | Key | Lizenz |
|---|---|---|---|---|---|---|
| **GeoSphere TAWES** | `station/current/tawes-v1-10min` | ~270 Stationen, 10 min | Echtzeit | AT | nein | CC BY 4.0 |
| **GeoSphere Nowcast** | `grid/forecast/nowcast-v1-15min-1km` | 1 km, 15 min | Nowcast | AT | nein | CC BY 4.0 |
| **GeoSphere NWP** | `grid/forecast/nwp-v2-1h-2500m` | 2.5 km, 1 h | Prognose | AT | nein | CC BY 4.0 |
| **GeoSphere INCA** | `grid/historical/inca-v1-1h-1km` | 1 km, 1 h | **Tage** | AT + Umland | nein | CC BY 4.0 |
| **Open-Meteo** | `api.open-meteo.com/v1/forecast` | 2 km (ICON-D2) | 15 min | global | nein | CC BY 4.0 |

Basis-URL GeoSphere: `https://dataset.api.hub.geosphere.at/v1/`

**INCA** liefert `UU` und `VV` (Windkomponenten in m/s, ostwärts und nordwärts) sowie `GL` (Globalstrahlung, W/m²), `T2M`, `RH2M`, `TD2M`, `P0`, `RR` auf 1-km-Raster. Der Betrag:

```
v₁₀ = sqrt(UU² + VV²)
```

Der Datensatz läuft im Modus `historical` mit mehreren Tagen Nachlauf — **für die Live-Kachel unbrauchbar, für die retrospektive Auswertung des 14-Tage-Logs die beste verfügbare Quelle**, weil er Wind und Globalstrahlung konsistent auf demselben Raster liefert.

**TAWES** ist die Live-Quelle: Rohdaten der letzten 3 Monate, 10-Minuten-Auflösung, in Echtzeit bespielt, Modus `current` verfügbar. Windmessung nach WMO-Standard in 10 m — **keine Höhenumrechnung nötig**. Nachteil: Punktmessung, die nächste Station kann 15 km entfernt und topographisch nicht vergleichbar sein.

Die genauen Parameterkürzel je Datensatz nicht raten, sondern abfragen:

```
GET /v1/station/current/tawes-v1-10min/metadata
GET /v1/grid/forecast/nowcast-v1-15min-1km/metadata
```

Beispielabfrage INCA-Zeitreihe an einem Punkt:

```
GET /v1/timeseries/historical/inca-v1-1h-1km
      ?parameters=UU,VV,GL,T2M,RH2M
      &lat_lon=48.2085,16.3721
      &start=2026-07-01T00:00
      &end=2026-07-14T23:00
```

**Open-Meteo** als globaler Fallback und Primärquelle für die Strahlungsaufteilung:

```
GET https://api.open-meteo.com/v1/forecast
      ?latitude=48.21&longitude=16.37
      &current=temperature_2m,relative_humidity_2m,wind_speed_10m,
               cloud_cover,shortwave_radiation,direct_radiation,diffuse_radiation
      &wind_speed_unit=ms
```

Der freie Tarif ist auf nicht-kommerzielle Nutzung und rund 10 000 Abrufe pro Tag begrenzt — bei 15-Minuten-Caching pro Gerät völlig ausreichend, bei einem Backend für viele Badges nicht.

### 6.2 Höhenumrechnung

Nur nötig, wenn eine Quelle den Wind in anderer Höhe liefert. Logarithmisches Windprofil:

```
v(z₂) = v(z₁) · ln(z₂/z₀) / ln(z₁/z₀)          z₀ = 0.01 m (Gras)
```

Umrechnungsfaktoren auf 10 m: von 1.1 m ×1.47, von 1.5 m ×1.38, von 2 m ×1.31.

TAWES, INCA `UU/VV` und Open-Meteo `wind_speed_10m` liefern bereits 10 m — hier **nichts umrechnen**. Der Faktor gehört nur in die Verarbeitung eigener bodennaher Messungen.

### 6.3 Urbane Korrektur

Das ist der unangenehme Teil. TAWES-Stationen stehen definitionsgemäß frei (Flughäfen, Wiesen). In einer Straßenschlucht liegt die tatsächliche Windgeschwindigkeit typisch bei 30–60 % davon. UTCI reagiert im Kalten sehr empfindlich: bei T_a = 0 °C senkt der Schritt von 1 auf 5 m/s den UTCI um rund 8 K.

Konsequenzen:

- Reduktionsfaktor `c_urban` als expliziten, dokumentierten Modellparameter führen (Startwert 0.5 im dichten Stadtgebiet, 1.0 im Freiland), **nicht** stillschweigend hineinrechnen.
- Bei `T_a < 10 °C` in der Kachel-Metadaten anzeigen, dass der Wind die dominierende Unsicherheit ist.
- Untergrenze hart clampen: `v₁₀ = max(v₁₀ · c_urban, 0.5)`.

### 6.4 Rolle eines badgeseitigen Anemometers

Ein FS3000 oder ähnliches am Körper misst **nicht** `v₁₀` — der Träger ist der Windschatten. Er könnte `c_urban` plausibilisieren (Verhältnis gemessener Nahfeldwind zu Stationswind), taugt aber nicht als UTCI-Eingang. Für die Kachel nicht erforderlich.

---

## 7. Schritt 5 — UTCI-Polynom

Referenz ist die Näherung 6. Ordnung von Bröde et al. (2012), Quellcode `UTCI_a002.f90` auf utci.org. Rund 210 Koeffizienten, rein mechanisch zu portieren.

**Gültigkeitsbereich** — außerhalb ist das Polynom nicht nur ungenau, sondern divergiert:

| Größe | Bereich |
|---|---|
| `T_a` | −50 … +50 °C |
| `T_mrt − T_a` | −30 … +70 K |
| `v₁₀` | 0.5 … 17 m/s |
| `p_a` | 0 … 5 kPa |

Alle vier vor dem Aufruf prüfen. Bei Überschreitung clampen **und** flaggen — ein geclampter Wert darf nicht als normaler Messwert in der Kachel stehen. Der Fall `T_mrt − T_a > 70 K` tritt in praller Sommersonne über Asphalt real auf.

Portierungsempfehlung: das Polynom **aus dem Fortran-Quelltext per Skript generieren**, nicht abtippen, und dieselbe generierte Datei in App, Backend und Auswertungsskript verwenden. 210 handabgetippte Koeffizienten enthalten praktisch garantiert einen Tippfehler, der nur in einer Ecke des Parameterraums auffällt.

Verfügbare Referenzimplementierungen zum Gegenrechnen:

- Python: `pythermalcomfort.models.utci` — der Standard für Unit-Tests
- Python: `thermofeel` (ECMWF)
- Fortran: Originalcode von utci.org

### 7.1 Belastungsstufen

Für die Anzeige in der Kachel:

| UTCI [°C] | Stufe |
|---|---|
| > +46 | extreme Hitzebelastung |
| +38 … +46 | sehr starke Hitzebelastung |
| +32 … +38 | starke Hitzebelastung |
| +26 … +32 | mäßige Hitzebelastung |
| +9 … +26 | keine thermische Belastung |
| 0 … +9 | leichte Kältebelastung |
| −13 … 0 | mäßige Kältebelastung |
| −27 … −13 | starke Kältebelastung |
| −40 … −27 | sehr starke Kältebelastung |
| < −40 | extreme Kältebelastung |

---

## 8. Qualitätsstufen der Kachel

Die Innen/Außen-Erkennung steuert, was die Kachel überhaupt anzeigen darf:

| Stufe | Bedingungen | Anzeige | erwartete Unsicherheit |
|---|---|---|---|
| **A** | `OUTDOOR`, Wetterdaten < 30 min, GPS-Fix, `ΔT_body` kalibriert, `f_sun` bestimmt | UTCI mit Belastungsstufe | ±2–3 K |
| **B** | `OUTDOOR`, aber Wetterdaten veraltet oder kein GPS-Fix | UTCI mit sichtbarem Vorbehalt, `T_mrt = T_a`, `v₁₀ = 1.0` gesetzt | ±5–8 K |
| **C** | `INDOOR` oder `INDOOR_WINDOW` | **kein UTCI** — Kachel schaltet auf PMV/PPD um | — |
| **D** | `UNKNOWN`, oder Eingang außerhalb Gültigkeitsbereich | letzter Wert ausgegraut mit Zeitstempel | — |

Stufe C ist keine Einschränkung, sondern korrekt: UTCI ist für Außenraumbedingungen definiert und setzt Gehaktivität sowie ein Outdoor-Bekleidungsmodell voraus. Ein UTCI-Wert im Büro ist ein Kategorienfehler, kein ungenauer Messwert.

Die Kachel sollte zusätzlich den **dominierenden Treiber** benennen — „Sonne", „Wind", „Feuchte" — bestimmt aus der partiellen Ableitung: welcher Eingang, um seine eigene Unsicherheit variiert, verschiebt den UTCI am stärksten. Das ist eine ehrlichere Information als eine dritte Nachkommastelle.

---

## 9. Referenzimplementierung (Python, zum Gegenrechnen)

```python
import numpy as np
from pythermalcomfort.models import utci

SIGMA = 5.670374419e-8

def vapour_pressure_kpa(t_a, rh):
    """Magnus über Wasser. t_a in °C, rh in %. Rückgabe kPa."""
    e_s = 6.112 * np.exp(17.62 * t_a / (243.12 + t_a))   # hPa
    return rh / 100.0 * e_s / 10.0                        # kPa

def projected_area_factor(h_deg):
    """Fanger, stehende Person. h_deg = Sonnenhöhe in Grad."""
    if h_deg <= 0:
        return 0.0
    return 0.308 * np.cos(np.radians(h_deg * (0.998 - h_deg**2 / 50000.0)))

def sky_emissivity(p_a_kpa, t_a, cloud_frac):
    """Brutsaert mit Bewölkungskorrektur."""
    eps_clear = 1.24 * (p_a_kpa * 10.0 / (t_a + 273.15)) ** (1.0 / 7.0)
    return eps_clear + (1.0 - eps_clear) * cloud_frac

def mean_radiant_temp(t_a, p_a_kpa, h_deg, i_n, d_h, g_h,
                      f_sun=1.0, cloud_frac=0.0,
                      alpha_k=0.70, eps_p=0.97, rho_g=0.20,
                      eps_grd=0.95, k_grd=0.02):
    f_sky = f_grd = 0.5
    f_p = projected_area_factor(h_deg)

    k_abs = f_p * i_n * f_sun + f_sky * d_h + f_grd * rho_g * g_h

    t_ak = t_a + 273.15
    t_grd_k = t_a + k_grd * g_h + 273.15
    eps_sky = sky_emissivity(p_a_kpa, t_a, cloud_frac)
    l_abs = (f_sky * eps_sky * SIGMA * t_ak**4
             + f_grd * eps_grd * SIGMA * t_grd_k**4)

    s_str = alpha_k * k_abs + eps_p * l_abs
    return (s_str / (eps_p * SIGMA)) ** 0.25 - 273.15

def utci_tile(t_a, rh, v10, h_deg, i_n, d_h, g_h, f_sun, cloud_frac):
    p_a = vapour_pressure_kpa(t_a, rh)
    t_mrt = mean_radiant_temp(t_a, p_a, h_deg, i_n, d_h, g_h, f_sun, cloud_frac)

    flags = []
    if not (-50 <= t_a <= 50):            flags.append("t_a")
    if not (-30 <= t_mrt - t_a <= 70):    flags.append("t_mrt")
    if not (0.5 <= v10 <= 17):            flags.append("v10")
    if p_a > 5.0:                          flags.append("p_a")

    t_mrt_c = np.clip(t_mrt, t_a - 30, t_a + 70)
    v10_c = np.clip(v10, 0.5, 17.0)

    return utci(tdb=t_a, tr=t_mrt_c, v=v10_c, rh=rh), t_mrt, flags


# Plausibilitätsprüfung gegen Abschnitt 5.2
if __name__ == "__main__":
    sun = utci_tile(30, 50, 1.0, 60, 900, 70, 850, 1.0, 0.0)
    shade = utci_tile(30, 50, 1.0, 60, 900, 150, 150, 0.0, 0.0)
    print(f"Sonne:    T_mrt={sun[1]:.1f} °C   UTCI={sun[0]:.1f} °C")
    print(f"Schatten: T_mrt={shade[1]:.1f} °C   UTCI={shade[0]:.1f} °C")
    # erwartet: T_mrt ≈ 58.5 bzw. 34.0 °C
```

---

## 10. Fehlerbudget

Nach Wirkung auf den UTCI sortiert — das bestimmt, wo Entwicklungsaufwand hingehört:

| Fehlerquelle | typische Größe | Wirkung auf UTCI | Gegenmaßnahme |
|---|---|---|---|
| T_a Körperwärme, unkorrigiert | +2 … +5 K | **+2 … +5 K** | Selbstkalibrierung 3.1, thermische Entkopplung |
| Sonne/Schatten falsch klassifiziert | ±25 K in T_mrt | **±6 … +8 K** | `f_sun` aus Spektralmerkmalen (5.3) |
| Wind: Stationsdistanz + Urbanität | Faktor 0.4 … 2 | ±3 … 8 K (kalt), ±1 K (warm) | `c_urban` dokumentieren, Unsicherheit anzeigen |
| T_mrt-Modellkonstanten (ρ_g, k_grd, α_k) | ±5 K in T_mrt | ±1.5 K | Parameter kalibrierbar halten |
| G_h aus Modell statt Messung | ±15 % | ±1 K | Open-Meteo Direkt/Diffus statt Separationsmodell |
| RH (SHTC3 ±2 %) | ±2 %RH | **< 0.3 K** | nichts — irrelevant |

Die Reihenfolge ist die eigentliche Aussage: **Körperwärme-Korrektur und Schattenerkennung entscheiden über die Brauchbarkeit der Kachel.** Alles darunter ist Feinschliff. Ein Gerät mit perfekt kalibriertem SHTC3, aber ohne ΔT_body-Korrektur, liefert schlechtere UTCI-Werte als eines mit mittelmäßigem Sensor und sauberer Korrektur.

---

## 11. Validierung

| Test | Vorgehen | Kriterium |
|---|---|---|
| Polynom-Portierung | 10 000 Zufallspunkte im Gültigkeitsbereich gegen `pythermalcomfort` | max. Abweichung < 0.01 K |
| T_mrt-Modell | Zahlenbeispiel 5.2 nachrechnen | 58.5 / 34.0 °C ±0.5 K |
| T_mrt gegen Referenz | Schwarzkugelthermometer (40 mm) neben dem Badge, 4 h wechselnde Bedingungen | Bias < 3 K, RMSE < 6 K |
| `f_sun` | 50 manuell gelabelte Sonne/Schatten-Wechsel | Trefferquote > 90 % |
| ΔT_body | Referenzthermometer im Schatten, Badge getragen, 24 h | Bias < 1 K nach Korrektur |
| Wind | TAWES-Nachbarstation gegen Handanemometer am Standort | `c_urban` bestimmen |
| End-to-End | 14-Tage-Log gegen INCA-Reanalyse am selben Ort | systematische Abweichung dokumentieren |

Der Schwarzkugel-Vergleich ist der einzige Test, der das T_mrt-Modell wirklich prüft. Eine 40-mm-Kugel (schwarz lackierter Tischtennisball, NTC innen) kostet nichts und ist nach ISO 7726 auswertbar:

```
T_mrt = [ (T_g+273.15)⁴ + (1.10e8 · v^0.6)/(ε · D^0.4) · (T_g − T_a) ]^0.25 − 273.15
```

mit `D` = 0.04 m, `ε` = 0.95. Nicht am Körper montieren — auf ein Stativ daneben.

---

## 12. Offene Punkte

1. **Magnetometer entscheiden.** LIS2MDL am LSM6DSOX-Sensor-Hub kostet ~2 mm² und 50 µA und hebt den TSL2591 von einem Schattendetektor zu einem echten Strahlungssensor. Vor dem Layout klären.
2. **Parameterkürzel** von `tawes-v1-10min` und `nowcast-v1-15min-1km` über die jeweiligen `/metadata`-Endpunkte verifizieren; nur für `inca-v1-1h-1km` sind sie hier belegt.
3. **INCA-Nachlauf messen.** Der tatsächliche Verzug entscheidet, ob INCA auch für eine „gestern"-Ansicht taugt oder rein retrospektiv bleibt.
4. **Wolkenbedeckung** `c` — Quelle festlegen (Open-Meteo `cloud_cover`); alternativ aus dem Verhältnis gemessener zu clear-sky-Globalstrahlung schätzen, was ohne Azimut wieder am Orientierungsproblem scheitert.
5. **Bodenalbedo `ρ_g` und `k_grd`** kontextabhängig machen? Schnee (ρ_g = 0.7) verschiebt T_mrt im Winter erheblich. Einfachste Lösung: Schneeflag aus `snowgrid_cl-v2-1d-1km` oder aus T_a-Historie plus Niederschlag.
6. **Lizenzhinweis.** Beide Datenquellen stehen unter CC BY 4.0 — Namensnennung von GeoSphere Austria bzw. Open-Meteo gehört in die App.
