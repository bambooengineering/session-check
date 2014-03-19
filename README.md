# Session Check

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

# Changelog

Version 0.2.1 : Added explicit reference to Devise (which is required)