#require 'factory_girl'

class MailPreview < MailView

  #FactoryGirl.find_definitions
  # Using factory girl here was problematic as we didn't want to store anything to DB and
  # some factories (person) was set up so that simple build without storing anything was not easy.

  def new_payment
    # instead of mock data, show last suitable payment
    payment = CheckoutPayment.last
    throw "No CheckoutPayments in DB, can't show this mail template." if payment.nil?
    community = payment.community

    PersonMailer.new_payment(payment, community)
  end

  def payment_settings_reminder
    recipient = Struct.new(:id, :given_name_or_username, :confirmed_notification_emails_to, :new_email_auth_token, :locale).new("123", "Test Recipient", "test@example.com", "123-abc", "en")
    listing = Struct.new(:id, :title).new(123, "Hammer")
    payment_gateway = Class.new()
    payment_gateway.define_singleton_method(:settings_url) { |*args| "http://marketplace.example.com/payment_settings_url" }
    community = Struct.new(:full_domain, :name, :full_name, :custom_email_from_address, :payment_gateway).new('http://marketplace.example.com', 'Example Marketplace', 'Example Marketplace', 'marketplace@example.com', payment_gateway)
    community.define_singleton_method(:payments_in_use?) { true }

    PersonMailer.payment_settings_reminder(listing, recipient, community)
  end

  def receipt_to_payer
    payment = CheckoutPayment.last
    throw "No CheckoutPayments in DB, can't show this mail template." if payment.nil?
    community = payment.community
    PersonMailer.receipt_to_payer(payment, community)
  end

  def braintree_receipt_to_payer
    recipient = Struct.new(:id, :given_name_or_username).new("123", "Test Recipient")

    # instead of mock data, show last suitable payment
    payment = BraintreePayment.last
    throw "No BraintreePayments in DB, can't show this mail template." if payment.nil?
    community = payment.community
    PersonMailer.braintree_receipt_to_payer(payment, community)
  end

  def braintree_new_payment
    author = FactoryGirl.build(:person)
    starter = FactoryGirl.build(:person)
    payment_gateway = FactoryGirl.build(:braintree_payment_gateway)
    community = FactoryGirl.build(:community, payment_gateway: payment_gateway, custom_color1: "FF0099")
    payment = FactoryGirl.build(:braintree_payment, payment_gateway: payment_gateway, payer: starter, recipient: author)
    listing = FactoryGirl.build(:listing, author: author)

    conversation = FactoryGirl.build(:listing_conversation, listing: listing, payment: payment, participants: [author, starter])
    payment.conversation = conversation

    PersonMailer.braintree_new_payment(conversation.payment, community)
  end

  def escrow_canceled
    author = FactoryGirl.build(:person)
    starter = FactoryGirl.build(:person)
    payment_gateway = FactoryGirl.build(:braintree_payment_gateway)
    community = FactoryGirl.build(:community, payment_gateway: payment_gateway, custom_color1: "FF0099")
    payment = FactoryGirl.build(:braintree_payment, payment_gateway: payment_gateway, payer: starter, recipient: author)
    listing = FactoryGirl.build(:listing, author: author)

    conversation = FactoryGirl.build(:listing_conversation, listing: listing, payment: payment, participants: [author, starter])
    payment.conversation = conversation

    PersonMailer.escrow_canceled(conversation, community)
  end

  def confirm_reminder
    author = FactoryGirl.build(:person)
    starter = FactoryGirl.build(:person)
    payment_gateway = FactoryGirl.build(:braintree_payment_gateway)
    community = FactoryGirl.build(:community, payment_gateway: payment_gateway, custom_color1: "FF0099")
    payment = FactoryGirl.build(:braintree_payment, payment_gateway: payment_gateway, payer: starter, recipient: author)
    listing = FactoryGirl.build(:listing, author: author)

    conversation = FactoryGirl.build(:listing_conversation, community: community, listing: listing, payment: payment, participants: [author, starter])
    payment.conversation = conversation

    # Show different template if hold_in_escrow is true
    conversation.community.payment_gateway = nil
    PersonMailer.confirm_reminder(conversation, conversation.requester, conversation.community, 4)
  end

  def confirm_reminder_escrow
    author = FactoryGirl.build(:person)
    starter = FactoryGirl.build(:person)
    payment_gateway = FactoryGirl.build(:braintree_payment_gateway)
    community = FactoryGirl.build(:community, payment_gateway: payment_gateway, custom_color1: "FF0099")
    payment = FactoryGirl.build(:braintree_payment, payment_gateway: payment_gateway, payer: starter, recipient: author)
    listing = FactoryGirl.build(:listing, author: author)

    conversation = FactoryGirl.build(:listing_conversation, community: community, listing: listing, payment: payment, participants: [author, starter])
    payment.conversation = conversation

    # Show different template if hold_in_escrow is true
    conversation.community.payment_gateway = BraintreePaymentGateway.new
    PersonMailer.confirm_reminder(conversation, conversation.requester, conversation.community, 5)
  end

  def admin_escrow_canceled
    author = FactoryGirl.build(:person)
    starter = FactoryGirl.build(:person)
    payment_gateway = FactoryGirl.build(:braintree_payment_gateway)


    admin_email = FactoryGirl.build(:email, address: "admin@marketplace.com")
    admin = FactoryGirl.build(:person, emails: [admin_email])
    community_membership = FactoryGirl.build(:community_membership, person: admin, admin: true)

    community = FactoryGirl.build(:community, payment_gateway: payment_gateway, custom_color1: "FF0099", admins: [admin])


    community.community_memberships << community_membership

    payment = FactoryGirl.build(:braintree_payment, payment_gateway: payment_gateway, payer: starter, recipient: author)
    listing = FactoryGirl.build(:listing, author: author)

    conversation = FactoryGirl.build(:listing_conversation, community: community, listing: listing, payment: payment, participants: [author, starter])
    payment.conversation = conversation

    PersonMailer.admin_escrow_canceled(conversation, community)
  end

  def transaction_confirmed
    author = FactoryGirl.build(:person)
    starter = FactoryGirl.build(:person)
    payment_gateway = FactoryGirl.build(:braintree_payment_gateway)
    community = FactoryGirl.build(:community, payment_gateway: payment_gateway, custom_color1: "FF0099")
    payment = FactoryGirl.build(:braintree_payment, payment_gateway: payment_gateway, payer: starter, recipient: author)
    listing = FactoryGirl.build(:listing, author: author)

    message = FactoryGirl.build(:message, sender: starter)

    conversation = FactoryGirl.build(:listing_conversation, community: community, listing: listing, payment: payment, participants: [author, starter], messages: [message])
    payment.conversation = conversation

    PersonMailer.transaction_confirmed(conversation, community)
  end

  def transaction_automatically_confirmed
    author = FactoryGirl.build(:person)
    starter = FactoryGirl.build(:person)
    payment_gateway = FactoryGirl.build(:braintree_payment_gateway)
    community = FactoryGirl.build(:community, payment_gateway: payment_gateway, custom_color1: "FF0099")
    payment = FactoryGirl.build(:braintree_payment, payment_gateway: payment_gateway, payer: starter, recipient: author)
    listing = FactoryGirl.build(:listing, author: author)

    message = FactoryGirl.build(:message, sender: starter)

    conversation = FactoryGirl.build(:listing_conversation, community: community, listing: listing, payment: payment, participants: [author, starter], messages: [message])
    payment.conversation = conversation

    PersonMailer.transaction_automatically_confirmed(conversation, community)
  end

  def conversation_status_changed
    author = FactoryGirl.build(:person)
    starter = FactoryGirl.build(:person)
    payment_gateway = FactoryGirl.build(:braintree_payment_gateway)
    community = FactoryGirl.build(:community, payment_gateway: payment_gateway, custom_color1: "FF0099")
    payment = FactoryGirl.build(:braintree_payment, id: 55, payment_gateway: payment_gateway, payer: starter, recipient: author)
    listing = FactoryGirl.build(:listing, author: author)

    message = FactoryGirl.build(:message, sender: starter, id: 123)

    conversation = FactoryGirl.build(:listing_conversation, id: 99, community: community, listing: listing, payment: payment, participants: [author, starter], messages: [message])
    conversation.transaction_transitions << FactoryGirl.build(:transaction_transition, to_state: "accepted")
    payment.conversation = conversation

    PersonMailer.conversation_status_changed(conversation, community)
  end

  def community_updates
    author = FactoryGirl.build(:person)
    starter = FactoryGirl.build(:person)
    recipient = FactoryGirl.build(:person)
    payment_gateway = FactoryGirl.build(:braintree_payment_gateway)
    community = FactoryGirl.build(:community, payment_gateway: payment_gateway, custom_color1: "FF0099", members: [recipient])
    payment = FactoryGirl.build(:braintree_payment, id: 55, payment_gateway: payment_gateway, payer: starter, recipient: author)
    listing = FactoryGirl.build(:listing, author: author, id: 123)

    message = FactoryGirl.build(:message, sender: starter, id: 123)

    conversation = FactoryGirl.build(:listing_conversation, id: 99, community: community, listing: listing, payment: payment, participants: [author, starter], messages: [message])
    conversation.transaction_transitions << FactoryGirl.build(:transaction_transition, to_state: "accepted")
    payment.conversation = conversation

    CommunityMailer.community_updates(recipient, community, [listing])
  end

  def transaction_preauthorized
    conversation = ListingConversation.find do |conversation|
      conversation.status == "preauthorized" && conversation.listing.transaction_type.preauthorize_payment?
    end
    TransactionMailer.transaction_preauthorized(conversation)
  end

    def transaction_preauthorized_reminder
    author = FactoryGirl.build(:person)
    starter = FactoryGirl.build(:person)
    recipient = FactoryGirl.build(:person)
    payment_gateway = FactoryGirl.build(:braintree_payment_gateway)
    community = FactoryGirl.build(:community, payment_gateway: payment_gateway, custom_color1: "FF0099", members: [recipient])
    payment = FactoryGirl.build(:braintree_payment, id: 55, payment_gateway: payment_gateway, payer: starter, recipient: author)
    listing = FactoryGirl.build(:listing, author: author, id: 123)

    message = FactoryGirl.build(:message, sender: starter, id: 123)

    participations = [FactoryGirl.build(:participation, person: author), FactoryGirl.build(:participation, person: starter, is_starter: true)]

    conversation = FactoryGirl.build(:listing_conversation, id: 99, community: community, listing: listing, payment: payment, participations: participations, participants: [author, starter], messages: [message])
    conversation.transaction_transitions << FactoryGirl.build(:transaction_transition, to_state: "accepted")
    payment.conversation = conversation

    TransactionMailer.transaction_preauthorized_reminder(conversation)
  end

  def new_listing_by_followed_person
    author = FactoryGirl.build(:person)
    starter = FactoryGirl.build(:person)
    recipient = FactoryGirl.build(:person)
    payment_gateway = FactoryGirl.build(:braintree_payment_gateway)
    community = FactoryGirl.build(:community, payment_gateway: payment_gateway, custom_color1: "FF0099", members: [recipient])
    payment = FactoryGirl.build(:braintree_payment, id: 55, payment_gateway: payment_gateway, payer: starter, recipient: author)
    listing = FactoryGirl.build(:listing, author: author, id: 123)

    message = FactoryGirl.build(:message, sender: starter, id: 123)

    conversation = FactoryGirl.build(:listing_conversation, id: 99, community: community, listing: listing, payment: payment, participants: [author, starter], messages: [message])
    conversation.transaction_transitions << FactoryGirl.build(:transaction_transition, to_state: "accepted")
    payment.conversation = conversation

    PersonMailer.new_listing_by_followed_person(listing, recipient, community)
  end
end
