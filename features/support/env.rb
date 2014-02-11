# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a 
# newer version of cucumber-rails. Consider adding your own code to a new file 
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.

require 'rubygems'
require File.expand_path('../../../test/helper_modules', __FILE__)
include TestHelpers

require 'cucumber/rails'
require 'email_spec/cucumber'

tables_to_keep = %w[categories transaction_types category_transaction_types category_translations transaction_type_translations communities community_categories] 

# Uncomment this if needed to keep the browser open after the test
# Capybara::Selenium::Driver.class_eval do
#   def quit
#     puts "Press RETURN to quit the browser"
#     $stdin.gets
#     @browser.quit
#   rescue Errno::ECONNREFUSED
#     # Browser must have already gone
#   end
# end

# Capybara defaults to XPath selectors rather than Webrat's default of CSS3. In
# order to ease the transition to Capybara we set the default here. If you'd
# prefer to use XPath just remove this line and adjust any selectors in your
# steps to use the XPath syntax.
Capybara.default_selector = :css
Capybara.ignore_hidden_elements = true
# These settigs could be in prefork block, but Zeus wouldn't run that, so moved here.

# By default, any exception happening in your Rails application will bubble up
# to Cucumber so that your scenario will fail. This is a different from how 
# your application behaves in the production environment, where an error page will 
# be rendered instead.
#
# Sometimes we want to override this default behaviour and allow Rails to rescue
# exceptions and display an error page (just like when the app is running in production).
# Typical scenarios where you want to do this is when you test your error pages.
# There are two ways to allow Rails to rescue exceptions:
#
# 1) Tag your scenario (or feature) with @allow-rescue
#
# 2) Set the value below to true. Beware that doing this globally is not
# recommended as it will mask a lot of errors for you!
#
ActionController::Base.allow_rescue = false

# Ensure sphinx directories exist for the test environment
ThinkingSphinx::Test.init
# Configure and start Sphinx, and automatically
# stop Sphinx at the end of the test suite.
ThinkingSphinx::Test.start_with_autostop
# This makes tests bit slower, but it's better to use Zeus if wanting to keep sphinx running

# Populate db with default data
DatabaseCleaner.clean_with(:truncation)
load_default_test_data_to_db_before_suite

begin
  require 'database_cleaner'
  require 'database_cleaner/cucumber'

  DatabaseCleaner.strategy = :truncation, {:except => tables_to_keep}
  Cucumber::Rails::Database.javascript_strategy = :truncation, {:except => tables_to_keep}
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end

# Disable delta indexing as it is not needed and generates unnecessary delay and output
ThinkingSphinx::Deltas.suspend!

Before do
  # Populate db with default data
  DatabaseCleaner.clean_with(:truncation)
  load_default_test_data_to_db_before_suite
  load_default_test_data_to_db_before_test
  
  # Clear cache for each run as caching is not planned to work when DB contents are changing and communities are removed
  Rails.cache.clear
end

After do
  DatabaseCleaner.clean
end

