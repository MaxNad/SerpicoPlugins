require 'sinatra'
require 'rmagick'
require './plugins/UDV_Worksheet/master_udv'

get '/KillChain/public/:file' do
	send_file('plugins/KillChain/public/'+params[:file], :disposition => 'inline')
end

get '/KillChain' do
	redirect to("/") unless valid_session?

	report_id = params[:report_id]
  # Query for the first report matching the id
  report = get_report(report_id)
  return 'No Such Report' if report.nil?

	@findings = Findings.all(report_id: report_id)

	haml :"../plugins/KillChain/views/chart", :encode_html => true
end

post '/KillChain' do
	redirect to("/") unless valid_session?

	data = request.POST
	svg_string = data['svgText']

	img = Magick::Image.from_blob(svg_string) {
	  self.format = 'SVG'
	  self.background_color = 'transparent'
	}
	File.open('/tmp/test.png', 'wb') do |f|
	  f.write img[0].to_blob {
							self.format = 'PNG'
						}
	end

	redirect ("/KillChain")
end
