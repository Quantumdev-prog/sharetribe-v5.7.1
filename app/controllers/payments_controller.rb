class PaymentsController < ApplicationController
  
  include MathHelper
  
  before_filter :payment_can_be_conducted
  
  before_filter :only => [ :new ] do |controller|
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_view_your_inbox")
  end
  
  skip_filter :dashboard_only
  
  def new
    @conversation = Conversation.find(params[:message_id])
    @payment = @conversation.payment  #This expects that each conversation already has a (pending) payment at this point
    
    @payment_gateway = @current_community.payment_gateways.first
    @payment_data = @payment_gateway.payment_data(@payment, 
                :return_url => done_person_message_payment_url(:id => @payment.id),
                :cancel_url => new_person_message_payment_url,
                :locale => I18n.locale,
                :mock => @current_community.settings["mock_cf_payments"])
    
  end
  
  def choose_method
    
  end
  
  def done
    @payment = Payment.find(params[:id])
    @payment_gateway = @current_community.payment_gateways.first
    
    check = @payment_gateway.check_payment(@payment, { :params => params, :mock =>@current_community.settings["mock_cf_payments"]})
    
    if check.nil? || check[:status].blank?
      flash[:error] = t("layouts.notifications.error_in_payment")
    elsif check[:status] == "paid"
      @payment.paid!
      flash[:notice] = check[:notice]
    else # not yet paid
      flash[:notice] = check[:notice]
      flash[:warning] = check[:warning]
      flash[:error] = check[:error]
    end

    redirect_to person_message_path(:id => params[:message_id])
  end
  
  
  private
  
  def payment_can_be_conducted
    @conversation = Conversation.find(params[:message_id])
    redirect_to person_message_path(@current_user, @conversation) unless @conversation.requires_payment?(@current_community)
  end
  
end