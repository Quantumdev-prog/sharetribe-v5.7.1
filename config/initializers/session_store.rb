# Be sure to restart your server when you modify this file.

# Pick the session domain from APP_CONFIG. (Removing the possible port in the end)
if APP_CONFIG.domain
  domain = APP_CONFIG.domain.split(":")[0]
else
  domain = ""
end

session_key = APP_CONFIG.session_key || 'kassi_session'

Rails.application.config.session_store :cookie_store, :key => session_key, :domain => domain, :expire_after => 1.years

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# Rails.application.config.session_store :active_record_store
