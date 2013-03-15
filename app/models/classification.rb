# Classification module contains methods that are common to Category and ShareType
module Classification
  
  def display_name
    if I18n.locale && translation(I18n.locale)
      translation(I18n.locale)
    else
      return name
    end
    
  end
  
  # returns the classification object which is highest in the hierarchy starting from self.
  def top_level_parent
    if parent
      parent.top_level_parent
    else
      self
    end
  end
  
  #returns a flattened array of all child objects, including self
  def with_all_children
    
    # first add self
    child_array = [self] 
    
    # Then add children with their children too
    children.each do |child|
      child_array << child.with_all_children
    end
    
    return child_array.flatten
  end
  
  
  
  private
  
  def name_is_not_taken_by_categories_or_share_types
    if (Category.find_by_name(name).present? && Category.find_by_name(name) != self) ||
        (ShareType.find_by_name(name).present? && ShareType.find_by_name(name) != self)
      errors.add(:name, "is already in use by a category or share type")
    end
  end
  
  def translation(locale)
    translation = translations.where(:locale => locale)
     if translation.empty?
       name
     else
       translation.first.name
     end
  end
end