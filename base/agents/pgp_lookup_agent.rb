require 'cgi'
module Lulz
	class  PgpSearchAgent < Agent
		searcher
		set_description "search public pgp key database"
		def self.accepts?(pred)
			return ((pred.object.is_a?(EmailAddress) or (pred.object.is_a?(Name) and pred.object.is_full_name?) or pred.object.is_a?(Alias)) and not is_processed?(pred.object.to_s))
		end

		default_process :parse

		def parse(pred)
			search_string=pred.object.to_s.strip

			set_processed search_string 
			return if search_string=="admin" # searching for admin is a bad idea ;)
			agent=Agent.get_web_agent
			url="https://pgp.mit.edu/pks/lookup?op=index&search=#{CGI.escape(search_string)}"
			page=agent.get(url)
			results=page.body.scan(/\d\d-\d\d(.*?)(?:pub |<\/pre>)/m).flatten rescue []
			results.each do |result|
				pgp_profile=PgpProfile.new
				key_id=result.scan(/<a href="\/pks\/lookup\?op=vindex\&search=(.*?)">/).flatten.first.to_s 

				pgp_profile.key_id=key_id
				result.each_line do |line|
					email=line.scan(/&lt;([A-Za-z0-9@.]+)&gt;/).first.first rescue nil
					name=line.scan(/([a-zA-Z][^&>]+)&lt;/).first.first.to_s rescue nil
					brute_fact pgp_profile, :email, EmailAddress.new(email)
					set_processed email
					single_fact pgp_profile, :name, Name.new(name)
				end
			end
		end

	end

end
