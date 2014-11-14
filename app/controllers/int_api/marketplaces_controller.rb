class IntApi::MarketplacesController < ApplicationController

  skip_filter :single_community_only
  skip_filter :dashboard_only
  skip_filter :fetch_community

  before_filter :set_access_control_headers

  # Creates a marketplace and an admin user for that marketplace
  def create
    marketplace = MarketplaceService::API::Marketplaces::create(params.slice(:marketplace_name, :marketplace_type, :marketplace_country, :marketplace_language))

    person_hash = {person: {
      given_name: params[:admin_first_name],
      family_name: params[:admin_last_name],
      email: params[:admin_email],
      password: params[:admin_password]
      },
      locale: params[:marketplace_language]
    }

    user = UserService::API::Users::create_user_with_membership(person_hash, marketplace[:id])

    auth_token = AuthToken.create(:person_id => user[:id], :expires_at => 10.minutes.from_now, :token_type => "login")
    url = marketplace[:url] + "?auth=" + auth_token.token

    # TODO Add user to mailchimp list

    # TODO handle error cases with proper response

    response.status = 201
    render :json => {"marketplace_url" => url} and return
  end

  # This could be more logical in different controller, but as implementing
  # at this point only tiny int-api with 2 methods, using one controller
  def check_email_availability
    email = params[:email]
    render :json => ["email parameter missing"], :status => 400 and return if email.blank?

    response.status = 200
    render :json => {:email => email, :available => (Email.email_available?(email))} and return
  end

  private

  def set_access_control_headers
    # TODO change this to more strict setting when done testing
    headers['Access-Control-Allow-Origin'] = '*'
  end

end
