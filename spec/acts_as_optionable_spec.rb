require File.dirname(__FILE__) + '/spec_helper'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

class Mixin < ActiveRecord::Base
end

class SpecifiedMixin < Mixin
  acts_as_optionable
  
  specify_option :foo, :default => "FOOFOO"
  specify_option :bar, :default => "BARBAR", :kind => "example", :display_name => "Bar Bar"
end

class NoSpecifiedMixin < Mixin
  acts_as_optionable
end

# Don't want output from AR
$stdout = StringIO.new

def setup_db
  ActiveRecord::Base.logger
  ActiveRecord::Schema.define do
    create_table :mixins do |t|
      t.string :stuff
    end
    
    create_table :options do |t|
      t.string :name
      t.string :display_name
      t.string :value
      t.string :kind
      t.references :optionable, :polymorphic => true
      t.timestamps
    end
  end  
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

describe "ActsAsOptionable" do
  before(:all) do
    setup_db
  end
  
  after(:all) do
    teardown_db
  end
  
  after(:each) do
    Option.delete_all
    Mixin.delete_all
  end
  
  before(:each) do
    @optionable = SpecifiedMixin.create!    
    @options_template = { :fizz => { :default => "FIZZFIZZ" }, :buzz => { :default => "BUZZBUZZ" } }
  end
  
  describe "specifying options at class level" do
    it "should have the proper number of options set" do
      @optionable.options_and_defaults.keys.length.should == 2
    end
    
    it "should have the expected options set" do
      @optionable.get_option(:foo).value.should == "FOOFOO"
      @optionable.get_option(:bar).value.should == "BARBAR"
    end

    it "should not have a kind if none was specified" do
      @optionable.get_option(:foo).kind.should be_blank
    end
    
    it "should be able to specify the kind of option" do
      @optionable.get_option(:bar).kind.should == "example"
    end
    
    it "should be able to specify a display name" do
      @optionable.get_option(:bar).display_name.should == "Bar Bar"
    end
    
    it "should not mix specifications across unrelated classes" do
      class Foobar < Mixin
        acts_as_optionable
        specify_option :foobar, :default => "FOOBAR"
      end
      
      foobar = Foobar.create!
      foobar.get_option(:foobar).value.should == "FOOBAR"
      Foobar.optionable_specified_options.should_not have_key("foo")
      Foobar.optionable_specified_options.should_not have_key("bar")
    end
    
    it "should return readonly records for the default options" do
      @optionable.get_option(:foo).should be_readonly
    end
  end
  
  describe "specifying options at the instance level" do
    before(:each) do
      @optionable = NoSpecifiedMixin.create!
    end
    
    it "should allow setting the options" do
      lambda {
        @optionable.instance_specified_options = @options_template
      }.should_not raise_error
    end
    
    it "should have the expected default options" do
      @optionable.instance_specified_options = @options_template
      @optionable.get_option(:fizz).value.should == "FIZZFIZZ"
      @optionable.get_option(:buzz).value.should == "BUZZBUZZ"
    end
    
    it "should have the kind if set" do
      @optionable.instance_specified_options = @options_template.merge(:kind_is_set => {:default => "kind_is_set", :kind => "example_kind" })
      @optionable.get_option(:kind_is_set).kind.should == "example_kind"
    end
    
    it "should have the display name if set" do
      @optionable.instance_specified_options = @options_template.merge(:display_name_is_set => {:default => "kind_is_set", :kind => "example_kind", :display_name => "Example Name" })
      @optionable.get_option(:display_name_is_set).display_name.should == "Example Name"
    end
    
    it "should not have the kind if none was provided" do
      @optionable.instance_specified_options = @options_template
      @optionable.get_option(:fizz).kind.should be_blank
    end
    
    it "should return readonly records for the default options" do
      @optionable.instance_specified_options = @options_template
      @optionable.get_option(:fizz).should be_readonly
    end
  end

  describe "default option precedence" do
    before(:each) do
      @optionable.instance_specified_options = @options_template.merge(:bar => {:default => "INSTANCE"}, :fizzbuzz => { :default => "FIZZBUZZ"})
    end

    it "should use class level defaults if an instance level doesn't exist" do
      @optionable.get_option(:bar).value.should == "INSTANCE"
    end
    
    it "should use instance level regardless of state of class level default" do
      @optionable.get_option(:fizzbuzz).value.should == "FIZZBUZZ"
    end
    
    it "should be nil if no default is set" do
      @optionable.get_option(:bogus).should be_nil
    end
  end
  
  describe "working with stored options" do
    before(:each) do
      @key = :is_something
    end
    
    describe "storing options" do
      it "should be able to store a number" do
        @optionable.set_option(@key, 9876)
        @optionable.get_option(@key).value.should == 9876
      end
    
      it "should be able to store false" do
        @optionable.set_option(@key, false)
        @optionable.get_option(@key).value.class.should == FalseClass
      end
    
      it "should be able to store true" do
        @optionable.set_option(@key, true)
        @optionable.get_option(@key).value.class.should == TrueClass
      end
    
      it "should be able to store a string" do
        @optionable.set_option(@key, "a-string")
        @optionable.get_option(@key).value.should == "a-string"
      end
    
      it "should raise an exception if you try to store an unapproved type" do
        lambda { @optionable.set_option(@key, {:a => "b"}) }.should raise_error(ArgumentError)
      end
    
      it "should create a new option if one didn't already exist" do
        @optionable.set_option(@key, true)
        lambda {@optionable.set_option(:new_option, "new-option") }.should change { Option.count }.by(1)
      end
    
      it "should not insert a new option if it already exists" do
        @optionable.set_option(@key, true)
        lambda {@optionable.set_option(@key, false) }.should_not change { Option.count }
      end
    
      it "should overwrite the option if it already exists" do
        @optionable.set_option(@key, true)
        @optionable.get_option(@key).value.should be_true
        @optionable.set_option(@key, false)
        @optionable.get_option(@key).value.should be_false
      end
      
      it "should allowing storing the option kind" do
        @optionable.set_option(@key, "red", :kind => "color")
        @optionable.get_option(@key).kind.should == "color"
      end
      
      it "should not update the option if it already matches current" do
        @optionable.set_option(@key, "red", "color")
        timestamp = @optionable.get_option(@key).updated_at.dup
        sleep 1 # not worth a dependency for 1 time check
        @optionable.set_option(@key, "red", "color")
        @optionable.get_option(@key).updated_at.should == timestamp
      end
      
      it "should not set the option if it matches default" do
        @optionable.get_option(:foo).value.should == "FOOFOO"
        lambda {
          @optionable.set_option(:foo, "FOOFOO") 
        }.should_not change { Option.count }
      end
    end
    
    describe "getting options" do
      it "should prefer the stored option over a default class option" do
        @optionable.class.optionable_specified_options.should have_key("foo")
        n = rand(999)
        @optionable.set_option("foo", n)
        @optionable.get_option("foo").value.should == n
      end
      
      it "should prefer the stored option over a default instance option" do
        n = rand(999)
        @optionable.instance_specified_options = @options_template.merge(:foo => { :default => n })
        @optionable.get_option("foo").value.should == n
        j = rand(999)
        @optionable.set_option("foo", j)
        @optionable.get_option("foo").value.should == j
      end
    end
    
    describe "deleting options" do
      before(:each) do
        @key = :delete_me
        @optionable.set_option(@key, "delete-me")
      end
      
      it "should remove a row from the options" do
        lambda { @optionable.delete_option(@key) }.should change { Option.count }.by(-1)
      end
      
      it "should delete the option" do
        @optionable.get_option(@key).value.should == "delete-me"
        @optionable.delete_option(@key)
        @optionable.get_option(@key).should be_nil
      end
      
      it "should not impact a default class option" do
        @optionable.get_option("foo").value.should == "FOOFOO"
        @optionable.set_option("foo", "foofoo")
        @optionable.get_option("foo").value.should == "foofoo"
        @optionable.delete_option("foo")
        @optionable.get_option("foo").value.should == "FOOFOO"
      end
      
      it "should not impact a default instance option" do
        @optionable.instance_specified_options = @options_template
        @optionable.get_option("fizz").value.should == "FIZZFIZZ"
        @optionable.set_option("fizz", "fizzfizz")
        @optionable.get_option("fizz").value.should == "fizzfizz"
        @optionable.delete_option("fizz")
        @optionable.get_option("fizz").value.should == "FIZZFIZZ"
      end
    end
  end
  
  describe "fetching an object with option names and values" do
    it "should have a method to fetch option names and values" do
      lambda { @optionable.options_values_struct }.should_not raise_error(NoMethodError)
    end
    
    it "should return an object that lets us retreive values by calling a method named for the option" do
      option_values = @optionable.options_values_struct
      option_values.foo.should == "FOOFOO"
      option_values.bar.should == "BARBAR"
    end
    
    it "should have option_name_kind methods set" do
      option_values = @optionable.options_values_struct
      option_values.foo_kind.should be_blank
      option_values.bar_kind.should == "example"
    end
    
    it "should contain both set and default options" do
      @optionable.instance_specified_options = @options_template
      @optionable.set_option("example_option", 99)
       option_values = @optionable.options_values_struct
      option_values.foo.should == "FOOFOO"
      option_values.fizz.should == "FIZZFIZZ"
      option_values.example_option.should == 99
    end
  end
  
  describe "getting options and defaults as a hash" do
    before(:each) do
      @optionable.set_option("example_option", "example_value", :kind => "example", :display_name => "Example Name")
      @options_and_defaults_hash = @optionable.options_and_defaults_hash
    end
    
    it "should return a hash" do
      @options_and_defaults_hash.should be_kind_of(Hash)
    end

    it "should have a value set for default options" do
      @options_and_defaults_hash["foo"]["value"].should == "FOOFOO"
      @options_and_defaults_hash["bar"]["value"].should == "BARBAR"
    end
    
    it "should return non-default options as well" do
      @options_and_defaults_hash["example_option"]["value"].should == "example_value"
    end
    
    it "should include the kind and default" do
      @options_and_defaults_hash["bar"]["default"].should == "BARBAR"
      @options_and_defaults_hash["bar"]["kind"].should == "example"
    end
    
    it "should include the display name" do
      @options_and_defaults_hash["example_option"]["display_name"].should == "Example Name"
    end
  end
end
