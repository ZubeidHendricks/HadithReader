# DailyDevotionalBible

Generated from niche `faith-devotional` (Faith, tier A, score 74).

**Utility:** Daily verses, devotionals, prayer log
**Primary ASO keyword:** `daily bible`
**Also target:** `devotional`, `bible verse`, `prayer app`, `daily verse`
**Paywall hook:** Full plans, audio, journaling, widgets, no ads

> Faith audiences show very high retention + willingness to subscribe.

## Build it

```bash
brew install xcodegen        # once
cd DailyDevotionalBible
xcodegen generate
open DailyDevotionalBible.xcodeproj
```

The app runs immediately on a MockPurchaseProvider (real paywall UI, fake
purchases). To go live:

1. Replace `revenueCatKey` in `Sources/App.swift` with your RevenueCat key.
2. In App Store Connect create products `faith-devotional_yearly` and `faith-devotional_weekly`,
   map them into a RevenueCat offering, entitlement id `premium`.
3. Build the real feature in `Sources/ContentView.swift`.
4. **Guideline 4.3:** make the function, UI, screenshots and keywords genuinely
   distinct from any sibling app. Re-niche, never reskin.

Bundle id: `com.zubeid.faithdevotional`

## Ship to TestFlight

This app ships with a Fastlane lane + GitHub Actions workflow. One-time account
setup (API key, signing) is documented in the kit's `Tools/appgen/DEPLOYMENT.md`.
Once your GitHub secrets are set, trigger the **TestFlight** workflow (or push a
`v*` tag), or run locally:

```bash
bundle install
bundle exec fastlane beta
```
