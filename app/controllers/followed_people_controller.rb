class FollowedPeopleController < ApplicationController

  def index
    target_user = Person.find_by_username_and_community_id!(params[:person_id], @current_community.id)

    @followed_people = followed_people_in_community(target_user, @current_community)
    respond_to do |format|
      format.js { render :partial => "people/followed_person", :collection => @followed_people, :as => :person }
    end
  end

  # Add or remove followed people from FollowersController


  # Filters out those followed_people that are not members of the community
  # This method is temporary and only needed until the possibility to have
  # one account in many communities is disabled. Then this can be deleted
  # and return to use just simpler followed_people
  # NOTE: similar method is in PeopleController and should be cleaned too
  def followed_people_in_community(person, community)
    person.followed_people.select{|p| p.member_of?(community)}
  end

end

