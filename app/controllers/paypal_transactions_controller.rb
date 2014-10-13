class PaypalTransactionsController < ApplicationController
  include PaypalService::PermissionsInjector
  include PaypalService::MerchantInjector

  skip_before_filter :verify_authenticity_token
  skip_filter :check_email_confirmation, :dashboard_only

  before_filter do
    unless @current_community.paypal_enabled?
      render :nothing => true, :status => 400 and return
    end
  end

  DataTypePermissions = PaypalService::DataTypes::Permissions
  PaypalAccountCommand = PaypalService::PaypalAccount::Command
  PaypalAccountQuery = PaypalService::PaypalAccount::Query


  def paypal_checkout_order_success
    if params[:token].blank?
      flash[:error] = t("error_messages.paypal.generic_error")
      # TODO Log?
      return redirect_to root
    end

    paypal_token = PaypalService::Token::Query.for_token(params[:token])
    transaction_id = paypal_token[:transaction_id]

    if transaction_id.blank?
      flash[:error] = t("error_messages.paypal.generic_error")
      # TODO Log?
      return redirect_to root
    end

    listing_author_id = Transaction.find(transaction_id).author.id

    paypal_receiver = PaypalService::PaypalAccount::Query.personal_account(listing_author_id, @current_community.id)

    # get_express_checkout_details
    express_checkout_details_req = PaypalService::DataTypes::Merchant.create_get_express_checkout_details({
        receiver_username: paypal_receiver[:email],
        token: params[:token]
      })
    express_checkout_details_res = paypal_merchant.do_request(express_checkout_details_req)
    puts express_checkout_details_res


    # do_express_checkout_payment
    do_express_checkout_payment_req = PaypalService::DataTypes::Merchant.create_do_express_checkout_payment({
        receiver_username: paypal_receiver[:email],
        token: params[:token],
        payer_id: express_checkout_details_res[:payer_id],
        order_total: express_checkout_details_res[:order_total]
      })
    do_express_checkout_payment_res = paypal_merchant.do_request(do_express_checkout_payment_req)
    puts do_express_checkout_payment_res

    # do_authorization
    do_authorization_req = PaypalService::DataTypes::Merchant.create_do_authorization({
        receiver_username: paypal_receiver[:email],
        transaction_id: do_express_checkout_payment_res[:transaction_id],
        order_total: express_checkout_details_res[:order_total]
      })
    do_authorization_res = paypal_merchant.do_request(do_authorization_req)
    puts do_authorization_res

    # TODO: think this throug!
    MarketplaceService::Transaction::Command.transition_to(transaction_id, "preauthorized")
    return redirect_to person_transaction_path(:person_id => @current_user.id, :id => transaction_id)
  end

  def paypal_checkout_order_cancel
    binding.pry
  end

end
