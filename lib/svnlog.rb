require 'xmlsimple'
require 'date'
module Svnlog
    def Svnlog.fetchlog(logurl, from_date, config_hash)

      command = "svn log --xml"

      puts "getting svn log #{logurl} from #{from_date}\n " unless $silent
			cached_log = logurl.tr(":/.", "")
			if File.exists?("#{cached_log}.xml") && (Time.now - File.mtime("#{cached_log}.xml") < 300) # five minutes
				puts "Reading Cached File (#{(Time.now - File.mtime("#{cached_log}.xml")).to_i} seconds old)" unless $silent
				xml_feed = File.read("#{cached_log}.xml")
			else
				xml_feed = %x{#{command} #{logurl}}
				File.open("#{cached_log}.xml", "w") { |f| f.write(xml_feed) }
			end
      
      xml_obj = XmlSimple.xml_in(xml_feed)

			puts "Found #{xml_obj['logentry'].length} checkins" unless $silent
			keys = Array.new
      xml_obj['logentry'].each do |item|
	      begin
					jira = item['msg'][0].match(/(#{config_hash['JIRASPACE']}-[0-9]+)/)[1]
				rescue
					jira = ""
				end
				
        message = {
          :key => item['revision'],
          :summary => item['msg'][0],
					:author => item['author'][0].match(/CN=([^\/]*)\//)[1],
					:date => item['date'][0],
					:jira => jira
        }                                     
				next if from_date > DateTime.parse(message[:date])
        keys.push message
      end
      {:keys => keys, :url => config_hash['SVNURL']}

    end
end