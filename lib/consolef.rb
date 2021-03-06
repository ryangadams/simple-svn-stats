# console formatting
module Consolef
	def show_jira_header(jira_id)
		jira_detail = Jiraissues.fetch_issue($config_data, jira_id)
		puts "\n\n" + 
			jira_detail[:keys][0][:key] + " - " + 
			jira_detail[:keys][0][:summary] + " - \033[4m" + jira_detail[:keys][0][:status] + "\033[0m" +
			"\n\033[32m" + jira_detail[:keys][0][:jiraurl] + "\033[0m " +
			"\n------------"
	end
	
	def show_author_header(author)
	  puts "\n\n" + author + "\n------------"
  end
  
	def print_log(logitem, include_author)
	  "r" + logitem[:key] + " - " + 
	  DateTime.parse(logitem[:date]).strftime("%d/%m/%Y %H:%M") + 
			" - " + logitem[:summary].gsub(/\n/, " ") +
			(include_author ? " :: Author: " + logitem[:author] : "")
	end                                          
	
	def print_pretty_history(log_list, author=nil, options)
	  by_jira = options[:by_jira]
	  by_author = options[:by_author]
		puts "\nHistory of Changes" unless author
		puts "\nHistory of Changes by #{author}" if author

		checkins = log_list[:keys]
		checkins = checkins.sort_by { |checkin| checkin[:author]} if by_author == 1
		checkins = checkins.sort_by { |checkin| checkin[:jira]} if by_jira == 1

		jira = nil
		current_author = nil
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
				elsif by_author > 0 && (current_author != logitem[:author])
				  show_author_header(logitem[:author])
				  current_author = logitem[:author]
				end
				puts print_log(logitem, true)
			end
		}
	end
	
	def print_author_stats(log_list)
		puts "\nCommits by Author in this period"
		puts "Name".ljust(20) + " | " + "Count" + " | " +" Last Commit"
		Svnlog.count_commits_by_author(log_list[:keys]).each {|author, stat| 
		  puts author.ljust(20) + " | " + stat[:count].to_s.ljust(5)  + " | " +
		  "\033[36m" + DateTime.parse(stat[:last_commit]).strftime("%d/%m/%Y") + "\033[0m"
	  }
	end
	
end