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
        # Store an option persistently and override default option
        def set_option(name, value, kind = nil)
          option = get_stored_option(name) || options.build(:name => name.to_s, :value => value, :kind => kind)
          return if new_option_matches_current?(option, value)
          option.value = value
          ret = option.save!
          options(:reload)
          ret
        end
        
        # Get a stored option, or fall back to a default option
        def get_option(name)
          get_stored_option(name) ||
          get_default_option(name)
        end        
        
        # Delete a stored option.
        def delete_option(name)
          if option = options(:reload).find_by_name(name.to_s)
            option = option.destroy
            options(:reload)
            option
          end
        end
        
        # Return a hash of options and defaults.  Values in hash are Option instances
        def options_and_defaults
          get_default_options.merge(options_as_hash)
        end
        
        # Return a pure hash filled from the options.  Use this if you want access to the data
        # as a hash without interfacing with Option methods
        def options_and_defaults_hash
          options_and_defaults.inject({}) do |memo, option|
            memo[option[0]] = option[1].to_h 
            memo
          end
        end
                
        # Returns an instance of options where option names are callable as methods
        #
        # Example:
        #   # Where foo is 'FOO' & bar is 'BAR'
        #   options = foo.options_values_struct 
        #   options.foo => "FOO"
        #   options.bar => "BAR"
        def options_values_struct
          options = {}
          options_and_defaults.each do |name, option|
            opt_key = name.to_s
            options[opt_key] = option.value
            options["#{opt_key}_kind"] = option.kind
          end        
          OpenStruct.new(options)
        end
                
        protected
        
        # Gets the default option if set.  Prefers instance default over class default.
        def get_default_option(name)
          instance_specified_option(name) || self.class.get_specified_option(name)
        end
        
        # Get a hash of all default options, with option names as keys.
        def get_default_options
          self.class.optionable_specified_options.merge(instance_specified_options || {})
        end
        
        # Find the stored option in the database
        def get_stored_option(name)
          options.detect { |option| option.name.to_s == name.to_s }
        end
        
        # Check if a new value provided is the same as the default option.
        def new_option_matches_current?(option, new_value)
          default_value = ( get_default_option(option.name).value rescue nil )
          ( option.value == default_value ) || ( option.value == new_value && ! option.new_record? )
        end
        
        # Return the stored options as a hash, with the option names as keys.
        def options_as_hash
          options.inject({}) do |memo, option|
            memo[option.name.to_s] = option
            memo
          end
        end
      end
    end
  end  
end
