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

          </script>
          HTML
          js
        end
      end

      def set(data)
        if data.is_a?(Hash) && data.keys.any?
          index = data[:index].to_i
          name  = data[:name ]
          value = data[:value]
          scope = case data[:scope].to_s
          when '1', '2', '3' then data[:scope].to_i
          when 'visitor' then 1
          when 'session' then 2
          when 'page' then 3
          else nil
          end
          if (1..5).to_a.include?(index) && !name.nil? && !value.nil?
            # data = "#{index}, '#{name}', '#{value}'"
            # data += (1..3).to_a.include?(scope) ? ", #{scope}" : ""
            # return "_gaq.push(['_setCustomVar', #{ data }]);"
            return "ga('set', 'dimension#{index}', '#{value}');"
          end
        end
      end

      def event(name, *args)
        data = args.first || {}
        data = data[:value] if data.is_a?(Hash)
        data_string = !data.nil? ? ", #{data}" : ""
        "_gaq.push(['_trackEvent', \"Event\", \"#{name}\"" + data_string + "]);"
        "ga('send', 'event', \"Event\", \"#{name}\"" + data_string + ");"
      end
    end
  end
end
