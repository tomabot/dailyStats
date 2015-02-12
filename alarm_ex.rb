
#!/usr/local/env ruby

require 'json'
require 'xml'
require 'net/http'
require 'open-uri'

class InstrumentMonitor
	def initialize( ip, cct )
		# currently the two know cct's are cct032 and cct034. the ip address
		# must include the port number. Currently the port number to use is
		# 32200. 
		@instr = cct
		uri = URI.parse("http://#{ip}/instrument_monitor?instrument_id=#{cct}")

		@loaded_disposable_id = ""
		@load_time = ""
		@latest_dataset_time = ""
		@dataset_count = ""
		@datasets_per_hour = ""
		@datasets_past_hour = ""

		begin
			response = Net::HTTP.get_response(uri)

			body = response.body
			root = XML::Parser.string(body).parse.root

			child = root.children.find {|node| node.name == "status"}
			@status = child[ "value" ]

			if @status == "ok"
				#puts "status: #{@status}"

				child = root.children.find {|node| node.name == "loaded_disposable_id"}
				@loaded_disposable_id = child[ "value" ]

				child = root.children.find {|node| node.name == "load_time"}
				@load_time = child[ "value" ]

				child = root.children.find {|node| node.name == "latest_dataset_time"}
				@latest_dataset_time = child[ "value" ]

				child = root.children.find {|node| node.name == "dataset_count"}
				@dataset_count = child[ "value" ]

				child = root.children.find {|node| node.name == "datasets_per_hour"}
				@datasets_per_hour = child[ "value" ]

				child = root.children.find {|node| node.name == "datasets_past_hour"}
				@datasets_past_hour = child[ "value" ]
			end
		rescue
			@status = "BROKEN CONNECTION"
		end
	end

	def GetInstr
		instrStr = "#{@instr}"
	end

	def GetMetrics
		metricsStr = 
			"dispos id: #{@loaded_disposable_id}\n" +
			"ld time: #{@load_time}\n" +
			"latest dset: #{@latest_dataset_time}\n" +
			"dset ct: #{@dataset_count}\n" +
			"dsets/hr: #{@datasets_per_hour}\n" +
			"past hr: #{@datasets_past_hour}\n"
	end

	def GetStatus
		statusStr = "#{@status}" 
	end

	def TellAll
		puts "status: #{@status}"
		puts "loaded disposable id: #{@loaded_disposable_id}"
		puts "load time: #{@load_time}"
		puts "latest dataset time: #{@latest_dataset_time}"
		puts "dataset count: #{@dataset_count}"
		puts "datasets per hour: #{@datasets_per_hour}"
		puts "datasets past hour: #{@datasets_past_hour}"
	end
end


# ...execution begins here...

	ip, instr, config = ARGV
	config = "/home/tomabot/local/src/dailyStats/seattle_config" if config == nil

	f = File.read( "#{config}" )
	j = JSON.parse( f )

	abort( "#{$0} Disabled" ) if( !j[ "enable" ])

	recipients = j[ "recipients" ].reject{ |key, value| key =~ /disable$/ }.values.join( ", " )

	imon = InstrumentMonitor.new( ip, instr )
	subject = "#{imon.GetInstr()} Status: #{imon.GetStatus()}"
	msgbody = "#{imon.GetMetrics()}"

	`echo "#{msgbody}" | mail -s "#{subject}" #{recipients}`
	#puts subject 
	#puts msgbody 
	#puts recipients 


