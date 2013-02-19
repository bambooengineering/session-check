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

No server ping requests are made, so there is no extra load on your server.