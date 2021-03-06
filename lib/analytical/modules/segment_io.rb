module Analytical
  module Modules
    class SegmentIo
      include Analytical::Modules::Base

      def initialize(options={})
        super
        @tracking_command_location = :head_append
      end

      def init_javascript(location)
        init_location(location) do
          js = <<-HTML
          <!-- Analytical Init: Segment.io -->
          <script type="text/javascript">
            !function(){var analytics=window.analytics=window.analytics||[];if(!analytics.initialize)if(analytics.invoked)window.console&&console.error&&console.error("Segment snippet included twice.");else{analytics.invoked=!0;analytics.methods=["trackSubmit","trackClick","trackLink","trackForm","pageview","identify","group","track","ready","alias","page","once","off","on"];analytics.factory=function(t){return function(){var e=Array.prototype.slice.call(arguments);e.unshift(t);analytics.push(e);return analytics}};for(var t=0;t<analytics.methods.length;t++){var e=analytics.methods[t];analytics[e]=analytics.factory(e)}analytics.load=function(t){var e=document.createElement("script");e.type="text/javascript";e.async=!0;e.src=("https:"===document.location.protocol?"https://":"http://")+"cdn.segment.com/analytics.js/v1/"+t+"/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(e,n)};analytics.SNIPPET_VERSION="3.0.1";
            analytics.load("#{options[:key]}");
            analytics.page()
            }}();
          </script>
          HTML
          js
        end
      end

      def track(*args)
        if args.any?
          %(window.analytics.pageview("#{args.first}");)
        else
          %(window.analytics.pageview();)
        end
      end

      def identify(id, attributes = {})
        %(window.analytics.identify("#{id}", #{attributes.to_json});)
      end

      def event(name, attributes = {})
        %(window.analytics.track("#{name}", #{attributes.to_json});)
      end

    end
  end
end
