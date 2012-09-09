require 'pathname'
$:.unshift File.join(File.dirname(Pathname.new($0).realpath.to_s), 'lib')
require 'optparse'
require 'date'
require 'yaml'
require 'svnlog'
require 'jiraissues'                               

# formatting for console
require 'consolef'
include Consolef

$config_data = YAML.load_file  ('config.yaml') 

                                   
options = Hash.new(0)            
# some defaults
options[:log] = $config_data["SVNURL"]
options[:date] = (Date.today - 7)
$author = nil

OptionParser.new do |o|
  o.on('-a AUTHOR', "Show only changes by the specified author") { |author| $author = author }        
	o.on('-j', "Group by jira ticket number (shows summary)") { |jira| options[:byjira] = 1 }
	o.on('-l SVN LOCATION', "get the log from this location") { |log| options[:log] = log }
	o.on('-d date', "Get commits since this date (must be Date.parse-able, defaults to last week)") {
		|date| options[:date] = Date.parse(date) }
	o.on('-s', "Silent") {|s| $silent = s }
  o.on('-h') { puts o; exit }
  o.parse!
end
       
# fetch the log entries
log_list = Svnlog.fetchlog(options[:log], options[:date], $config_data)
      
# print some stats
print_author_stats(log_list)
print_pretty_history(log_list, $author, options[:byjira]) 