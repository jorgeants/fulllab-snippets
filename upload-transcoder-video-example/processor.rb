# Processor Video

class Processor
	def initialize(args)
		@input_key_video = args[:input_key_video]
		@video_id = args[:video_id]
	end

	def send_job
		transcoder_client = Aws::ElasticTranscoder::Client.new

		pipeline_id = ENV['AWS_ELASTICTRANSCODER_PIPELINE_ID']
		input_key = @input_key_video

		# HLS Presets that will be used to create an adaptive bitrate playlist.
		# hls_64k_audio_preset_id = '1351620000001-200071';
		hls_0400k_preset_id     = '1351620000001-200050';
		hls_0600k_preset_id     = '1351620000001-200040';
		hls_1000k_preset_id     = '1351620000001-200030';
		hls_1500k_preset_id     = '1351620000001-200020';
		hls_2000k_preset_id     = '1351620000001-200010';

		# HLS Segment duration that will be targeted.
		segment_duration = '6'
		# Recomendations:
			# https://forums.developer.apple.com/thread/61411#173586
			# https://developer.apple.com/library/content/technotes/tn2224/_index.html
			# https://developer.apple.com/library/content/documentation/General/Reference/HLSAuthoringSpec/Requirements.html

		# All outputs will have this prefix prepended to their output key.
		output_key_prefix = 'streaming/hls/'

		# Setup the job input using the provided input key.
		input = { key: input_key }

		# Setup the job outputs using the HLS presets.
		output_key = @video_id.to_s

		# hls_audio = {
		#   key: 'hlsAudio/' + output_key,
		#   preset_id: hls_64k_audio_preset_id,
		#   segment_duration: segment_duration
		# }

		hls_400k = {
		  key: 'hls0400k/' + output_key,
		  preset_id: hls_0400k_preset_id,
		  segment_duration: segment_duration
		}

		hls_600k = {
		  key: 'hls0600k/' + output_key,
		  preset_id: hls_0600k_preset_id,
		  segment_duration: segment_duration
		}

		hls_1000k = {
		  key: 'hls1000k/' + output_key,
		  preset_id: hls_1000k_preset_id,
		  segment_duration: segment_duration
		}

		hls_1500k = {
		  key: 'hls1500k/' + output_key,
		  preset_id: hls_1500k_preset_id,
		  segment_duration: segment_duration
		}

		hls_2000k = {
		  key: 'hls2000k/' + output_key,
		  preset_id: hls_2000k_preset_id,
		  segment_duration: segment_duration
		}

		# outputs = [ hls_audio, hls_400k, hls_600k, hls_1000k, hls_1500k, hls_2000k ]
		outputs = [ hls_400k, hls_600k, hls_1000k, hls_1500k, hls_2000k ]
		playlist = {
		  name: 'hls_' + output_key,
		  format: 'HLSv3',
		  output_keys: outputs.map { |output| output[:key] }
		}

		user_metadata = {
			video_id: @video_id.to_s
		}

		job = transcoder_client.create_job(
		  pipeline_id: pipeline_id,
		  input: input,
		  output_key_prefix: output_key_prefix + output_key + '/',
		  outputs: outputs,
		  playlists: [ playlist ],
		  user_metadata: user_metadata
		)[:job]

		job
	end
end


