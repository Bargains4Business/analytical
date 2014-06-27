module Analytical
  module Modules
    class GoogleUniversal
      include Analytical::Modules::Base

      def initialize(options={})
        super
        @tracking_command_location = :head_append
      end

      def init_javascript(location)
        init_location(location) do
          js = <<-HTML
          <!-- Analytical Init: Google Universal -->
          <script>
            (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
            (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
            m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
            })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

            ga('create', '#{options[:key]}', '#{options[:domain]}');
            ga('send', 'pageview');
            setTimeout("ga(‘send’,’event’,’Valid Pageview’,’time on page more than 15 seconds’)",15000);

          </script>
          HTML
          js
        end

        def event(name, *args)
          name_words = name.split(' ')
          action = name_words.first
          category = name_words[1..name_words.size].join('')
          "ga('send', {'hitType': 'event', 'eventCategory': '#{category}', 'eventAction': '#{action}', 'eventValue': 1});"
        end
      end

    end
  end
end
