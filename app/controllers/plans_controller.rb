class PlansController < ApplicationController
  skip_before_filter :verify_authenticity_token, :fetch_logged_in_user, :fetch_community, :fetch_community_membership
  skip_filter :check_email_confirmation
  before_filter :ensure_external_plan_service_in_use!
  before_filter :do_jwt_authentication!

  # includes: external_plan_service (Hash with jwt_secret)
  # includes: logger
  include PlanService::ExternalPlanServiceInjector

  # Request data types

  NewPlanRequest = EntityUtils.define_builder(
    [:marketplace_id, :fixnum, :mandatory],
    [:plan_level, :fixnum, :mandatory],
    [:expires_at, :utc_str_to_time, :optional],
  )

  NewPlansRequest = EntityUtils.define_builder(
    [:plans, :mandatory, collection: NewPlanRequest]
  )

  # Response data types

  NewPlanResponse = EntityUtils.define_builder(
    [:marketplace_plan_id, :fixnum, :mandatory],
    [:marketplace_id, :fixnum, :mandatory],
    [:plan_level, :fixnum, :mandatory],
    [:expires_at, :time, :optional],
    [:created_at, :time, :mandatory],
    [:updated_at, :time, :mandatory],
  )

  NewPlansResponse = EntityUtils.define_builder(
    [:plans, :mandatory, collection: NewPlanResponse]
  )

  # Map from External service key names to Entity key names
  EXT_SERVICE_TO_ENTITY_MAP = {
    :marketplace_id => :community_id,
    :marketplace_plan_id => :id
  }

  ENTITY_TO_EXT_SERVICE_MAP = EXT_SERVICE_TO_ENTITY_MAP.invert

  def create
    body = request.raw_post
    logger.info("Received plan notification", nil, {raw: body})

    res = JWTUtils.decode(params[:token], external_plan_service[:jwt_secret]).and_then {
      parse_json(request.raw_post)
    }.and_then { |parsed_json|
      NewPlansRequest.validate(parsed_json)
    }.and_then { |parsed_request|
      logger.info("Parsed plan notification", nil, parsed_request)

      create_plan_operations = parsed_request[:plans].map { |plan_request|
        plan_entity = to_entity(plan_request)

        ->(*) {
          PlanService::API::Api.plans.create(community_id: plan_entity[:community_id], plan: plan_entity)
        }
      }

      if create_plan_operations.present?
        Result.all(*create_plan_operations)
      else
        # Nothing to save
        Result::Success.new([])
      end
    }.on_success { |created_plans|
      logger.info("Created new plans based on the notification", nil, created_plans)

      response = NewPlansResponse.build(plans: created_plans.map { |plan_entity| from_entity(plan_entity) })

      render json: response, status: 200
    }.on_error { |error_msg, data|
      case data
      when JSON::ParserError
        logger.error("Error while parsing JSON: #{data.message}")
        render json: {error: :json_parser_error}, status: 400
      else
        logger.error("Unknown error")
        render json: {error: :unknown_error}, status: 500
      end
    }
  end

  def get_trials
    after = Maybe(params)[:after].to_i.map { |time_int| Time.at(time_int).utc }.or_else(nil)

    if after
      plans = PlanService::API::Api.plans.get_trials(after: after).data.map { |plan|
        from_entity(plan)
      }

      render json: {plans: plans}

      logger.info("Returned #{plans.count} plans that were created after #{after}", nil, {plan_count: plans.count, after: after})
    else
      render json: {error: "Missing 'after' parameter"}, status: 400
      logger.error("Missing 'after' parameter")
    end

  end

  # private

  def parse_json(body)
    begin
      Result::Success.new(JSONUtils.symbolize_keys(JSON.parse(body)))
    rescue StandardError => e
      Result::Error.new(e)
    end
  end

  def from_entity(entity)
    HashUtils.rename_keys(ENTITY_TO_EXT_SERVICE_MAP, entity)
  end

  def to_entity(hash)
    HashUtils.rename_keys(EXT_SERVICE_TO_ENTITY_MAP, hash)
  end

  # filters

  def do_jwt_authentication!
    JWTUtils.decode(params[:token], external_plan_service[:jwt_secret]).on_error {
      logger.error("Unauthorized", nil, token: params[:token])
      render json: {error: :unauthorized}, status: 401
    }
  end

  def ensure_external_plan_service_in_use!
    unless external_plan_service[:active]
      raise ActiveRecord::RecordNotFound
    end
  end

end
