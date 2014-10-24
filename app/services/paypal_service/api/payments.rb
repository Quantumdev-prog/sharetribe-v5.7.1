module PaypalService::API

  class Payments
    # Injects a configured instance of the merchant client as paypal_merchant
    include PaypalService::MerchantInjector

    MerchantData = PaypalService::DataTypes::Merchant
    TokenStore = PaypalService::Store::Token

    def initialize(config, logger = PaypalService::Logger.new)
      @logger = logger
      @config = config
    end

    ## POST /payments/request
    def request(community_id, create_payment)
      with_account(
        community_id, create_payment[:merchant_id]
      ) do |m_acc|

        request = MerchantData.create_set_express_checkout_order(
          create_payment.merge({
              receiver_username: m_acc[:email],
              invnum: invnum(community_id, create_payment[:transaction_id])}))

        with_success(
          request,
          error_policy: {
            codes_to_retry: ["10001", "x-timeout", "x-servererror"],
            try_max: 3
          }
        ) do |response|
          TokenStore.create({
            community_id: community_id,
            token: response[:token],
            transaction_id: create_payment[:transaction_id],
            merchant_id: m_acc[:person_id],
            item_name: create_payment[:item_name],
            item_quantity: create_payment[:item_quantity],
            item_price: create_payment[:item_price] || create_payment[:order_total],
            express_checkout_url: response[:redirect_url]
          })

          Result::Success.new(
            DataTypes.create_payment_request({
                transaction_id: create_payment[:transaction_id],
                token: response[:token],
                redirect_url: response[:redirect_url]}))
        end
      end
    end

    ## POST /payments/request/cancel?token=EC-7XU83376C70426719
    def request_cancel(community_id, token_id)
      token = TokenStore.get(community_id, token_id)
      if(token.present?)
        #trigger callback for payment cancelled
        @config[:request_cancel].call(token)

        TokenStore.delete(community_id, token_id)
        Result::Success.new
      else
        #Handle errors by logging, because request cancellations are async (direct cancels + scheduling)
        @logger.warn("Tried to cancel non-existent request: [token: #{token_id}, community: #{community_id}]")
        Result::Error.new("Tried to cancel non-existent request: [token: #{token_id}, community: #{community_id}]")
      end
    end

    ## POST /payments/create?token=EC-7XU83376C70426719
    def create(community_id, token)
      with_token(community_id, token) do |token, m_acc|
        with_success(
          MerchantData.create_get_express_checkout_details(
            { receiver_username: m_acc[:email], token: token[:token] }
          ),
          error_policy: {
            codes_to_retry: ["10001", "x-timeout", "x-servererror"],
            try_max: 3
          }
        ) do |ec_details|

          # Validate that the buyer accepted and we have a payer_id now
          if (ec_details[:payer_id].nil?)
            return Result::Error.new("Payment has not been accepted by the buyer.")
          end

          with_success(
            MerchantData.create_do_express_checkout_payment({
              receiver_username: m_acc[:email],
              token: token[:token],
              payer_id: ec_details[:payer_id],
              order_total: ec_details[:order_total],
              item_name: token[:item_name],
              item_quantity: token[:item_quantity],
              item_price: token[:item_price],
              invnum: invnum(community_id, token[:transaction_id])
            }),
            error_policy: {
              codes_to_retry: ["10001", "x-timeout", "x-servererror"],
              try_max: 3
            }
          ) do |payment_res|
            # Save payment
            payment = PaypalService::PaypalPayment::Command.create(
              community_id,
              token[:transaction_id],
              ec_details.merge(payment_res))

            # Return as payment entity
            Result::Success.new(DataTypes.create_payment(payment.merge({ merchant_id: m_acc[:person_id] })))
          end
        end
      end
    end

    ## POST /payments/:community_id/:transaction_id/authorize
    def authorize(community_id, transaction_id, info)
      with_payment(community_id, transaction_id) do |payment, m_acc|
        with_success(
          MerchantData.create_do_authorization({
              receiver_username: m_acc[:email],
              order_id: payment[:order_id],
              authorization_total: info[:authorization_total]
          }),
          error_policy: {
            codes_to_retry: ["10001", "x-timeout", "x-servererror"],
            try_max: 5,
            finally: (method :void_failed_authorization).call(payment, m_acc)
          }
        ) do |auth_res|

          # Delete the token, we have now completed the payment request
          TokenStore.delete(community_id, transaction_id)

          # Save authorization data to payment
          payment = PaypalService::PaypalPayment::Command.update(community_id, transaction_id, auth_res)

          # Return as payment entity
          Result::Success.new(DataTypes.create_payment(payment.merge({ merchant_id: m_acc[:person_id] })))
        end
      end
    end

    ## POST /payments/:community_id/:transaction_id/full_capture
    def full_capture(community_id, transaction_id, info)
      with_payment(community_id, transaction_id) do |payment, m_acc|
        with_success(
          MerchantData.create_do_full_capture({
              receiver_username: m_acc[:email],
              authorization_id: payment[:authorization_id],
              payment_total: info[:payment_total],
              invnum: invnum(community_id, transaction_id)
          }),
          error_policy: {
            codes_to_retry: ["10001", "x-timeout", "x-servererror"],
            try_max: 5,
            finally: (method :void_failed_payment).call(payment, m_acc)
          }
        ) do |payment_res|

          # Save payment data to payment
          payment = PaypalService::PaypalPayment::Command.update(
            community_id,
            transaction_id,
            payment_res
          )

          # Return as payment entity
          Result::Success.new(DataTypes.create_payment(payment.merge({ merchant_id: m_acc[:person_id] })))
        end
      end
    end

    ## GET /payments/:community_id/:transaction_id
    def get_payment(community_id, transaction_id)
      with_payment(community_id, transaction_id) do |payment, m_acc|
        Result::Success.new(DataTypes.create_payment(payment.merge({ merchant_id: m_acc[:person_id] })))
      end
    end

    ## POST /payments/:community_id/:transaction_id/void
    def void(community_id, transaction_id, info)
      with_payment(community_id, transaction_id) do |payment, m_acc|
        with_success(
          MerchantData.create_do_void({
              receiver_username: m_acc[:email],
              # Always void the order, it automatically voids any authorization connected to the payment
              transaction_id: payment[:order_id],
              note: info[:note]
          }),
          error_policy: {
            codes_to_retry: ["10001", "x-timeout", "x-servererror"],
            try_max: 5
          }
        ) do |void_res|
          with_success(MerchantData.create_get_transaction_details({
            receiver_username: m_acc[:email],
            transaction_id: payment[:order_id],
          })) do |payment_res|
            payment = PaypalService::PaypalPayment::Command.update(
              community_id,
              transaction_id,
              payment_res)

            # Return as payment entity
            Result::Success.new(DataTypes.create_payment(payment.merge({ merchant_id: m_acc[:person_id] })))
          end
        end
      end
    end

    ## POST /payments/:community_id/:transaction_id/refund
    def refund(community_id, transaction_id)
      raise NoMethodError.new("Not implemented")
    end

    private

    def with_account(cid, pid, &block)
       m_acc = PaypalService::PaypalAccount::Query.personal_account(pid, cid)
      if m_acc.nil?
        Result::Error.new("Cannot find paypal account for the given community and person: community_id: #{cid}, person_id: #{pid}.")
      else
        block.call(m_acc)
      end
    end

    def with_token(cid, t, &block)
      token = TokenStore.get(cid, t)
      if (token.nil?)
        return Result::Error.new("No matching token for community_id: #{cid} and token: #{t}")
      end

      m_acc = PaypalService::PaypalAccount::Query.personal_account(token[:merchant_id], cid)
      if m_acc.nil?
        return Result::Error.new("No matching merchant account for community_id: #{cid} and person_id: #{token[:merchant_id]}.")
      end

      block.call(token, m_acc)
    end

    def with_payment(cid, txid, &block)
      payment = PaypalService::PaypalPayment::Query.get(cid, txid)
      if (payment.nil?)
        return Result::Error.new("No matching payment for community_id: #{cid} and transaction_id: #{txid}.")
      end

      m_acc = PaypalService::PaypalAccount::Query.for_payer_id(cid, payment[:receiver_id])
      if m_acc.nil?
        return Result::Error.new("No matching merchant account for community_id: #{cid} and transaction_id: #{txid}.")
      end

      block.call(payment, m_acc)
    end

    def with_success(request, opts = { error_policy: {} }, &block)
      retry_codes, try_max, finally = parse_policy(opts[:error_policy])
      response = try_operation(retry_codes, try_max) { paypal_merchant.do_request(request) }

      if (response[:success])
        block.call(response)
      else
        finally.call(request, response)
      end
    end

    def parse_policy(policy)
      [ policy.include?(:codes_to_retry) ? policy[:codes_to_retry] : [],
        policy.include?(:try_max) ? policy[:try_max] : 1,
        policy.include?(:finally) ? policy[:finally] : (method :log_and_return) ]
    end

    def try_operation(retry_codes, try_max, &op)
      result = op.call()
      attempts = 1

      while (!result[:success] && attempts < try_max && retry_codes.include?(result[:error_code]))
        result = op.call()
        attempts = attempts + 1
      end

      result
    end

    def log_and_return(request, err_response, data = {})
      @logger.warn("PayPal operation #{request[:method]} failed. Error code: #{err_response[:error_code]}, msg: #{err_response[:error_msg]}")
      Result::Error.new(
        "Failed response from Paypal. Error code: #{err_response[:error_code]}, msg: #{err_response[:error_msg]}",
        {paypal_error_code: err_response[:error_code]}.merge(data)
        )
    end

    def void_failed_authorization(payment, m_acc)
      -> (request, err_response) do
        if err_response[:error_code] == "10486"
          # Special handling for 10486 error. Return error response and do NOT void.
          token = PaypalService::Store::Token.get_for_transaction(payment[:community_id], payment[:transaction_id])
          redirect_url = append_order_id(token[:express_checkout_url], payment[:order_id])
          log_and_return(request, err_response, {redirect_url: "#{redirect_url}"})
        else
          void_failed_payment(payment, m_acc).call(request, err_response)
        end
      end
    end

    def void_failed_payment(payment, m_acc)
      -> (request, err_response) do
        with_success(
          MerchantData.create_do_void({
              receiver_username: m_acc[:email],
              # Always void the order, it automatically voids any authorization connected to the payment
              transaction_id: payment[:order_id]
            }),
          error_policy: {
            retry_codes: ["10001", "x-timeout", "x-servererror"],
            try_max: 3
          }
          ) do |void_res|
          with_success(
            MerchantData.create_get_transaction_details({
                receiver_username: m_acc[:email],
                transaction_id: payment[:order_id],
              }),
            error_policy: {
              retry_codes: ["10001", "x-timeout", "x-servererror"],
              try_max: 3
            }
            ) do |payment_res|
            payment = PaypalService::PaypalPayment::Command.update(
              payment[:community_id],
              payment[:transaction_id],
              payment_res)

            # Return original error
            log_and_return(request, err_response)
          end
        end
      end
    end

    def invnum(community_id, transaction_id)
      "#{community_id}-#{transaction_id}"
    end

    def append_order_id(url_str, order_id)
      URLUtils.append_query_param(url_str, "order_id", order_id)
    end

  end

end
