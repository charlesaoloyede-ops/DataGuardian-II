# Data Guardian — Backend Data Contract (Firebase)

This is the contract between the **Flutter app**, the **Firestore backend**, and the
**admin dashboard**. Build the backend/admin against this so the two sides stay in
sync. The app already writes feedback in this shape (see
`lib/features/feedback/`).

---

## 1. Auth model

- The app signs in with **Firebase Anonymous Auth** on first launch. This gives
  every install a stable `auth.uid` with **no PII**.
- The app also stores a locally-generated `installId` (`ins_<ts>_<rand>`) as a
  human-debuggable correlation key. `auth.uid` is the security key; `installId`
  is a convenience field.
- The **admin dashboard** signs in with a normal Firebase account that carries a
  custom claim `admin: true` (set once via the Admin SDK). All privileged reads
  and all reply writes are gated on that claim.

---

## 2. Collection: `feedback`

One document per submission. Auto-ID documents.

### Fields written by the **app** (immutable after create)

| Field         | Type      | Notes |
|---------------|-----------|-------|
| `message`     | string    | Required. The feedback text. |
| `category`    | string    | One of `bug` \| `suggestion` \| `question` \| `praise` \| `other`. |
| `email`       | string?   | Optional. Only present if the user opted to get a reply. |
| `uid`         | string    | `auth.uid` of the anonymous user. Set from the token, not client input. |
| `installId`   | string    | Anonymous per-install id, e.g. `ins_18f..._a3c9`. |
| `appVersion`  | string    | e.g. `1.0.0+1`. |
| `platform`    | string    | `android` (room for `ios` later). |
| `osVersion`   | string?   | e.g. `14`. (Populated once `device_info_plus` is added — see §6.) |
| `deviceModel` | string?   | e.g. `SM-A065F`. (Same as above.) |
| `createdAt`   | timestamp | **Server timestamp** (`FieldValue.serverTimestamp()`), authoritative. |
| `status`      | string    | App writes `"new"`. Only the backend may change it afterwards. |

### Fields written by the **backend / admin** (app can read, never write)

| Field       | Type      | Notes |
|-------------|-----------|-------|
| `status`    | string    | `new` → `read` → `replied`. |
| `reply`     | map?      | `{ text: string, repliedAt: timestamp, sentToEmail: bool }`. |
| `adminNote` | string?   | Internal triage note, **never** exposed to the app (see rules). |

> The app shows **"Reply sent to your email"** by reading back its own docs
> (where `uid == auth.uid`) and checking `reply.sentToEmail == true`. It never
> reads `adminNote`.

---

## 3. Reply → email flow

1. Admin opens a feedback doc in the dashboard and writes a reply.
2. Dashboard sets `reply = { text, repliedAt: serverTimestamp, sentToEmail: false }`
   and `status = "replied"`.
3. A **Cloud Function** `onFeedbackReply` triggers on that write:
   - If `email` is present and `reply.sentToEmail == false`, send the reply via
     **Resend** (or SendGrid), then set `reply.sentToEmail = true`.
   - If no `email`, leave `sentToEmail = false` (in-app only).
4. Next time the app reads its threads, it shows the reply and, when
   `sentToEmail == true`, the "Reply sent to your email" marker.

Keep the email provider key in Cloud Functions **environment config**, never in
the app or the dashboard bundle.

---

## 4. Security rules (starting point)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    function isAdmin() {
      return request.auth != null && request.auth.token.admin == true;
    }

    match /feedback/{id} {
      // Anyone signed in (anonymous ok) may create their own feedback.
      allow create: if request.auth != null
        && request.resource.data.uid == request.auth.uid
        && request.resource.data.status == 'new'
        && !('reply' in request.resource.data)
        && !('adminNote' in request.resource.data);

      // A user may read only their own docs; admins read everything.
      allow read: if isAdmin()
        || (request.auth != null && resource.data.uid == request.auth.uid);

      // Only admins may update (status / reply / adminNote). Nobody deletes.
      allow update: if isAdmin();
      allow delete: if false;
    }
  }
}
```

> Note: `adminNote` is not field-level hidden by these rules — a user reading
> their own doc would receive it. If you want it truly hidden, store admin notes
> in a **separate** `feedback_admin/{id}` collection that only admins can read.
> Recommended.

---

## 5. Analytics (opt-in)

- Behavioral/platform analytics uses **Firebase Analytics**, gated behind an
  explicit opt-in (`shareAnonymousAnalytics`, default **false**). See
  `lib/core/analytics/`.
- When the user opts in, the app calls
  `FirebaseAnalytics.setAnalyticsCollectionEnabled(true)` and logs the events in
  `AnalyticsEvents` (`lib/core/analytics/i_analytics_service.dart`). Opting out
  sets it back to `false`.
- The admin dashboard can read these from the Firebase Analytics console (or GA4
  / BigQuery export) — no custom collection needed initially.

---

## 6. App-side status / TODO when Firebase lands

- [ ] Add `firebase_core`, `cloud_firestore`, `firebase_auth`,
      `firebase_analytics` to `pubspec.yaml`; drop in `google-services.json`.
- [ ] `Firebase.initializeApp()` + anonymous sign-in in `main.dart`.
- [ ] Replace `FeedbackRepositoryImpl` (local queue) with
      `FirebaseFeedbackRepository`: on submit, write to `feedback`; on startup,
      drain `SharedPrefsService.drainPendingFeedback()` into Firestore.
- [ ] Add `FirebaseAnalyticsService implements IAnalyticsService`, gated by the
      opt-in flag; swap the DI binding off `NoOpAnalyticsService`.
- [ ] Add `package_info_plus` + `device_info_plus` to populate `appVersion`,
      `osVersion`, `deviceModel` (currently `appVersion` is a constant and the
      device fields are null).
- [ ] Update the Play Store **Data Safety** form + privacy policy to declare
      feedback text, optional email, and opt-in analytics.
