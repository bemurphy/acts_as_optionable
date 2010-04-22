module ActiveRecord
  module Acts
    module Optionable
      def self.included(base)
        base.extend ClassMethods
      end
    
      module ClassMethods
        def acts_as_optionable
          has_many :options, :as => :optionable, :dependent => :destroy
          include IntanceMethods
          extend ActiveRecord::Acts::Optionable::SpecifyOption::ClassMethods
          include ActiveRecord::Acts::Optionable::SpecifyOption::InstanceMethods
        end        
      end
    
      module IntanceMethods
        def set_option(name, value)
          option = get_stored_option(name) || options.build(:name => name.to_s)
          return if new_option_matches_current?(option)
          option.value = value
          ret = option.save!
          options(:reload)
          ret
        end
        
        def get_option(name)
          get_stored_option(name) ||
          get_default_option(name)
        end
        
        def get_default_option(name)
          instance_specified_option(name) || self.class.get_specified_option(name)
        end
        
        def get_default_options
          self.class.optionable_specified_options.merge(instance_specified_options || {})
        end
        
        def delete_option(name)
          if option = options(:reload).find_by_name(name.to_s)
            option = option.destroy
            options(:reload)
            option
          end
        end
        
        def options_and_defaults
          options_as_hash = options.inject({}) do |memo, option|
            memo[option.name.to_s] = option
            memo
          end
          get_default_options.merge(options_as_hash)
        end
      
        def specified_options
          raise "TODO"
        end
        
        protected
        
        def get_stored_option(name)
          options.detect { |option| option.name.to_s == name.to_s }
        end
        
        def new_option_matches_current?(option)
          (!option.new_record? && option.value == value) || (get_default_option(name).value == value rescue nil)
        end
      end
    end
  end  
end
