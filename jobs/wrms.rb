require 'net/https'
require 'json'
require 'date'
require 'yaml'

configpath = '/home/'+ENV['USER']+'/.dashing.yaml'
config = YAML.load_file(configpath)['wrms'] or raise("Cannot load YAML config at #{configpath}")
# wrms id
$user_id=config['user_id']
$auth_key=config['auth_key']
# Support for old-style password-based configuration
$flubber=config['password']
$max_wrs=config['max_wrs']
$server=config['server']
$linktoall=config['linktoall']

$log = Logger.new(STDOUT)
$log.level = Logger::WARN

SCHEDULER.every '1m', :first_in => 0 do |job|
	tries ||= 2
	wrms = WRMS.new($user_id, $auth_key, $flubber)
	$log.debug "Using cookie: #{wrms.cookie}"
	return unless wrms.cookie

	begin
		daily_time, daily_good = wrms.daily_timesheet
		send_event('wrms_daily',  { value: daily_time, performance: daily_good })

		weekly_time, weekly_good = wrms.weekly_timesheet
		send_event('wrms_weekly', { value: weekly_time, performance: weekly_good })

		wrs, clipped = wrms.your_wrs
		count = if clipped
				   "latest #{wrs.count}, clipped"
			   else
				   wrs.count.to_s
			   end
		count = "(#{count})"
		send_event('wrs', {
			items: wrs,
			clipped: clipped,
			count: count,
			linktoall: $linktoall
		})
	rescue
		# If we run into an issue, assume can't log in through auth_key, try with pw
		$log.warn 'auth_key authentication failed, trying with password'
		wrms = WRMS.new $user_id, nil, $flubber
		tries = tries - 1
		retry if tries > 0
	end
end


class WRMS
	def initialize(user_id, auth_key, password)
		@user_id = user_id
		@http = Net::HTTP.new($server, 443)
		@http.use_ssl = true
		@http.verify_mode = OpenSSL::SSL::VERIFY_PEER
		@http.set_debug_output($stdout) if $log.debug?
		if auth_key
			$log.info 'Authenticating using auth_key'
			@cookie = 'wrms3_auth='+auth_key
		else
			$log.info 'Authenticating using password'
			self.login(user_id, password)
		end
	end

	def login(user_id, password)
		begin
			request = Net::HTTP::Post.new("/api2/login")
			request.set_form_data({'user_id' => user_id, 'password' => password})
			response = @http.request(request)
			response_parsed = JSON.parse(response.body)
			@cookie = response_parsed["response"]["auth_cookie_name"] + '=' + response_parsed["response"]["auth_cookie_value"]
		rescue
			$log.error 'Authentication to WRMS failed - please check your user_id and password'
			@cookie = false
		end
	end

	def cookie
		return @cookie
	end

	def daily_timesheet
		time = timesheet('d','d')
		target = [DateTime.now.hour - 9, 8].min
		$log.debug "Daily time #{time}, target #{target}, performance #{perf(time, target)}"
		return time, perf(time,target)
	end

	def weekly_timesheet
		time   = timesheet('w','w')
		target = [(Date.today.cwday - 1) * 8, 40].min
		$log.debug "Weekly time #{time}, target #{target}, performance #{perf(time, target)}"
		return time, perf(time,target)
	end

	def perf(time, target)
		if time >= target
			return 'good'
		elsif ((target - time)/target) <= 0.2 # 20% leeway
			return 'meh'
		else
			return 'bad'
		end
	end

	def timesheet(from,to)
		request = Net::HTTP::Get.new("/api2/report?" +  URI.encode_www_form({
			'created_date'=>from+':'+to,
			'worker' => @user_id,
			'report_type'=>'timesheet',
			'page_size'=>'500',
			'page_no'=>'1',
			'display_fields'=>'request_id,hours,worker_fullname',
			'order_by'=>'timesheet_id',
			'order_direction'=>'desc'
		}))
		request["Cookie"] = @cookie
		response = @http.request(request)
		r = JSON.parse(response.body)
		total = 0.0
		r['response']['results'].each do |ts|
			total += ts['hours']
		end
		return total
	end

	def your_wrs
		return unless @cookie
		clipped = false
		request = Net::HTTP::Get.new("/api2/report?" +  URI.encode_www_form({
			'allocated_to'=>'MY_USER_ID',
			'last_status'=>'A,B,E,I,K,L,O,N,Q,P,S,R,U,W,V,Z',
			'report_type'=>'request',
			'page_size'=>'500',
			'page_no'=>'1',
			'display_fields'=>'request_id,status_desc,brief',
			'order_by'=>'request_id',
			'order_direction'=>'desc'
		}))
		request["Cookie"] = @cookie
		response = @http.request(request)
		r = JSON.parse(response.body)
		wrs = []
		r['response']['results'].each do |wr|
			wrs << {
				link: "https://#{$server}/#{wr['request_id']}",
				label: wr['brief'],
				value: wr['status_desc'],
				request_id: 'wr' + wr['request_id'].to_s
			}
		end
		if wrs.size > $max_wrs
			wrs = wrs[0...$max_wrs]
			clipped = true
		end
		return sort_by_status(wrs), clipped
	end

	def sort_by_status wrs
		# Status list for ordering purposes
		statuses = [
			'New request',
			'Allocated',
			'Quoted',
			'Quote Approved',
			'In Progress',
			'Need Info',
			'Provide Feedback',
			'Development Complete',
			'Ready for Staging',
			'Catalyst Testing',
			'Failed Testing',
			'QA Approved',
			'Ready for System Test',
			'Pending QA',
			'Testing/Signoff',
			'Needs Documenting',
			'Reviewed',
			'Production Ready',
			'Ongoing Maintenance',
			'Blocked',
			'On Hold',
			'Cancelled',
			'Finished'
		]
		sorted_wrs = wrs.sort{|a,b| statuses.find_index(a[:value]) <=> statuses.find_index(b[:value]) }
		return sorted_wrs
	end
end
