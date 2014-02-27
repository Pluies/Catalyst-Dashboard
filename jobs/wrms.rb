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
end


class WRMS
	def initialize
		@http = Net::HTTP.new("wrms.catalyst.net.nz", 443)
		@http.use_ssl = true
		@http.verify_mode = OpenSSL::SSL::VERIFY_PEER
		@http.set_debug_output($stdout)
	end
	def login(user_id,password)
		begin
			request = Net::HTTP::Post.new("/api2/login")
			request.set_form_data({'user_id' => user_id, 'password' => password})
			response = @http.request(request)
			response_parsed = JSON.parse(response.body)
			@cookie = response_parsed["response"]["auth_cookie_value"]
		rescue
			@cookie = false
		end
	end
	def cookie
		return @cookie
	end
end
