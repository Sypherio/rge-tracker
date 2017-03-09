require 'mechanize'

module RGE
  class TrendFinder
    RGE_SITE = 'http://ebiz1.rge.com/OutageReports/RGEMONROE.html'.freeze
    LOG_NAME = 'rge_logs'.freeze
    POLL_EVERY = 20 # seconds

    def find_outages
      mechanize = Mechanize.new
      prev_outages = 0
      loop do
        total_customers = mechanize.get(RGE_SITE).body.split('service to ')[1].split(' ')[0].delete(',').to_f
        curr_outages = mechanize.get(RGE_SITE).body.split('&nbsp;</th><th>')[1].split('</th></tr>')[0].delete(',').to_f
        percent_outages = (curr_outages / total_customers * 100).round(1)
        write_str = "#{curr_outages.to_i} outages (#{percent_outages}\%)"
        write_outages("#{(curr_outages - prev_outages).to_i} customers have lost power!") if curr_outages > prev_outages
        write_outages("#{(prev_outages - curr_outages).to_i} customers' power was restored!") if prev_outages > curr_outages
        write_outages(write_str)
        prev_outages = curr_outages
        sleep(POLL_EVERY)
      end
    end

    def write_outages(curr_outages)
      `touch #{LOG_NAME}` unless File.exist?(LOG_NAME)
      File.open(LOG_NAME, 'a+') { |file| file.puts("#{Time.now.asctime}: #{curr_outages}") }
    end
  end
end
