class PlansController < ApplicationController
  skip_before_filter :verify_authenticity_token, :fetch_logged_in_user, :fetch_community, :fetch_community_membership
  skip_filter :check_email_confirmation
  before_filter :do_jwt_authentication!

  include PlanService::ExternalPlanServiceInjector

  def create
    body = request.raw_post
    logger.info("Received plan notification", nil, {raw: body})

    res = JWTUtils.decode(params[:token], external_plan_service[:jwt_secret]).and_then {
      parse_json(request.raw_post)
    }.on_success { |ext_plans|
      logger.info("Parsed plan notification", nil, ext_plans)

      result = Maybe(ext_plans)["plans"].or_else([]).map { |ext_plan|
        to_plan_entity(ext_plan)
      }.map { |plan|
        new_plan = PlanService::API::Api.plans.create(community_id: plan[:community_id], plan: plan).data

        { marketplace_plan_id: new_plan[:id] }
      }

      logger.info("Created new plans based on the notification", nil, {plans: result})

      render json: {plans: result}, status: 200
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
        from_plan_entity(plan)
      }

      render json: {plans: plans}

      logger.info("Returned #{plans.count} plans that were created after #{after}", nil, {plan_count: plans.count, after: after})
    else
      render json: {error: "Missing 'after' parameter"}, status: 400
      logger.error("Missing 'after' parameter")
    end

  end

  # private

  def do_jwt_authentication!
    JWTUtils.decode(params[:token], external_plan_service[:jwt_secret]).on_error {
      logger.error("Unauthorized", nil, token: params[:token])
      render json: {error: :unauthorized}, status: 401
    }
  end

  def parse_json(body)
    begin
      Result::Success.new(JSON.parse(body))
    rescue StandardError => e
      Result::Error.new(e)
    end
  end

  # Converts plan hash from external service to the format
  # that is expected by PlanService::API::Api.plans.create
  def to_plan_entity(plan)
    {
      community_id: plan["marketplace_id"],
      plan_level: plan["plan_level"],
      expires_at: Maybe(plan)["expires_at"].map { |ts| TimeUtils.utc_str_to_time(ts) }.or_else(nil)
    }
  end

  def from_plan_entity(plan)
    HashUtils.rename_keys({
                            :community_id => :marketplace_id,
                            :id => :marketplace_plan_id
                          }, plan)
  end
end
