# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{acts-as-optionable}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brendon Murphy"]
  s.date = %q{2010-04-22}
  s.email = %q{xternal1+aao@gmail.com}
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    "MIT-LICENSE",
     "README",
     "Rakefile",
     "VERSION",
     "lib/acts-as-optionable.rb",
     "lib/acts_as_optionable/acts_as_optionable.rb",
     "lib/acts_as_optionable/option_methods.rb",
     "lib/acts_as_optionable/options_template.rb",
     "lib/acts_as_optionable/specify_option.rb",
     "rails/init.rb",
     "spec/acts_as_optionable_spec.rb",
     "spec/spec_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/bemurphy/acts_as_optionable}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{ActsAsOptionable is a plugin for Rails that support adding options, as well as specify default options, to ActiveRecord models.}
  s.test_files = [
    "spec/acts_as_optionable_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

