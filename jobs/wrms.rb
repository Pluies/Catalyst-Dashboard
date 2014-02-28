require 'net/https'
require 'json'

# wrms id
user_id="2583"

#wrms password
flubber="flubber"

SCHEDULER.every '30m', :first_in => 0 do |job|
	wrms = WRMS.new
	wrms.login(user_id,flubber)
	p wrms.cookie
	send_event('wrms_weekly', { value: wrms.weekly_timesheet })
end


class WRMS
	def initialize
		@http = Net::HTTP.new("wrms.catalyst.net.nz", 443)
		@http.use_ssl = true
		@http.verify_mode = OpenSSL::SSL::VERIFY_PEER
#		@http.set_debug_output($stdout)
	end
	def login(user_id,password)
		begin
			request = Net::HTTP::Post.new("/api2/login")
			request.set_form_data({'user_id' => user_id, 'password' => password})
			response = @http.request(request)
			response_parsed = JSON.parse(response.body)
			@cookie = response_parsed["response"]["auth_cookie_name"] + '=' + response_parsed["response"]["auth_cookie_value"]
		rescue
			@cookie = false
		end
	end
	def cookie
		return @cookie
	end
	def weekly_timesheet
		return unless @cookie
		week_start = Date.parse('Monday')
		monday = week_start.strftime("%Y-%m-%d")
		sunday = (week_start + 6).strftime("%Y-%m-%d")
		p monday+':'+sunday
		request = Net::HTTP::Get.new("/api2/report?" +  URI.encode_www_form({
			'created_date'=>monday+':'+sunday,
			'worker'=>'2583',
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
		p r
		p total
		return total
	end
end
