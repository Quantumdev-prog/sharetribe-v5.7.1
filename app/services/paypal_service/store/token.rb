module PaypalService::Store::Token
  PaypalTokenModel = ::PaypalToken

  module Entity
    Token = EntityUtils.define_builder(
      [:community_id, :mandatory, :fixnum],
      [:token, :string, :mandatory],
      [:transaction_id, :fixnum, :mandatory],
      [:merchant_id, :string, :mandatory],
      [:item_name, :string],
      [:item_quantity, :fixnum],
      [:item_price, :money],
      [:express_checkout_url, :string, :mandatory]
    )

    module_function

    def from_model(model)
      Token.call(
        EntityUtils.model_to_hash(model).merge({
            item_price: model.item_price
        }))
    end
  end


  module_function

  def create(opts)
    PaypalToken.create!({
        community_id: opts[:community_id],
        token: opts[:token],
        transaction_id: opts[:transaction_id],
        merchant_id: opts[:merchant_id],
        item_name: opts[:item_name],
        item_quantity: opts[:item_quantity],
        item_price: opts[:item_price],
        express_checkout_url: opts[:express_checkout_url]
    })
  end

  def delete(community_id, transaction_id)
    PaypalTokenModel.where(community_id: community_id, transaction_id: transaction_id).destroy_all
  end

  def get(community_id, token)
    Maybe(PaypalTokenModel.where(token: token, community_id: community_id).first)
      .map { |model| Entity.from_model(model) }
      .or_else(nil)
  end

  def get_for_transaction(community_id, transaction_id)
    Maybe(PaypalTokenModel.where(community_id: community_id, transaction_id: transaction_id).first)
      .map { |model| Entity.from_model(model) }
      .or_else(nil)
  end
end
