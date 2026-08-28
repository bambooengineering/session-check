Session Check
=========

[![Gem Version](https://img.shields.io/gem/v/session-check?color=green)](https://rubygems.org/gems/session-check)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A gem that returns you to your application's sign in page when your Devise session expires.

# Usage

Include the gem in your Gemfile...

    gem 'session-check'

... and include the helper tag in your layout.erb, anywhere in the _<head>_ tag.

    <%= session_check %>

You're done.

# How it works

A JS timeout checks a value supplied from your Devise config, and when it determines that the Devise session has expired,
it takes the user to the sign in page. A global AJAX listener ensures AJAX heavy apps are catered for, by listening to each
request and resetting the counter for you.

No server ping requests are made until the moment the session is expected to be expired, so there is no extra load on your server.

# Non-refreshing logins

If a user is not lot logged in, then no server pings will be perfomed. If, however, you application logs a user in without refreshing
their browser, you can start the ping process by calling:

    SessionCheck.should_session_check = true;

# Configuration

`logged_out_url` — the URL users are redirected to when their session expires. Defaults to `/users/sign_in`.

    Session::Check.configure do |config|
      config.logged_out_url = '/login'
      config.check_every_s = 30
    end

These can also be overridden per-call:

    <%= session_check logged_out_url: '/login', check_every_s: 30 %>

# Custom session detection

If your application uses a non-Devise session mechanism (e.g. token-based principals stored in the session hash),
you can override how the gem detects an active session by configuring a `session_active_proc`.

The proc receives the current context (controller in the ping endpoint, view/helper context in the `session_check` helper) and must return a Hash with two keys:
- `exists` — Boolean, whether an active session is present
- `expires_in` — Integer (seconds), how long until the session expires

    Session::Check.configure do |config|
      config.session_active_proc = ->(controller) {
        if controller.current_user
          # Devise-backed session
          expires_in = Session::Check::Devise.expires_in(controller.session)
          { exists: true, expires_in: expires_in }
        elsif controller.session[:my_custom_principal]
          { exists: true, expires_in: 3600 }
        else
          { exists: false, expires_in: 0 }
        end
      }
    end

When `session_active_proc` is configured it replaces the default `current_user` check in both the
server-side ping endpoint and the initial JS `should_session_check` value. All other behaviour
(check interval, AJAX counter reset, redirect URL) remains unchanged and configurable via the
`session_check` helper options.

If `session_active_proc` is not set the gem uses the default Devise behaviour, computing remaining session time from the Warden last-request timestamp.

# Development

The client-side JS lives in `app/assets/javascripts/session_check.js` as plain, dependency-free JS
so it can be unit tested in isolation. The `_session_check` partial only passes configuration in via
`window.SessionCheckConfig` and inlines this file's contents — no asset pipeline setup is required
by consuming applications.

JS unit tests (Jest + jsdom) live under `spec/javascript` and are scoped to this repo only —
`package.json`/`node_modules` are dev-only and excluded from the published gem. Run them with:

    npm install
    npm test

# Changelog

Version 2.0.1 : Fix session-expiry check drifting in background/inactive tabs
Version 2.0.0 : **Breaking change** — default Devise behaviour now correctly computes remaining session time from the Warden last-request timestamp rather than always returning the full timeout. `current_user` is no longer exposed to the session check partial. Added `session_active_proc` configuration option for non-Devise session support. Fixed setTimeout multiplier (5000 → 1000) so session checks fire at the correct interval. Bump your dependency to `>= 2.0.0`.
Version 1.1.0 : Added optional nonce
Version 0.2.1 : Added explicit reference to Devise (which is required)

## Licence

The gem is available as open source under the terms of the [MIT Licence](https://opensource.org/licenses/MIT).

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicence, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
