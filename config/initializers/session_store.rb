# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key => ENV['SESSION_KEY'] || 'ube',
  :secret => ENV['SESSION_SECRET'] || '08a3f5c2a37b8c0a468015fd92971c60e14ea8569d4235a1267615a46c5e1cafd64eabb56527fb7f514f3477bc4c037e1b5dedf67bca051b3130eedce4e71993',
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
