Feature: SMS compensation for ride match
  In order to pay compensation for gas expenses for the driver that offered a ride for me
  As a passenger
  I want to be able to pay the driver with SMS

  #NOTE: This feature is probably not possible with the first versions of Operator API:s. But this document can
  # be used to specify what kind of payment mechanism we would like to have when possible

  Scenario: Ride match was made and the passenger pays with SMS
    Given I got an SMS "Simo is driving from taik to tkk at 13:00. You can call him at 0501234567. To pay some gas money to Simo, reply 'SEND Xe' where X is the amount (max.90e)"
    And I took the ride and want to pay
    And My account has remaining at least 10,50 credits
    When I send SMS "SEND 10e"
    Then Simo's account should change +10e
    And My account should change -10,50e
