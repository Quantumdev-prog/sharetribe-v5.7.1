Feature: Seller creates an invoice with Braintree
  In order to get money from buyer
  As a seller
  I want to invoice the buyer with Braintree payments

  @javascript
  Scenario: User accepts a payment-requiring request and creates an invoice
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And community "test" has payments in use via Braintree
    And there is item offer with title "Power drill" from "kassi_testperson1" and with share type "sell" and with price "20.90"
    And there is a message "I request this" from "kassi_testperson2" about that listing
    And I am logged in as "kassi_testperson1"
    When I follow "inbox-link"
    Then I should see "1" within ".inbox-link"
    When I follow "Accept request"
    Then I should see "20.90" in the "conversation_payment_attributes_sum" input
    When I fill in "conversation_payment_attributes_sum" with "30"
    And I press "Send"
    Then I should see "Accepted" 
    And I should see "to pay" within ".conversation-status"
    When the system processes jobs
    Then "kassi_testperson2@example.com" should have 1 email
    When I open the email with subject "Your request was accepted"
    Then I should see "has accepted your request" in the email body
    When "4" days have passed
    And the system processes jobs
    Then "kassi_testperson2@example.com" should have 2 emails
    When I open the email with subject "Remember to pay"
    Then I should see "You have not yet paid" in the email body
    When "8" days have passed
    And the system processes jobs
    Then "kassi_testperson2@example.com" should have 3 emails
    When "100" days have passed
    And the system processes jobs
    Then "kassi_testperson2@example.com" should have 3 emails
    And return to current time