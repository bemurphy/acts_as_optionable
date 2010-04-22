module ActiveRecord
  module Acts
    module Optionable
      module OptionMethods        
        def self.included(option_model)
          option_model.extend Finders
        end

        module Finders
          def find_options_for_optionable(optionable_str, optionable_id)
            all(:conditions => { :optionable_type => optionable_str, :optionable_id => optionable_id }, :order => "created_at DESC")
          end
        end
      end
    end
  end  
end
