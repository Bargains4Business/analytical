module Analytical
  module Modules
    class Mixpanel
      include Analytical::Modules::Base

      def initialize(options={})
        super
        @tracking_command_location = :head_append
      end

      # Mixpanel-specific queueing behavior, overrides Base#queue
      def queue(*args)
        return if @options[:ignore_duplicates] && @command_store.include?(args)
        if args.first==:alias_identity
          @command_store.unshift args
        elsif args.first==:identify
          if @command_store.empty?
            @command_store.unshift args
          else
            first_command = @command_store.first
            first_command = first_command.first if first_command.respond_to?(:first)
            @command_store.unshift args unless first_command == :alias_identity
          end
        else
          @command_store << args
        end
      end

      def init_javascript(location)
        init_location(location) do
          js = <<-HTML
          <!-- Analytical Init: Mixpanel -->
          <script type="text/javascript">
            (function(f,b){if(!b.__SV){var a,e,i,g;window.mixpanel=b;b._i=[];b.init=function(a,e,d){function f(b,h){var a=h.split(".");2==a.length&&(b=b[a[0]],h=a[1]);b[h]=function(){b.push([h].concat(Array.prototype.slice.call(arguments,0)))}}var c=b;"undefined"!==typeof d?c=b[d]=[]:d="mixpanel";c.people=c.people||[];c.toString=function(b){var a="mixpanel";"mixpanel"!==d&&(a+="."+d);b||(a+=" (stub)");return a};c.people.toString=function(){return c.toString(1)+".people (stub)"};i="disable track track_pageview track_links track_forms register register_once alias unregister identify name_tag set_config people.set people.set_once people.increment people.append people.track_charge people.clear_charges people.delete_user".split(" ");for(g=0;g<i.length;g++)f(c,i[g]);b._i.push([a,e,d])};b.__SV=1.2;a=f.createElement("script");a.type="text/javascript";a.async=!0;a.src="//cdn.mxpnl.com/libs/mixpanel-2-latest.min.js";e=f.getElementsByTagName("script")[0];e.parentNode.insertBefore(a,e)}})(document,window.mixpanel||[]);
            mixpanel.init("#{options[:key]}");
          </script>
          <!-- end Mixpanel -->
          HTML
          js
        end
      end

      # Old Init Config:
      #   var config = { track_pageview: #{options.fetch(:track_pageview, true)} };
      #   mixpanel.init("#{options[:key]}", config);
      
      
      # Examples:
      #     analytical.track(url_viewed)
      #     analytical.track(url_viewed, 'page name' => @page_title)
      #     analytical.track(url_viewed, :event => 'pageview')
      #
      # By default, this module tracks all pageviews under a single Mixpanel event
      # named 'page viewed'. This follows a recommendation in the Mixpanel docs for
      # minimizing the number of distinct events you log, thus keeping your event data uncluttered.
      #
      # The url is followed by a Hash parameter that contains any other custom properties 
      # you want logged along with the pageview event. The following Hash keys get special treatment:
      # * :callback => String representing javascript function to callback
      # * :event => overrides the default event name for pageviews
      # * :url => gets assigned the url you pass in
      #
      # Mixpanel docs also recommend specifying a 'page name' property when tracking pageviews.
      #
      # To turn off pageview tracking for Mixpanel entirely, initialize analytical as follows: 
      #        analytical( ... mixpanel: { key: ENV['MIXPANEL_KEY'], track_pageview: false } ... )
      def track(*args)
        return if args.empty?
        url = args.first
        properties = args.extract_options!
        callback = properties.delete(:callback) || "function(){}"
        event = properties.delete(:event) || 'page viewed'
        if options[:track_pageview] != false
          properties[:url] = url
          # Docs recommend: mixpanel.track('page viewed', {'page name' : document.title, 'url' : window.location.pathname});
          %(mixpanel.track("#{event}", #{properties.to_json}, #{callback});)
        end          
      end

      # Used to set "Super Properties" - http://mixpanel.com/api/docs/guides/super-properties
      def set(properties)
        "mixpanel.register(#{properties.to_json});"
      end

      def identify(id, *args)
        opts = args.first || {}
        name = opts.is_a?(Hash) ? opts[:name] : ""
        name_str = name.blank? ? "" : " mixpanel.name_tag('#{name}');"
        %(mixpanel.identify('#{id}');#{name_str})
      end

      # See https://mixpanel.com/docs/integration-libraries/using-mixpanel-alias
      # For consistency with KissMetrics this method accepts two parameters.
      # However, the first parameter is ignored because Mixpanel doesn't need it;
      # pass any value for the first parameter, e.g. nil.
      def alias_identity(_, new_identity)
        %(mixpanel.alias("#{new_identity}");)
      end

      def event(name, attributes = {})
        %(mixpanel.track("#{name}", #{attributes.to_json});)
      end
      
      def person(attributes = {})
        %(mixpanel.people.set(#{attributes.to_json});)
      end
      
      def revenue(charge, attributes = {})
        %(mixpanel.people.track_charge(#{charge}, #{attributes.to_json});)
      end

    end
  end
end
