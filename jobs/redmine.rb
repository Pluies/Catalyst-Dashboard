require 'yaml'
require 'active_resource'

configpath = '/home/'+ENV['USER']+'/.dashing.yaml'
config = YAML.load_file(configpath)['redmine'] or die("Cannot load YAML config at #{configpath}")

# Redmine URL
$url=config['url']
# redmine username
$username=config['username']
# redmine password
$flubber=config['password']

$REDMINE_DEBUG=false

class Issues < ActiveResource::Base
	self.site = $url
	self.user = $username
	self.password = $flubber
	self.format = :xml
end

SCHEDULER.every '1m', :first_in => 0 do |job|
	issues = Issues.find(:all, :params => {:assigned_to_id => 'me'})
	issues_array = []
	issues.each do |i|
		new_issue = {
			:id => '#' + i.id,
			:label => i.subject,
			:link => $url + '/issues/' + i.id.to_s,
			:status => '(' + i.status.name + ')'
		}
		p new_issue if $REDMINE_DEBUG
		issues_array << new_issue
	end
	send_event('redmine', { items: issues_array })
end

