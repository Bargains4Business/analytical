require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Analytical::Modules::Google" do
  before(:each) do
    @parent = mock('api', :options=>{:google=>{:key=>'abc'}})
  end
  describe 'on initialize' do
    it 'should set the command_location' do
      a = Analytical::Modules::Google.new :parent=>@parent, :key=>'abc'
      a.tracking_command_location.should == :head_append
    end
    it 'should set the options' do
      a = Analytical::Modules::Google.new :parent=>@parent, :key=>'abc'
      a.options.should == {:key=>'abc', :parent=>@parent}
    end
  end
  describe '#track' do
    it 'should return the tracking javascript' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.track.should == "_gaq.push(['_trackPageview']);"
      @api.track('pagename', {:some=>'data'}).should ==  "_gaq.push(['_trackPageview', \"pagename\"]);"
    end
  end
  describe '#event' do
    it 'should return the event javascript' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.event('pagename').should ==  '_gaq.push(["_trackEvent","Event","pagename"]);'
    end
    
    it 'should default the category to "Event" if none is specified' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.event('pagename').should ==  '_gaq.push(["_trackEvent","Event","pagename"]);'
    end
    it 'should include data value, in the "opt_value" argument' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.event('pagename', {:value=>555, :more=>'info'}).should ==  '_gaq.push(["_trackEvent","Event","pagename",null,555]);'
    end
    it 'should include category, label, value, and noninteraction, if specified' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.event('pagename', {:category=>'Thing', :label=>'description', :value=>555, :noninteraction=>true}).should == '_gaq.push(["_trackEvent","Thing","pagename","description",555,true]);'
    end
    it 'should not include data if there is no value' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.event('pagename', {:more=>'info'}).should ==  '_gaq.push(["_trackEvent","Event","pagename"]);'
    end
    it 'should not include data if it is not a hash' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.event('pagename', 555).should ==  '_gaq.push(["_trackEvent","Event","pagename"]);'
    end
  end
  describe '#custom_event' do
    it 'should return the event javascript' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.custom_event('Tag', 'view').should ==  '_gaq.push(["_trackEvent","Tag","view"]);'
    end

    it 'should set the optional label and event value' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.custom_event('Tag', 'view', 'rails', 27).should ==  '_gaq.push(["_trackEvent","Tag","view","rails",27]);'
    end
  end
  
  describe '#event_javascript' do
    it 'should return a custom javascript function' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.event_javascript.should =~ /_gaq.push\(\['_trackEvent', data.category, name, data.label, data.value, data.noninteraction\]\);/
    end
  end
  describe '#set_javascript' do
    it 'should return a custom javascript function' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.set_javascript.should =~ /_gaq.push\(\['_setCustomVar'.*]\);/
    end
  end

  describe '#set' do
    it 'should return the set javascript' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.set(:index => 1, :name => 'gender', :value => 'male').should ==  "_gaq.push(['_setCustomVar', 1, 'gender', 'male']);"
    end

    it 'should handle an optional scope' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.set(:index => 1, :name => 'gender', :value => 'male', :scope => 3).should ==  "_gaq.push(['_setCustomVar', 1, 'gender', 'male', 3]);"
    end
  end

  describe "google ecommerce" do
    before do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
    end

    describe "#add_item" do
      it "adds an item" do
        @api.add_item(123, 'foo', 'bar', 'baz', 10.24, 42).should == "_gaq.push(['_addItem', '123', 'foo', 'bar', 'baz', '10.24', '42']);"
      end

      it "adds an item with a nil category" do
        @api.add_item(123, 'foo', 'bar', nil, 10.24, 42).should == "_gaq.push(['_addItem', '123', 'foo', 'bar', '', '10.24', '42']);"
      end
    end

    describe "#add_trans" do
      it "sets up a transaction" do
        @api.add_trans(123, 'foo', 100.0, 5.12, 10.24, 'NYC', 'NY', 'USA').should == "_gaq.push(['_addTrans', '123', 'foo', '100.0', '5.12', '10.24', 'NYC', 'NY', 'USA']);"
      end

      it "sets up a transaction without optional params" do
         @api.add_trans(123, nil, 100.0).should == "_gaq.push(['_addTrans', '123', '', '100.0', '', '', '', '', '']);"
       end

    end

    describe "#track_trans" do
      it "pushes the transaction data to google" do
        @api.track_trans.should == "_gaq.push(['_trackTrans']);"
      end
    end

  end

  describe '#init_javascript' do
    it 'should return the init javascript' do
      @api = Analytical::Modules::Google.new :parent=>@parent, :key=>'abcdef'
      @api.init_javascript(:head_prepend).should == ''
      @api.init_javascript(:head_append).should =~ /abcdef/
      @api.init_javascript(:head_append).should =~ /google-analytics.com\/ga.js/
      @api.init_javascript(:body_prepend).should == ''
      @api.init_javascript(:body_append).should == ''
    end
  end
end