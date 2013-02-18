# Session Check

Checks every 10 sec to see if your session has expired and boots you to the sign in page if it is.

# Usage

Include the gem in your Gemfile

    gem 'session-check'

Include the helper tag in your layout.erb, anywhere in the _<head>_ tag.

    <%= session_check %>

You're done.

# How it works

A JS timeout checks a value supplied from your Devise config, and when it determines that the Devise session has expired,
it takes the user to the sign in page. A global AJAX listener ensures AJAX heavy apps are catered for, by listening to each
request and resetting the counter for you.