# Accounting Ledger – Setup Guide

## Requirements
- Flutter 3.2+ / Dart 3.2+
- Android SDK 21+ / iOS 12+

## Installation
```bash
cd accounting_ledger
flutter pub get
flutter run
```

## Android Permissions (android/app/src/main/AndroidManifest.xml)
Add inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

Add inside `<application>`:
```xml
<activity android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```

## iOS Permissions (ios/Runner/Info.plist)
```xml
<key>NSFaceIDUsageDescription</key>
<string>Used for biometric authentication</string>
<key>NSMicrophoneUsageDescription</key>
<string>Used for voice input of transactions</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Used for voice input of transactions</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Used for attaching receipts</string>
<key>NSCameraUsageDescription</key>
<string>Used for capturing receipts</string>
```

## Features
- ✅ PIN & Biometric Authentication
- ✅ Multi-account management
- ✅ Income / Expense / Transfer transactions
- ✅ Multi-currency support (15 currencies)
- ✅ Recurring transactions (daily/weekly/monthly/yearly)
- ✅ Installment payment plans
- ✅ PDF & Excel export
- ✅ Pie charts by category
- ✅ Local SQLite database
- ✅ Backup & Restore (JSON)
- ✅ Arabic & English (RTL support)
- ✅ Dark / Light / System theme
- ✅ Voice input with AI category suggestion
- ✅ Share reports
