# Zoom API Integration Setup

## Files to copy into your app

```
app/services/zoom_api_service.rb          ← NEW (create this folder/file)
app/controllers/zoom_meetings_controller.rb  ← REPLACE existing
config/initializers/zoom.rb               ← NEW
Gemfile                                   ← REPLACE existing
.env.example                              ← NEW (copy to .env and fill in)
```

---

## Step 1 — Create a Zoom Server-to-Server OAuth App

1. Go to [https://marketplace.zoom.us/develop/create](https://marketplace.zoom.us/develop/create)
2. Click **"Server-to-Server OAuth"**
3. Give your app a name (e.g. "Meetings App") → click **Create**
4. Go to the **"Scopes"** tab and add these scopes:
   - `meeting:write:admin`
   - `meeting:read:admin`
5. Go to **"App Credentials"** tab — copy:
   - Account ID
   - Client ID
   - Client Secret
6. Click **"Activate your app"**

---

## Step 2 — Add Credentials to your app

### Option A — Using .env file (easier for development)

```bash
# Copy the example file
cp .env.example .env
```

Edit `.env`:
```
ZOOM_ACCOUNT_ID=your_account_id_here
ZOOM_CLIENT_ID=your_client_id_here
ZOOM_CLIENT_SECRET=your_client_secret_here
```

Add `.env` to `.gitignore`:
```bash
echo ".env" >> .gitignore
```

### Option B — Using Rails credentials (more secure)

```bash
rails credentials:edit
```

Add this to the credentials file:
```yaml
zoom:
  account_id: "YOUR_ACCOUNT_ID"
  client_id: "YOUR_CLIENT_ID"
  client_secret: "YOUR_CLIENT_SECRET"
```

---

## Step 3 — Install gems and restart

```bash
bundle install
rails server
```

---

## How it works

When you create a meeting in the app:

1. The form is submitted → `ZoomMeetingsController#create` runs
2. It calls `ZoomApiService#create_meeting` which:
   - Gets an OAuth access token from Zoom
   - Posts the meeting data to `https://api.zoom.us/v2/users/me/meetings`
   - Returns the Zoom Meeting ID, Join URL, and Start URL
3. These are saved to the database automatically
4. The meeting list shows the **Join** button with the real Zoom link

If Zoom credentials are not set, meetings are still saved locally with a warning.

---

## What gets synced

| Action | Zoom API call |
|--------|--------------|
| Create meeting | `POST /users/me/meetings` |
| Edit meeting   | `PATCH /meetings/{id}` |
| Delete meeting | `DELETE /meetings/{id}` |
