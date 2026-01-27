# Don't Forget 💳📍

**Gift card & voucher tracker with barcode scanning. Never let a card expire unused.**

## The Problem

- Gift cards sitting in your wallet, forgotten until they expire
- Can't find the card when you're at checkout
- No idea how much balance is left on each card
- Forget you have a card when passing by the store

## The Solution

Don't Forget is your **gift card wallet** with:
- 📸 **Barcode scanner** — scan cards for quick checkout
- 📷 **Card photos** — snap a pic, never dig through your wallet
- 💰 **Balance tracking** — know exactly what you have
- 📍 **Location alerts** — get reminded when you're near the store

> "You're near Target — don't forget your gift card! $35.50 remaining, expires in 3 days"

## Features

### 📸 Barcode Scanner
- Scan any barcode (QR, EAN, Code128, PDF417, etc.)
- Display barcode at checkout — no physical card needed
- Auto-brightness boost for easy scanning
- Manual entry fallback

### 💳 Card Photo Storage
- Take a photo of your card
- See it instantly when needed at checkout
- Never dig through your wallet again

### 💰 Balance Tracking
- Track remaining balance on each card
- See total value across all cards
- Quick-update after each use

### 📍 Location Alerts
- Set store locations for each card
- Get notified when you're nearby
- Combined with expiration warnings

### ⏰ Expiration Warnings
- 7-day, 3-day, and same-day alerts
- "Expiring Soon" tab for urgent cards
- Never let a card go to waste

### 🔒 100% Private
- No account required
- No cloud storage
- Everything stays on your device
- Camera used only for scanning/photos

## Screenshots

<p float="left">
  <img src="AppStore/screenshots/screenshot1.png" width="200" />
  <img src="AppStore/screenshots/screenshot2.png" width="200" />
  <img src="AppStore/screenshots/screenshot3.png" width="200" />
  <img src="AppStore/screenshots/screenshot4.png" width="200" />
</p>

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Camera (for barcode scanning & card photos)
- Location permissions (optional, for store alerts)

## Installation

1. Clone this repo
2. Open `DontForget.xcodeproj` in Xcode
3. Build and run
4. Allow camera and location permissions when prompted

## Tech Stack

- SwiftUI
- AVFoundation (barcode scanning)
- CoreImage (barcode generation)
- PhotosUI (image picker)
- CoreLocation (geofencing)
- UserNotifications
- MapKit (store search)
- UserDefaults (local storage)
- No external dependencies

## Privacy

- **Camera**: Used only for scanning barcodes and taking card photos
- **Location**: Used only for triggering reminders near stores (optional)
- **Storage**: All data stays on your device — we don't collect anything

## App Store

### Description
Never let a gift card expire unused! Don't Forget is your personal gift card wallet that keeps track of all your cards, balances, and expiration dates.

**Key Features:**
• Scan barcodes — show your phone at checkout instead of carrying cards
• Take card photos — see your card instantly when you need it
• Track balances — know exactly how much you have left
• Get location alerts — reminded when you're near the store
• Expiration warnings — 7-day, 3-day, and same-day notifications

Stop losing money to expired gift cards. Download Don't Forget today!

### Keywords
gift card, voucher, barcode scanner, wallet, tracker, expiration, reminder, balance

## License

MIT License - feel free to use, modify, and distribute.

## Author

Built by Yuxuan

---

**100% FREE** — No ads. No subscriptions. No catch.
