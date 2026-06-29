# Hadith Reader

A clean iOS reader for the major hadith collections — a daily narration, browsable
collections, and bookmarks. Built on [AppFactoryKit](https://github.com/ZubeidHendricks/AppFactoryKit).

**36,000+ hadiths** across 9 complete collections, **bilingual (Arabic + English)**, bundled
offline: Sahih al-Bukhari, Sahih Muslim, Sunan Abi Dawud, Jami' at-Tirmidhi, Sunan an-Nasa'i,
Sunan Ibn Majah, Muwatta Malik, 40 Hadith Nawawi, 40 Hadith Qudsi. (Bukhari & Muslim free; the
rest unlock with Pro.) Data: open public-domain `fawazahmed0/hadith-api`, loaded per-collection
on demand for fast launch.

## Features
- **Hadith of the Day** — an authentic narration daily, with narrator and source citation
- **Browse by collection** with proper references (e.g. *Sahih al-Bukhari 1*)
- **Bookmarks** with a daily reminder
- Native **StoreKit 2** subscriptions (no third-party SDK)

## Build
```bash
brew install xcodegen
cd HadithReader
xcodegen generate
open HadithReader.xcodeproj
```

## Tests
`xcodebuild test -scheme Tests -destination 'platform=iOS Simulator,name=iPhone 17'` — verifies
the library integrity, daily selection, citation format, and free/Pro collection gating (5/5 pass).

> Narration texts are widely-known authentic hadiths with standard reference numbers, included
> as a starter set; expand the library in `Sources/Hadiths.swift`.
