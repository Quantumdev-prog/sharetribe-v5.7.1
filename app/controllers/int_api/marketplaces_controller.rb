class IntApi::MarketplacesController < ApplicationController

  skip_filter :single_community_only
  skip_filter :dashboard_only

  # Creates a marketplace and an admin user for that marketplace
  def create
    community = MarketplaceService::API::Marketplaces::create(params.slice(:marketplace_name, :marketplace_type, :marketplace_country, :marketplace_language))

    person_hash = {person: {
      given_name: params[:admin_first_name],
      family_name: params[:admin_last_name],
      email: params[:admin_email],
      password: params[:admin_password]
      },
      locale: params[:marketplace_language]
    }

    user = UserService::API::Users::create_user_and_make_a_member_of_community(person_hash, community)

    # create auth token for the new admin and return that with the link

    # Add user to mailchimp list

    response.status = 201
    render :json => ["Marketplace created."] and return
  end

  # This could be more logical in different controller, but as implementing
  # at this point only tiny int-api with 2 methods, using one controller
  def check_email_availability
    email = params[:email]
    render :json => ["email parameter missing"], :status => 400 and return if email.blank?

    response.status = 200
    render :json => {:email => email, :available => Email.email_available?(email)} and return
  end

end
