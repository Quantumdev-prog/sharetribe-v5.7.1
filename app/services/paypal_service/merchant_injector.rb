module PaypalService
  module MerchantInjector
    def paypal_merchant
      @paypal_merchant ||= build_paypal_merchant
    end

    module_function

    def build_paypal_merchant
      PaypalService::Merchant.new(
        build_endpoint(APP_CONFIG),
        build_api_credentials(APP_CONFIG),
        PaypalService::Logger.new)
    end


    def build_endpoint(config)
      PaypalService::DataTypes.create_endpoint(config.paypal_endpoint)
    end

    def build_api_credentials(config)
      PaypalService::DataTypes.create_api_credentials(
        config.paypal_username,
        config.paypal_password,
        config.paypal_signature,
        config.paypal_app_id)
    end
  end
end
