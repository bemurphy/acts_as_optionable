class Option < ActiveRecord::Base
  include ActiveRecord::Acts::Optionable
  extend ActiveSupport::Memoizable
  
  belongs_to :optionable, :polymorphic => true

  default_scope :order => 'created_at ASC'

  validates_uniqueness_of :name, :scope => [:optionable_id, :optionable_type]
  validates_presence_of [:optionable_type, :optionable_id]
  
  attr_accessor :default
  
  def self.new_readonly(attrs)
    option = new(attrs)
    option.readonly!
    option
  end

  def value
    val = read_attribute(:value)
    val ? YAML.load(val) : default
  end
  memoize :value
  
  def value_or_default
    value || default
  end
  memoize :value_or_default

  def value=(val)
    unless value_class_ok?(val)
      raise ArgumentError, "Only store booleans, numbers, and strings, please"
    end
    
    write_attribute(:value, val.to_yaml)
  end

  def display_name
    read_attribute(:display_name) || name.humanize.titleize
  end
  
  def to_h
    option_hash = {}
    option_hash["value"] = value
    option_hash["display_name"] = display_name
    option_hash["default"] = default if default
    option_hash["kind"] = kind if kind
    option_hash.dup
  end
    
  protected
  
  def value_class_ok?(val)
    val.is_a?(TrueClass) || val.is_a?(FalseClass) || val.kind_of?(Numeric) || val.is_a?(String)
  end
end
