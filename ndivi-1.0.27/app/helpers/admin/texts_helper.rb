# Copyright Ndivi Ltd.
module Admin::TextsHelper
  include ::TextHelper

  def display_text(text)    
    case text
    when Array 
      "["+text.map{|key| '"'+key.to_s.gsub('"', '\"')+'"'}.join(", ")+"]"
    else
      text
    end
  end
  
  def branch_options
    return options_for_select(@branch_roots.map{|br| br.to_s}.sort.map{|br| [br, br]}, @default_branch)
  end

end
