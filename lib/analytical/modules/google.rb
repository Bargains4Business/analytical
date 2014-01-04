module Analytical
  module Modules
    class Google
      include Analytical::Modules::Base

      def initialize(options={})
        super
        @tracking_command_location = :head_append
      end

      def init_javascript(location)
        init_location(location) do
          js = <<-HTML
          <!-- Analytical Init: Google -->
          <script type="text/javascript">
            var _gaq = _gaq || [];
            _gaq.push(['_setAccount', '#{options[:key]}']);
            _gaq.push(['_setDomainName', '#{options[:domain]}']);
            #{"_gaq.push(['_setAllowLinker', true]);" if options[:allow_linker]}
            #{"_gaq.push(['_trackPageLoadTime']);" if options[:track_page_load_time]}
            if(typeof custom_variables !== 'undefined'){
              for(var i = 0; i < custom_variables.length; i++) {
                _gaq.push(['_setCustomVar', custom_variables[i].slot, custom_variables[i].key, custom_variables[i].value, custom_variables[i].scope ]);
              }
            }
            #{"_gaq.push(['_trackPageview']);" unless options[:manually_track_pageviews]}
            setTimeout("_gaq.push(['_trackEvent', '15_seconds', 'read'])",15000);
            (function() {
              var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
              ga.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'stats.g.doubleclick.net/dc.js';
              var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
            })();
          </script>
          HTML
          js
        end
      end

      # slot: 1-5 allowed
      # key: String
      # value: String
      # scope: 1 (visitor-level), 2 (session-level), or 3 (page-level)
      def custom_variable(slot, key, value, scope)
        js = <<-HTML
        <script type="text/javascript">
          if (typeof window.custom_variables == 'undefined') window.custom_variables = [];
          window.custom_variables.push({slot: #{slot}, key: '#{key}', value: '#{value}', scope: #{scope}});
        </script>
        HTML
        js
      end

      def track(*args)
        "_gaq.push(['_trackPageview'#{args.empty? ? ']' : ', "' + args.first + '"]'});"
      end

      def event(name, *args)
        data = args.first
        data = {} unless data.is_a?(Hash)
        category = data[:category] || "Event"
        action = name
        label, value, noninteraction = data[:label], data[:value], data[:noninteraction]
        args = ['_trackEvent', category, action, label, value, noninteraction]
        args.pop while args[-1].nil?
        "_gaq.push(#{args.to_json});"
      end

      def event_javascript
        js = <<-HTML
        if (data.category == null) {
          data.category = "Event";
        }
        _gaq.push(['_trackEvent', data.category, name, data.label, data.value, data.noninteraction]);
        HTML
      end

      def custom_event(category, action, opt_label=nil, opt_value=nil)
        args = [category, action, opt_label, opt_value].compact
        "_gaq.push(" + [ "_trackEvent", *args].to_json + ");"
      end


      # http://code.google.com/apis/analytics/docs/tracking/gaTrackingCustomVariables.html
      #
      #_setCustomVar(index, name, value, opt_scope)
      #
      # index — The slot for the custom variable. Required. This is a number whose value can range from 1 - 5, inclusive.
      #
      # name —  The name for the custom variable. Required. This is a string that identifies the custom variable and appears in the top-level Custom Variables report of the Analytics reports.
      #
      # value — The value for the custom variable. Required. This is a string that is paired with a name.
      #
      # opt_scope — The scope for the custom variable. Optional. As described above, the scope defines the level of user engagement with your site.
      # It is a number whose possible values are 1 (visitor-level), 2 (session-level), or 3 (page-level).
      # When left undefined, the custom variable scope defaults to page-level interaction.
      def set(data)
        if data.is_a?(Hash) && data.keys.any?
          index = data[:index].to_i
          name  = data[:name ]
          value = data[:value]
          scope = data[:scope]
          if (1..5).to_a.include?(index) && !name.nil? && !value.nil?
            data = "#{index}, '#{name}', '#{value}'"
            data += (1..3).to_a.include?(scope) ? ", #{scope}" : ""
            return "_gaq.push(['_setCustomVar', #{ data }]);"
          end
        end
      end

      # http://code.google.com/apis/analytics/docs/gaJS/gaJSApiEcommerce.html#_gat.GA_Tracker_._addTrans
      # String orderId      Required. Internal unique order id number for this transaction.
      # String affiliation  Optional. Partner or store affiliation (undefined if absent).
      # String total        Required. Total dollar amount of the transaction.
      # String tax          Optional. Tax amount of the transaction.
      # String shipping     Optional. Shipping charge for the transaction.
      # String city         Optional. City to associate with transaction.
      # String state        Optional. State to associate with transaction.
      # String country      Optional. Country to associate with transaction.
      def add_trans(order_id, affiliation=nil, total=nil, tax=nil, shipping=nil, city=nil, state=nil, country=nil)
        data = []
        data << "'#{order_id}'"
        data << "'#{affiliation}'"
        data << "'#{total}'"
        data << "'#{tax}'"
        data << "'#{shipping}'"
        data << "'#{city}'"
        data << "'#{state}'"
        data << "'#{country}'"

        "_gaq.push(['_addTrans', #{data.join(', ')}]);"
      end

      # http://code.google.com/apis/analytics/docs/gaJS/gaJSApiEcommerce.html#_gat.GA_Tracker_._addItem
      # String orderId  Optional Order ID of the transaction to associate with item.
      # String sku      Required. Item's SKU code.
      # String name     Required. Product name. Required to see data in the product detail report.
      # String category Optional. Product category.
      # String price    Required. Product price.
      # String quantity Required. Purchase quantity.
      def add_item(order_id, sku, name, category, price, quantity)
        data  = "'#{order_id}', '#{sku}', '#{name}', '#{category}', '#{price}', '#{quantity}'"
        "_gaq.push(['_addItem', #{data}]);"
      end

      # http://code.google.com/apis/analytics/docs/gaJS/gaJSApiEcommerce.html#_gat.GA_Tracker_._trackTrans
      # Sends both the transaction and item data to the Google Analytics server.
      # This method should be used in conjunction with the add_item and add_trans methods.
      def track_trans
        "_gaq.push(['_trackTrans']);"
      end

    end
  end
end
