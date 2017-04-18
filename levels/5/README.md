# WaffleCopter

WaffleCopter is a new service delivering locally-sourced organic waffles hot
off of vintage waffle irons straight to your location using quad-rotor
GPS-enabled helicopters. The service is modeled after
[TacoCopter](http://tacocopter.com), an innovative and highly successful early
contender in the airborne food delivery industry. WaffleCopter is currently
being tested in private beta in select locations.

Your goal is to order one of the decadent Liège waffles, offered only to the
first premium subscribers of the service.

## The API

The WaffleCopter API is quite simple. All users have a secret API token that is
used to sign POST requests to /v1/orders. Parameters such as the waffle product
code and target GPS coordinates are encoded as if for a query string and placed
in the request body.

## The Code

You can use `client.rb` to talk to the API, specifying an appropriate API
endpoint, user id, and secret key. The app itself is `wafflecopter.rb`, which
will use a SQLite database created by `initialize_db.rb`. The page templates can be
found under `views/`.


## To run

- Install bundler: `gem install bundler`
- Run `bundle install`
- Run `ruby ./initialize_db.rb`
- Run `ruby ./wafflecopter.rb`
- Point your browser to [http://localhost:4567](http://localhost:4567)
