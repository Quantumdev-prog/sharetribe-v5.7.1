module PeopleHelper
  
  # Class is selected if listing type is currently selected
  def get_profile_tab_class(tab_name)
    current_tab_name = params[:type] || "offers"
    "inbox_tab_#{current_tab_name.eql?(tab_name) ? 'selected' : 'unselected'}"
  end
  
  def grade_image_class(grade)
    "profile_feedback_average_image_#{grade_number(grade).to_s}"
  end
  
  def grade_text(grade)
    t(".#{Testimonial::GRADES[grade_number(grade) - 1][0]}")
  end
  
  def grade_number(grade)
    if grade < 2
      return 1
    elsif (grade >= 2 && grade < 3)
      return 2
    elsif (grade >= 3 && grade < 3.5)
      return 3
    elsif (grade >= 3.5 && grade < 4.5)
      return 4
    else
      return 5
    end
  end
  
end
