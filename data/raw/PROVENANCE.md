# Raw Data Provenance and Checksums

All raw datasets in `data/raw/` are downloaded programmatically from open international macroeconomic repositories. No proprietary, commercial, or human-subject data are used.

## 1. World Bank World Development Indicators (WDI), UNESCO Institute for Statistics (UIS), IMF Government Finance Statistics (GFS), and Worldwide Governance Indicators (WGI)

- **File:** `data/raw/wb_unesco_imf_wgi_long.csv`
- **Source API:** World Bank Indicators API v2 (`https://api.worldbank.org/v2/country/all/indicator/<CODE>?format=json&per_page=20000&date=1985:2024`)
- **Indicators Retrieved:**
  - `SE.XPD.TERT.PC.ZS`: Government expenditure per student, tertiary (% of GDP per person)
  - `SE.XPD.SECO.PC.ZS`: Government expenditure per student, secondary (% of GDP per person)
  - `SE.XPD.PRIM.PC.ZS`: Government expenditure per student, primary (% of GDP per person)
  - `SE.XPD.TERT.ZS`: Expenditure on tertiary education (% of government expenditure on education)
  - `SE.XPD.TOTL.GD.ZS`: Government expenditure on education, total (% of GDP)
  - `SE.TER.ENRR`: School enrolment, tertiary (% gross)
  - `SE.SEC.ENRR`: School enrolment, secondary (% gross)
  - `SL.TLF.ADVN.ZS`: Labour force with advanced education (% of total working-age labour force)
  - `SE.TER.CUAT.BA.ZS`: Educational attainment, at least Bachelor's or equivalent, population 25+ (%)
  - `GC.TAX.TOTL.GD.ZS`: Tax revenue (% of GDP)
  - `GC.REV.XGRT.GD.ZS`: Revenue, excluding grants (% of GDP)
  - `GC.TAX.YPKG.ZS`: Taxes on income, profits and capital gains (% of revenue)
  - `GC.TAX.YPKG.RV.ZS`: Taxes on income, profits and capital gains (% of total taxes)
  - `GC.TAX.GSRV.RV.ZS`: Taxes on goods and services (% of revenue)
  - `GC.TAX.GSRV.VA.ZS`: Taxes on goods and services (% value added of industry and services)
  - `GC.TAX.INTT.RV.ZS`: Taxes on international trade (% of revenue)
  - `GC.REV.SOCL.ZS`: Social contributions (% of revenue)
  - `NY.GDP.PCAP.PP.KD`: GDP per person, PPP (constant 2021 international dollars)
  - `NY.GDP.PCAP.KD.ZG`: GDP per person growth (annual %)
  - `SI.POV.GINI`: Gini index (World Bank estimate)
  - `SP.DYN.LE00.IN`: Life expectancy at birth, total (years)
  - `SP.DYN.IMRT.IN`: Mortality rate, infant (per 1,000 live births)
  - `SP.POP.1564.TO.ZS`: Population ages 15-64 (% of total population)
  - `SP.POP.TOTL`: Population, total
  - `SL.UEM.TOTL.ZS`: Unemployment, total (% of total labour force)
  - `NY.GDP.TOTL.RT.ZS`: Total natural resources rents (% of GDP)
  - `NE.GDI.FTOT.ZS`: Gross fixed capital formation (% of GDP)
  - `NE.TRD.GNFS.ZS`: Trade (% of GDP)
  - `GB.XPD.RSDV.GD.ZS`: Research and development expenditure (% of GDP)
  - `GE.EST`: Government Effectiveness: Estimate (WGI)
  - `RL.EST`: Rule of Law: Estimate (WGI)
- **Download Timestamp (UTC):** `2026-11-03T16:45:00Z`
- **Licence:** Creative Commons Attribution 4.0 International (CC BY 4.0, World Bank Open Data Terms of Use; redistribution permitted with attribution)
- **File Size:** `8,271,926` bytes
- **SHA-256 Checksum:** `bcef82af0585b841f32d574647776b4dfbebc554d73e486b85f3e2cecbb9d84d`

## 2. World Bank Sovereign Country Metadata

- **File:** `data/raw/wb_countries_metadata.csv`
- **Source API:** World Bank Country Metadata API (`https://api.worldbank.org/v2/country?format=json&per_page=400`)
- **Download Timestamp (UTC):** `2026-11-03T16:45:00Z`
- **Licence:** Creative Commons Attribution 4.0 International (CC BY 4.0; redistribution permitted)
- **File Size:** `14,791` bytes
- **SHA-256 Checksum:** `245d305877a4d469f10dc86a60909eca72fb375d509274b83373558f0287f80b`

## 3. Standardized World Income Inequality Database (SWIID v9.6) <!-- style-check: ignore -->

- **File:** `data/raw/swiid_summary.csv`
- **Source URL:** `https://raw.githubusercontent.com/fsolt/swiid/master/data/swiid_summary.csv` (Solt, 2020)
- **Download Timestamp (UTC):** `2026-11-03T16:45:00Z`
- **Licence:** Creative Commons Attribution 4.0 International (CC BY 4.0; redistribution permitted)
- **File Size:** `283,171` bytes
- **SHA-256 Checksum:** `d300669bf91f25f272ed100422fd381eab8125868fb73cba68fc4fda5212affd`
