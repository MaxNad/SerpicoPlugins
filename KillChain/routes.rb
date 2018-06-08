require 'sinatra'
require 'rmagick'
require './plugins/KillChain/model/diagrams'

require 'json'

get '/KillChain/public/:file' do
	send_file('plugins/KillChain/public/'+params[:file], :disposition => 'inline')
end

get '/KillChain' do
	redirect to("/") unless valid_session?

	report_id = params[:report_id]
  # Query for the first report matching the id
  report = get_report(report_id)
  return 'No Such Report' if report.nil?

	@report_id = report_id

	@findings = Findings.all(report_id: report_id)

	DataMapper.repository(:diagrams) {
		@diagram = Diagram.first(report_id: report_id)

		if !@diagram
			@diagram = Diagram.new()
			@diagram.report_id = report_id
		  @diagram.save

			classDef1 = ClassDefinitions.new()
			classDef1.diagram_id = @diagram.id
			classDef1.name = "asset"
			classDef1.css = "fill:#008000,stroke-width:0px";
		  classDef1.save

			classDef2 = ClassDefinitions.new()
			classDef2.diagram_id = @diagram.id
			classDef2.name = "attack"
			classDef2.css = "fill:#FF0000,stroke-width:0px";
		  classDef2.save

			@classDefs = Array.new
			@classDefs.push(classDef1)
			@classDefs.push(classDef2)

			startElement = Element.new()
			startElement.diagram_id = @diagram.id
			startElement.name = "Start"
			startElement.key_name = "id1"
			startElement.is_start = true
		  startElement.save

			@graphElements = Array.new
			@graphElements.push(startElement)
		else
			@classDefs = ClassDefinitions.all(diagram_id: @diagram.id)
			@graphElements = Element.all(diagram_id: @diagram.id)
			@relationships = Relationship.all(diagram_id: @diagram.id)
		end
	}

	haml :"../plugins/KillChain/views/chart", :encode_html => true
end

post '/KillChain' do
	redirect to("/") unless valid_session?

	data = request.POST

	report_id = data['report_id']

  # Query for the first report matching the id
  report = get_report(report_id)
  return 'No Such Report' if report.nil?

	svg_string = data['svgText']
	graph_element = data['graphElements']
	relationships = data['relationships']
	json_elements = JSON.parse(graph_element)
	json_relationships = JSON.parse(relationships)

	img = Magick::Image.from_blob(svg_string) {
	  self.format = 'SVG'
	  self.background_color = 'transparent'
	}

	DataMapper.repository(:diagrams) {
		@diagram = Diagram.first(report_id: report_id)
		@relationships = Relationship.all(diagram_id: @diagram.id)

		json_elements.each do |item|
			@graphElement = Element.first(id: item["id"])
			if @graphElement
				@graphElement.name = item["name"]
				@graphElement.key_name = item["key_name"]
				@graphElement.is_start = item["is_start"]
				@graphElement.class_id = item["class_id"]
				@graphElement.save
			else
				@graphElement = Element.new
				@graphElement.name = item["name"]
				@graphElement.key_name = item["key_name"]
				@graphElement.is_start = item["is_start"]
				@graphElement.class_id = item["class_id"]
		    @graphElement.diagram_id = @diagram.id
				@graphElement.save
			end
		end

		@relationships_ids = json_relationships.collect{ |obj| obj["id"] }
		@deletedRelations = Relationship.all(diagram_id: @diagram.id, :id.not => @relationships_ids)
		@deletedRelations.destroy

		json_relationships.each do |item|
			@relationship = Relationship.first(id: item["id"])
			if @relationship
				@relationship.from_key = item["from_key"]
				@relationship.to_key = item["to_key"]
				@relationship.save
			else
				@relationship = Relationship.new
				@relationship.from_key = item["from_key"]
				@relationship.to_key = item["to_key"]
		    @relationship.diagram_id = @diagram.id
				@relationship.save
			end
		end
	}

	@attachment = Attachments.first(id: @diagram.attachment_id)

	if @attachment
		File.open(@attachment.filename_location, 'wb') do |f|
		  f.write img[0].to_blob {
								self.format = 'PNG'
							}
		end
	else
		rand_file = "./attachments/#{rand(36**36).to_s(36)}.png"

		File.open(rand_file, 'wb') do |f|
		  f.write img[0].to_blob {
								self.format = 'PNG'
							}
		end

		# delete the file data from the attachment
		datax = {}
		# to prevent traversal we hardcode this
		datax['filename_location'] = rand_file.to_s
		datax['filename'] = 'KillChain_Plugin_Diagram'
		datax['description'] = 'KillChain_Plugin_Diagram'
		datax['report_id'] = report_id
		data = url_escape_hash(datax)

		@attachment = Attachments.new(data)
		@attachment.save

		@diagram.attachment_id = @attachment.id
		@diagram.save
	end

	redirect ("/KillChain")
end
