# Google Cloud Setup (5 minutes)

## 1. Create a project

1. Go to https://console.cloud.google.com/
2. Click **Select a project** → **New Project**
3. Name it `MeetingBuddy`, click **Create**

## 2. Enable the Calendar API

1. In your new project, go to **APIs & Services → Library**
2. Search for **Google Calendar API**
3. Click it → **Enable**

## 3. Create OAuth credentials

1. Go to **APIs & Services → Credentials**
2. Click **+ Create Credentials → OAuth client ID**
3. If prompted to configure the consent screen first:
   - Choose **External**, click **Create**
   - Fill in App name: `MeetingBuddy`, your email for support + developer fields
   - Click **Save and Continue** through Scopes and Test Users (no changes needed)
   - Add yourself as a Test User on the "Test users" step
   - Back on the Dashboard, click **+ Create Credentials → OAuth client ID** again
4. For **Application type**, choose **Desktop app**
5. Name it `MeetingBuddy Desktop`
6. Click **Create**

## 4. Copy your credentials

A dialog will show your **Client ID** and **Client Secret**.

Open `Sources/Config.swift` and paste them in:

```swift
static let googleClientID     = "123456789-abc.apps.googleusercontent.com"  // ← your value
static let googleClientSecret = "GOCSPX-xxxxxxxxxxxx"                        // ← your value
```

That's it — no redirect URI configuration needed in Google Console for Desktop apps using localhost.
