require 'pathname'
$:.unshift File.join(File.dirname(Pathname.new($0).realpath.to_s), 'lib')
require 'optparse'
require 'date'
require 'json'
require 'yaml'
require 'svnlog'
require 'jiraissues'

$config_data = YAML.load_file  ('config.yaml') 
                               
def commits_by_author(logitems)
	authors = Hash.new(0)
	logitems.each do | item |
		authors[item[:author]] = authors[item[:author]] + 1
	end                                              
	authors.sort_by { |author, count| -count }
end
     
def show_jira_header(jira_id)
	jira_detail = Jiraissues.fetch_issue($config_data, jira_id)
	puts "\n\n" + 
		jira_detail[:keys][0][:key] + " - " + 
		jira_detail[:keys][0][:summary] + " - " + jira_detail[:keys][0][:status] + 
		"\n------------"
end                                                                                                                  

def print_log(logitem, include_author)
  DateTime.parse(logitem[:date]).strftime("%d/%m/%Y %H:%M") + 
		" - " + logitem[:summary].gsub(/\n/, " ") +
		(include_author ? " :: Author: " + logitem[:author] : "")
end                                          

def print_pretty_history(log_list, author=nil, by_jira=0) 
	puts "\nHistory of Changes" unless author
	puts "\nHistory of Changes by #{author}" if author
	           
	checkins = log_list[:keys]
	checkins = checkins.sort_by { |checkin| checkin[:jira]} if by_jira == 1
	                                                    
	jira = nil
	checkins.each { |logitem|
		if author                                          
			if author == logitem[:author]                        
				if logitem[:jira] != jira && logitem[:jira] != ''
					show_jira_header(logitem[:jira])
					jira = logitem[:jira]
				end
				puts print_log(logitem, false)
			end
		else
			if by_jira > 0 && logitem[:jira] != jira && logitem[:jira] != ''
				show_jira_header(logitem[:jira])
				jira = logitem[:jira]
			end
			puts print_log(logitem, true)
		end
	}
end

now = Date.today
last_week = (now - 7)
                                   
options = Hash.new(0)
$author = nil

OptionParser.new do |o|
  o.on('-a AUTHOR', "Show only changes by the specified author") { |author| $author = author }        
	o.on('-j', "Group by jira ticket number (shows summary)") { |jira| options[:byjira] = 1 }
	o.on('-s', "Silent") {|s| $silent = s }
  o.on('-h') { puts o; exit }
  o.parse!
end
                                                   

log_list = Svnlog.fetchlog($config_data, last_week)
      
puts "\nCommits by Author"
commits_by_author(log_list [:keys]).each {|author, count| puts author + " : " + count.to_s }
                                      
print_pretty_history(log_list, $author, options[:byjira]) 