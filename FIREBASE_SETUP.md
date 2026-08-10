# Firebase Push Notification Setup

Code দুই দিকেই বসানো আছে (backend already ছিল, app-এ এখন যোগ করলাম)।
কাজ চালু করতে তোমার শুধু এই manual steps লাগবে — কোনো ফাইল Claude বসাতে পারবে না
কারণ এগুলো তোমার Firebase account-specific secret/config ফাইল।

## 1. Firebase project (যদি না থাকে)

1. https://console.firebase.google.com → Add project → "ClassyBattle"
2. Android app যোগ করো — package name দিতে হবে ঠিক এটা:
   `com.classybattle.app`
   (Classybattle-app/android/app/build.gradle.kts এ `applicationId` দেখে confirm করলাম)

## 2. App-side: google-services.json

1. Firebase console থেকে `google-services.json` ডাউনলোড করো
2. রাখো এখানে: `Classybattle-app/android/app/google-services.json`
   (এই ফাইলটা .gitignore-এ রাখা ভালো — commit কোরো না, private key জাতীয় কিছু না থাকলেও app config leak করা ঠিক না)
3. Build files ইতিমধ্যে ready:
   - `android/settings.gradle.kts` → `com.google.gms.google-services` plugin যোগ করা আছে
   - `android/app/build.gradle.kts` → plugin apply করা আছে
4. `flutter pub get` চালাও (firebase_core, firebase_messaging, flutter_local_notifications ইতিমধ্যে pubspec.yaml-এ আছে)

## 3. Backend-side: service account credentials

Backend-এ `app/notifications/push_service.py` ইতিমধ্যে পুরো FCM sending logic
নিয়ে রেডি — শুধু credential ফাইল দরকার।

1. Firebase console → Project settings → Service accounts → "Generate new private key"
   → এটা একটা JSON ফাইল ডাউনলোড হবে
2. Render dashboard → তোমার classybattle service → Environment → "Secret Files"
   → path দাও: `firebase-service-account.json` → content এ পুরো JSON paste করো
3. Backend settings (`app/config/settings.py`) default path ধরেই আছে:
   ```
   FIREBASE_CREDENTIALS_PATH: str = "firebase-service-account.json"
   ```
   তাই আলাদা env var লাগবে না, Secret File path মিলে গেলেই কাজ করবে।
4. Redeploy করলে startup log-এ দেখবে:
   `firebase_initialized project_id=...`
   এটা না দেখালে বুঝবে credential path/format ভুল আছে।

## 4. Test

1. App-এ login করো (device token ওই মুহূর্তে backend-এ auto-register হয়ে যাবে —
   `POST /notifications/device-tokens`)
2. Backend admin panel বা admin API দিয়ে broadcast পাঠাও:
   `POST /api/v1/admin/notifications/broadcast`
3. Phone-এ notification আসা উচিত — app foreground/background দুই অবস্থাতেই।

## Notes / caveats আমি backend review করে পেলাম

- `push_service.py`-তে `messaging.send()` synchronous call, event loop block করে —
  বেশি বড় broadcast-এ (হাজার হাজার user) সামান্য দেরি হতে পারে। এখনকার scale-এ সমস্যা না,
  ভবিষ্যতে `messaging.send_multicast` বা background task queue বিবেচনা কোরো।
- Invalid/expired FCM token পেলে backend সেটা device_tokens table থেকে auto-remove করে না —
  সময়ের সাথে dead token জমে পুশ পাঠানোর সময় ছোট delay বাড়াবে। ছোট cleanup job যোগ করা যায় (পরে করে দিতে পারি)।
- `notification_routes.py` device-token routes ঠিকভাবে static route-কে dynamic route-এর
  আগে রেখেছে (comment-এও লেখা আছে কেন) — এই bug আগেই এড়ানো হয়েছে, ভালো।
