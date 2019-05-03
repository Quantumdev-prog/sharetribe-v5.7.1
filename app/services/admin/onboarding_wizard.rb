module Admin
  class OnboardingWizard

    MarketplaceSetupSteps = ::MarketplaceSetupSteps

    KNOWN_STATUSES = [
      :slogan_and_description, :cover_photo, :filter, :paypal, :listing, :invitation
    ].to_set

    EVENT_TYPES = [
      :community_customizations_updated,
      :community_updated,
      :custom_field_created,
      :paypal_preferences_updated,
      :listing_created,
      :invitation_created,
      :listing_shape_updated
    ].to_set

    SetupStatus = EntityUtils.define_builder(
      [:community_id, :fixnum, :mandatory],
      [:slogan_and_description, :bool, :mandatory],
      [:cover_photo, :bool, :mandatory],
      [:filter, :bool, :mandatory],
      [:paypal, :bool, :mandatory],
      [:listing, :bool, :mandatory],
      [:invitation, :bool, :mandatory])

    def initialize(community_id)
      raise ArgumentError("Missing mandatory community_id") unless community_id
      @community_id = community_id
    end

    # Get the status as a SetupStatus hash
    def setup_status
      to_setup_status(load_setup_steps(@community_id))
    end

    # Imperative shell. Process the given event_type with *args
    # arguments. If the event leads to a state change apply it and
    # return true. Otherwise return false.
    def update_from_event(event_type, *args)
      completed_status = process_event(event_type, setup_status(), args)

      if completed_status
        update_completed(@community_id, completed_status)
        true
      else
        false
      end
    end


    private

    def process_event(event_type, setup_status, args)
      unless EVENT_TYPES.include?(event_type)
        raise ArgumentError.new("Unknown event type: #{event_type}")
      end

      # Dispatch to event handler method of same name as event_type
      method(event_type).call(setup_status, *args)
    end


    # Update events
    #

    def community_customizations_updated(setup_status, community_customizations)
      if !setup_status[:slogan_and_description] &&
         community_customizations.all? { |c| c.slogan.present? } &&
         community_customizations.all? { |c| c.description.present? }
        :slogan_and_description
      end
    end

    def community_updated(setup_status, community)
      if !setup_status[:cover_photo] &&
         Maybe(community).map { |c| c.cover_photo_file_name.present? }.or_else(false)
        :cover_photo
      end
    end

    def custom_field_created(setup_status, custom_field)
      if !setup_status[:filter] &&
         Maybe(custom_field).search_filter.or_else(false)
        :filter
      end
    end

    def paypal_preferences_updated(setup_status, community)
      # This event handler is an unfortunate exception as it's not a
      # pure function of input values. The reason is that PaypalHelper
      # already encapsulates the logic to check if a community is
      # ready for payments so repeating it here would be both waste
      # and also dangerous as PaypalHelper logic is used in all other
      # places.
      if !setup_status[:paypal] &&
         community &&
         PaypalHelper.community_ready_for_payments?(community.id)
        :paypal
      end
    end

    def listing_created(setup_status, listing)
      if !setup_status[:listing] &&
         listing
        :listing
      end
    end

    def invitation_created(setup_status, invitation)
      if !setup_status[:invitation] &&
         invitation
        :invitation
      end
    end

    def listing_shape_updated(setup_status, listing_shape)
      if !setup_status[:paypal] && listing_shape && listing_shape.data &&
        !listing_shape.data[:price_enabled]
        :paypal
      end
    end


    # Helpers and setup logic
    #

    def load_setup_steps(community_id)
      Maybe(MarketplaceSetupSteps.find_by(community_id: community_id))
        .or_else { init_setup_steps(community_id) }
    end

    def init_setup_steps(community_id)
      community = Community.find(community_id)
      community_customizations = CommunityCustomization.where(community_id: community.id)
      custom_field = CustomField.find_by(community_id: community.id)
      listing = Listing.find_by(community_id: community.id)
      invitation = Invitation.find_by(community_id: community.id)

      m = MarketplaceSetupSteps.find_or_create_by(community_id: community_id)
      setup_status = to_setup_status(m)

      updates = [
        community_customizations_updated(setup_status, community_customizations),
        community_updated(setup_status, community),
        custom_field_created(setup_status, custom_field),
        paypal_preferences_updated(setup_status, community),
        listing_created(setup_status, listing),
        invitation_created(setup_status, invitation)
      ].compact.map { |status| [status, true] }.to_h

      m.update_attributes(updates)
      m
    end

    def update_completed(community_id, status)
      unless KNOWN_STATUSES.include?(status)
        raise ArgumentError.new("Unknown status: #{status}")
      end

      m = load_setup_steps(community_id)
      m.update(status => true)
    end

    def to_setup_status(model)
      SetupStatus.call(EntityUtils.model_to_hash(model))
    end
  end
end
