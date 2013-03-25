Feature: User accepts a transaction
  In order to announce to another user that I accept his offer or request
  As an author of a listing describing an offer or a request
  I want to be able to accept the conversation

  @javascript
  Scenario: User accepts an offer with message and closes the listing
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And there is favor request with title "Massage" from "kassi_testperson1"
    And there is a message "I offer this" from "kassi_testperson2" about that listing
    And I am logged in as "kassi_testperson1"
    When I follow "inbox-link"
    And I should see "1" within ".inbox-toggle"
    And I follow "Service offer: Massage"
    And I follow "Accept offer"
    And I fill in "conversation_message_attributes_content" with "Ok, sounds good!"
    And I press "Send message"
    Then I should see "Offer accepted"
    And I should see "Ok, sounds good!"
    And I should see "Mark completed" within ".conversation-status"
    When I follow "Massage"
    Then I should see "Request is closed"
    Then I should not see "Close request"
    When the system processes jobs
    Then "kassi_testperson1@example.com" should have 0 emails
    And "kassi_testperson2@example.com" should receive an email
    When I open the email
    Then I should see "has accepted your offer" in the email body
    When "8" days have passed
    And the system processes jobs
    Then "kassi_testperson1@example.com" should receive an email
    When I open the email
    Then I should see "You have not yet confirmed" in the email body
    And return to current time
  
  @javascript
  Scenario: User accepts a request without message and doesn't close the listing
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And there is favor offer with title "Massage" from "kassi_testperson1"
    And there is a message "I request this" from "kassi_testperson2" about that listing
    And I am logged in as "kassi_testperson1"
    When I follow "inbox-link"
    And I should see "1" within ".inbox-toggle"
    And I should see "Service request: Massage" within ".unread"
    When I follow "Accept request"
    And I choose "Update the listing later"
    And I press "Send message"
    Then I should see "Request accepted" 
    And I should see "to mark the request as completed" within ".conversation-status"
    When I follow "Massage"
    Then I should not see "Offer is closed"
    And I should see "Close offer"
  
