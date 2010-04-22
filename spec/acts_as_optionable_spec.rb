require File.dirname(__FILE__) + '/spec_helper'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

class Mixin < ActiveRecord::Base
end

class SpecifiedMixin < Mixin
  acts_as_optionable
  
  specify_option :foo, :default => "FOOFOO"
  specify_option :bar, :default => "BARBAR"
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
      t.string :value
    end
    
    create_table :options do |t|
      t.string :name
      t.string :value
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
      @optionable.get_default_options.length.should == 2
    end
    
    it "should have the expected options set" do
      @optionable.get_option(:foo).value.should == "FOOFOO"
      @optionable.get_option(:bar).value.should == "BARBAR"
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
end
