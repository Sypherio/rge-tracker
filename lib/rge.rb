require 'mechanize'
require 'uri'

module RGE
  class TrendFinder
    RGE_SITE = 'http://ebiz1.rge.com/OutageReports/RGEMONROE.html'.freeze
    LOG_NAME = 'rge_logs'.freeze
    POLL_EVERY = 20 # seconds

    def find_outages(options)
      mechanize = Mechanize.new
      options[:road].upcase!
      road_url = find_road_url(mechanize, options) if options[:road]
      prev_outages = 0
      loop do
        # total_customers = mechanize.get(RGE_SITE).body.split('&nbsp;</th><th>')[1].split(' ')[0].gsub(',', '').to_f
        total_customers = mechanize.get(RGE_SITE).body.split('service to ')[1].split(' ')[0].delete(',').to_f
        curr_outages = mechanize.get(RGE_SITE).body.split('&nbsp;</th><th>&nbsp;</th><th>')[1].split('</th></tr>')[0].delete(',').to_f
        percent_outages = (curr_outages / total_customers * 100).round(1)
        write_str = "#{curr_outages.to_i} outages (#{percent_outages}\%)"
        write_outages("#{(curr_outages - prev_outages).to_i} customers have lost power!") if curr_outages > prev_outages
        write_outages("#{(prev_outages - curr_outages).to_i} customers' power was restored!") if prev_outages > curr_outages
        write_outages(write_str)
        print_road_status(road_url, options, mechanize) if road_url
        prev_outages = curr_outages
        sleep(POLL_EVERY)
      end
    end

    def write_outages(curr_outages)
      `touch #{LOG_NAME}` unless File.exist?(LOG_NAME)
      puts curr_outages
      File.open(LOG_NAME, 'a+') { |file| file.puts("#{Time.now.asctime}: #{curr_outages}") }
    end

    def find_road_url(mechanize, options)
      zones = mechanize.get(RGE_SITE).links.map { |link| link.href }
      zones.each do |zone_url|
        next if zone_url == 'RGE.html'
        subzones = mechanize.get("#{RGE_SITE.gsub('RGEMONROE.html', '')}#{zone_url}").links.map { |link| link.href }
        subzones.each do |subzone_url|
          url = "#{RGE_SITE.gsub(zone_url, '').gsub('RGEMONROE.html', '')}#{subzone_url}"
          if mechanize.get(url).body.include?(options[:road])
            return url
          end
        end
      end
      return nil
    end

    def print_road_status(road_url, options, mechanize)
      roads = mechanize.get(road_url).parser.css('tr')
      roads.each do |road|
        data = road.css('td')
        next unless data.to_s.include?(options[:road])
        total_customers = data[1].to_s.gsub('<td>', '').gsub('</td>', '').to_f
        no_power = data[2].to_s.gsub('<td>', '').gsub('</td>', '').to_f
        puts("#{no_power.to_i}/#{total_customers.to_i} people on #{options[:road]} have no power (#{(no_power/total_customers*100).round(1)}%)")
      end
    end
  end
end
