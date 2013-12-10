Given /^there are following Braintree accounts:$/ do |bt_accounts|
  # Create new accounts
  bt_accounts.hashes.each do |hash|
    person = Person.find_by_username(hash[:person])
    @hash_account = FactoryGirl.create(:braintree_account, :person => person)
    
    attributes_to_update = hash.except('person')
    @hash_account.update_attributes(attributes_to_update) unless attributes_to_update.empty?
  end
end

Given /^there is an accepted request for "(.*?)" with price "(.*?)" from "(.*?)"$/ do |item_title, price, requester_username|
  community = Community.find_by_name("test") # Default testing community
  listing = Listing.find_by_title(item_title)
  requester = Person.find_by_username(requester_username)

  message = Message.new()
  message.sender = listing.author
  message.content = "Please pay"
  message.action = "accept"

  conversation = Conversation.new()
  conversation.messages << message
  conversation.participants << listing.author
  conversation.participants << requester
  conversation.status = "accepted"
  conversation.title = "Conversation title"

  payment = Payment.new()
  payment.payer = requester
  payment.recipient = listing.author
  payment.status = "pending"

  row = PaymentRow.new()
  row.sum_cents = price.to_i * 100
  row.currency = "EUR"

  payment.rows << row

  conversation.payment = payment
  community.payments << payment

  listing.conversations << conversation

  community.save!
  listing.save!
end

Then /^"(.*?)" should have required Checkout payment details saved to my account information$/ do |username|
  p = Person.find_by_username(username)

  p.checkout_merchant_id.should_not be_nil
  p.checkout_merchant_id.should_not be_blank
  p.checkout_merchant_key.should_not be_nil
  p.checkout_merchant_key.should_not be_blank
end

Given /^I want to pay "(.*?)"$/ do |item_title|
  steps %Q{Given I am on the messages page}
  steps %Q{Then I should see "Pay"} # This fails if there are many payments waiting
  steps %Q{When I follow "Pay"} # This fails if there are many payments waiting
end

Then /^I should be able to fill in my payment details for Braintree$/ do
  steps %Q{
    Then I should see payment details form for Braintree
    When I fill payment details for Braintree
    And I submit the payment
  }
end

Then /^I should be able to see that the payment was successful$/ do
  steps %Q{
    Then I should see "Your payment was successful"
  }
end

When /^I browse to payment settings$/ do
  steps %Q{
    When I go to the settings page
    Then the link to payment settings should be visible
    When I follow link to payment settings
    Then I should be on the payment settings page
  }
end

Then /^the link to payment settings should be visible$/ do
  find("#settings-tab-payments").should be_visible
end

When /^I follow link to payment settings$/ do
  steps %Q{
    When I follow "settings-tab-payments"
  }
end

When /^I fill the payment details form(?: with valid information)?$/ do
  steps %Q{
    When I fill in "person[company_id]" with "1234567-8"
    And I fill in "person[organization_address]" with "Startup Sauna, Betonimiehenkuja, Espoo, Finland"
    And I fill in "person[phone_number]" with "555-12345678"
    And I fill in "person[organization_website]" with "http://www.company.com/"
    And I press submit
  }
end

When /^I fill the payment details form with invalid information$/ do
  steps %Q{
    When I fill in "person[company_id]" with "12345465467484578"
    And I fill in "person[organization_address]" with ""
    And I fill in "person[phone_number]" with "555"
    And I fill in "person[organization_website]" with ""
    And I press submit
  }
end

Given /^"(.*?)" has Checkout account$/ do |org_username|
  org = Person.find_by_username(org_username)
  org.checkout_merchant_key = "SAIPPUAKAUPPIAS"
  org.checkout_merchant_id = "375917"
  org.save!
end

Given /^"(.*?)" does not have Checkout account$/ do |org_username|
  org = Person.find_by_username(org_username)
  org.checkout_merchant_key = nil
  org.checkout_merchant_id = nil
  org.save!
end

Then /^I should see information about existing Checkout account$/ do
  find("#payment-help-checkout-exists").visible?.should be_true
  steps %Q{
    And I should not see payment setting fields
  }
end

Then /^I should not see payment setting fields$/ do
  page.should have_no_selector("#person-company-id")
  page.should have_no_selector("#person-organization-address")
  page.should have_no_selector("#person-phone-number")
  page.should have_no_selector("#person-organization-website")
  page.should have_no_selector("[type=submit]")
end

When /^I click Osuuspankki logo$/ do
  page.find('input[src="https://payment.checkout.fi/static/img/osuuspankki.png"]').click
end

When /^I click Tilisiirto logo$/ do
  page.find('input[src="https://payment.checkout.fi/static/img/tilisiirto.gif"]').click
end

Then /^I should receive an email about missing payment details$/ do
  steps %Q{
    Then I should receive an email with subject "Remember to add your payment details to receive payments"
    When I open the email
    And I should see "However, you haven't yet added your payment details. In order to receive the payment you have to add your payment information." in the email body
  }
end