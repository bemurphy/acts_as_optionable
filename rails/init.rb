require "acts-as-optionable"

ActiveRecord::Base.send(:include, ActiveRecord::Acts::Optionable)

RAILS_DEFAULT_LOGGER.info "** acts_as_optionable: initialized properly."