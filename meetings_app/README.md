# 📅 Meetings App

A Ruby on Rails web application for scheduling and managing Zoom meetings, with built-in user authentication and real-time Zoom API integration.

---

## ✨ Features

### Authentication
- User registration with validations
- Secure login / logout using `bcrypt` and `has_secure_password`
- Session-based authentication (no Devise)
- Protected routes with `before_action :require_login`
- Flash messages for user feedback

### Zoom Meetings
- Create, edit, and delete meetings synced directly with Zoom API
- Support for all meeting types: Instant, Scheduled, Recurring
- Full settings: video, audio, waiting room, passcode, recording, recurrence
- Join URL and Start URL automatically saved from Zoom response
- Dashboard with upcoming and past meeting previews

### UI
- Clean sidebar navigation layout
- Responsive dashboard with meeting stats
- Quick actions panel
- Upcoming meetings list with Join buttons

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Ruby on Rails 7.1 |
| Database | SQLite3 |
| Auth | bcrypt + has_secure_password |
| API | Zoom Server-to-Server OAuth v2 |
| Frontend | ERB + Vanilla CSS |
| Server | Puma |

---

## ⚙️ Requirements

- Ruby 3.4+
- Rails 7.1+
- SQLite3
- A [Zoom Marketplace](https://marketplace.zoom.us) Server-to-Server OAuth app

---

## 🚀 Setup & Run

### 1. Install dependencies
```bash
bundle install
```

### 2. Configure Zoom credentials
Copy the example env file and fill in your Zoom credentials:
```bash
cp .env.example .env
```

Edit `.env`:
```
ZOOM_ACCOUNT_ID=your_account_id
ZOOM_CLIENT_ID=your_client_id
ZOOM_CLIENT_SECRET=your_client_secret
```

> See [Zoom API Setup](#-zoom-api-setup) below for how to get these values.

### 3. Set up the database
```bash
rails db:create db:migrate db:seed
```

### 4. Start the server
```bash
rails server
```

Open **http://localhost:3000** in your browser.

---

## 🔑 Demo Account

After running `db:seed`, log in with:

| Field | Value |
|-------|-------|
| Email | `demo@example.com` |
| Password | `password123` |

---

## 🔐 Zoom API Setup

1. Go to [marketplace.zoom.us/develop/create](https://marketplace.zoom.us/develop/create)
2. Select **Server-to-Server OAuth** and click **Create**
3. Go to the **Scopes** tab and add:
   - `meeting:write:meeting`
   - `meeting:write:meeting:admin`
   - `meeting:read:meeting`
   - `meeting:read:meeting:admin`
4. Go to **App Credentials** and copy your **Account ID**, **Client ID**, and **Client Secret**
5. Click **Activate your app**
6. Paste the values into your `.env` file

When a meeting is created in the app, it automatically calls the Zoom API and saves the **Meeting ID**, **Join URL**, and **Start URL** to the database.

---

## 📁 Project Structure

```
app/
├── controllers/
│   ├── application_controller.rb     # current_user, logged_in?, require_login
│   ├── sessions_controller.rb        # Login / Logout
│   ├── users_controller.rb           # Registration & Profile
│   ├── dashboard_controller.rb       # Protected dashboard
│   └── zoom_meetings_controller.rb   # Zoom meeting CRUD + API sync
├── models/
│   ├── user.rb                       # has_secure_password + validations
│   └── zoom_meeting.rb               # Meeting model with scopes & helpers
├── services/
│   └── zoom_api_service.rb           # Zoom API client (OAuth + REST)
└── views/
    ├── sessions/                     # Login page
    ├── users/                        # Sign up & Profile pages
    ├── dashboard/                    # Dashboard with stats & meeting preview
    ├── zoom_meetings/                # Meeting list, new, edit forms
    └── layouts/application.html.erb  # Sidebar layout with top nav

config/
├── routes.rb                         # All app routes
└── initializers/zoom.rb              # Zoom credential validation on boot
```

---

## 🗺 Routes

| Method | Path | Action |
|--------|------|--------|
| GET | `/login` | Show login form |
| POST | `/login` | Authenticate user |
| DELETE | `/logout` | Log out |
| GET | `/signup` | Show registration form |
| POST | `/signup` | Create user account |
| GET | `/profile` | User profile |
| GET | `/dashboard` | Protected dashboard |
| GET | `/zoom_meetings` | List all meetings |
| GET | `/zoom_meetings/new` | New meeting form |
| POST | `/zoom_meetings` | Create meeting + sync to Zoom |
| GET | `/zoom_meetings/:id/edit` | Edit meeting form |
| PATCH | `/zoom_meetings/:id` | Update meeting + sync to Zoom |
| DELETE | `/zoom_meetings/:id` | Delete meeting + remove from Zoom |
| PATCH | `/zoom_meetings/:id/cancel` | Cancel a meeting |

---

## 🔄 Zoom API Sync Behaviour

| App Action | Zoom API Call |
|------------|--------------|
| Create meeting | `POST /users/me/meetings` |
| Edit meeting | `PATCH /meetings/{id}` |
| Delete meeting | `DELETE /meetings/{id}` |

If Zoom credentials are missing or the API call fails, the meeting is still saved locally and a warning is shown — so the app works gracefully without Zoom configured.
