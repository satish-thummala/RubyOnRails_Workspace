# Meetings App

A simple Ruby on Rails application with a complete authentication system built from scratch using sessions and bcrypt (no Devise).

## Features

- ✅ User registration with validations
- ✅ Secure login / logout
- ✅ Password hashing with `bcrypt` via `has_secure_password`
- ✅ Session-based authentication
- ✅ Protected routes with `before_action :require_login`
- ✅ Flash messages for user feedback
- ✅ Profile page
- ✅ Clean, modern UI

## Requirements

- Ruby 3.2+
- Rails 7.1+
- SQLite3

## Setup & Run

```bash
# 1. Install dependencies
bundle install

# 2. Set up the database
rails db:create db:migrate db:seed

# 3. Start the server
rails server
```

Then open **http://localhost:3000** in your browser.

## Demo Account

After running `db:seed`, you can log in with:

- **Email:** `demo@example.com`
- **Password:** `password123`

## Project Structure

```
app/
├── controllers/
│   ├── application_controller.rb   # Auth helpers: current_user, logged_in?, require_login
│   ├── sessions_controller.rb      # Login / Logout
│   ├── users_controller.rb         # Registration & Profile
│   └── dashboard_controller.rb     # Protected dashboard
├── models/
│   └── user.rb                     # has_secure_password + validations
└── views/
    ├── sessions/new.html.erb        # Login page
    ├── users/new.html.erb           # Sign up page
    ├── users/show.html.erb          # Profile page
    ├── dashboard/index.html.erb     # Protected dashboard
    └── layouts/application.html.erb # Shared layout with nav

config/
└── routes.rb                        # GET/POST /login, /signup, /logout, /dashboard
```

## Routes

| Method | Path       | Action                 |
| ------ | ---------- | ---------------------- |
| GET    | /login     | Show login form        |
| POST   | /login     | Authenticate user      |
| DELETE | /logout    | Log out                |
| GET    | /signup    | Show registration form |
| POST   | /signup    | Create user account    |
| GET    | /profile   | Show user profile      |
| GET    | /dashboard | Protected dashboard    |
