class BraintreeAccountsController < ApplicationController

  before_filter do |controller|
    # FIXME Change copy text
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_change_profile_settings")
  end

  skip_filter :dashboard_only

  def edit
    render locals: { braintree_account: BraintreeAccount.find_by_person_id(@current_user.id) || BraintreeAccount.new(params[:braintree_account]) }
  end

  def save
    braintree_account = BraintreeAccount.find_by_person_id(@current_user.id)

    if braintree_account
      update(braintree_account)
    else
      create
    end
  end

  private

  def create
    braintree_account = BraintreeAccount.new(params[:braintree_account].merge(person: @current_user))
    success = braintree_account.save

    if success
      # FIXME Copy text
      flash[:notice] = "Successfully saved!"
      redirect_to braintree_settings_payment_path(@current_user)
    else
      flash[:error] = "Error in saving"
      render :edit, locals: { braintree_account: braintree_account }
    end
  end

  def update(braintree_account)
    braintree_account.update_attributes(params[:braintree_account])
    flash[:notice] = "Successfully updated!"
    redirect_to braintree_settings_payment_path(@current_user)
  end
end