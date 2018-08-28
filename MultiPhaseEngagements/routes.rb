require 'sinatra'
require './plugins/MultiPhaseEngagements/model/phases'

set :haml, :layout => true

# Entry point, will redirect to admin if we want to manage the phases
get '/MultiPhase' do
        redirect to("/") unless valid_session?

        if request.referrer =~ /admin/ or params[:admin_view] == "true"
                redirect to("/MultiPhase/admin") if is_administrator?
        end

      	report_id = params[:report_id]
        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

        @report_id = report_id

      	DataMapper.repository(:phases) {
          @report_phases = ReportPhase.all(report_id: report_id, order: [:phase_order.asc])

          @last_sort_order = ReportPhase.max(:phase_order)

          if !@last_sort_order
            @last_sort_order = 0
          end

          @all_phases = EngagementPhase.all()
          @available_phases = EngagementPhase.all()
          if @report_phases.length > 0
            @available_phases.delete_if {|obj| @report_phases.map{|obj| obj.phase_id}.include? obj.id}
          end
        }

        haml :'../plugins/MultiPhaseEngagements/views/report_phases', :encode_html => true
end

post '/MultiPhase/add' do
        redirect to("/") unless valid_session?

        data = request.POST
      	report_id = data['report_id']
        phase_id = data['new_phase_id']

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

      	DataMapper.repository(:phases) {
          @last_sort_order = ReportPhase.max(:phase_order)

          if !@last_sort_order
            @last_sort_order = 0
          end

          @report_phases = ReportPhase.create(:report_id => report_id, :phase_id => phase_id, :phase_order => (@last_sort_order+1))
        }

        redirect to("/MultiPhase?report_id=" + report_id)
end

get '/MultiPhase/delete' do
        redirect to("/") unless valid_session?

      	report_id = params[:report_id]
        phase_id = params[:deleted_phase_id]

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

      	DataMapper.repository(:phases) {
          @report_phases = ReportPhase.first(:report_id => report_id, :phase_id => phase_id)
          @report_phases.destroy
        }

        redirect to("/MultiPhase?report_id=" + report_id)
end

get '/MultiPhase/MoveUp' do
        redirect to("/") unless valid_session?

      	report_id = params[:report_id]
        phase_id = params[:phase_id]

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

      	DataMapper.repository(:phases) {
          @moved_up_phase = ReportPhase.first(:report_id => report_id, :phase_id => phase_id)
          @moved_down_phase = ReportPhase.first(:report_id => report_id, :phase_order => (@moved_up_phase.phase_order - 1))

          @moved_up_phase.phase_order = @moved_up_phase.phase_order - 1
          @moved_down_phase.phase_order = @moved_down_phase.phase_order + 1

          @moved_up_phase.save
          @moved_down_phase.save
        }

        redirect to("/MultiPhase?report_id=" + report_id)
end

get '/MultiPhase/MoveDown' do
        redirect to("/") unless valid_session?

      	report_id = params[:report_id]
        phase_id = params[:phase_id]

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

      	DataMapper.repository(:phases) {
          @moved_down_phase = ReportPhase.first(:report_id => report_id, :phase_id => phase_id)
          @moved_up_phase = ReportPhase.first(:report_id => report_id, :phase_order => (@moved_down_phase.phase_order + 1))

          @moved_down_phase.phase_order = @moved_down_phase.phase_order + 1
          @moved_up_phase.phase_order = @moved_up_phase.phase_order - 1

          @moved_down_phase.save
          @moved_up_phase.save
        }

        redirect to("/MultiPhase?report_id=" + report_id)
end

get '/MultiPhase/edit' do
        redirect to("/") unless valid_session?

      	report_id = params[:report_id]
        phase_id = params[:phase_id]

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

        @report_id = report_id
        @phase_id = phase_id

      	DataMapper.repository(:phases) {
          @phase = EngagementPhase.first(:id => phase_id)
          @report_phase = ReportPhase.first(:report_id => report_id, :phase_id => phase_id)
          @phase_findings = ReportPhaseFinding.all(:report_phase_id => @report_phase.id)
        }

        @all_findings = Findings.all(report_id: report_id)
        @available_findings = Findings.all(report_id: report_id)
        if @phase_findings.length > 0
          @available_findings.delete_if {|obj| @phase_findings.map{|obj| obj.finding_id}.include? obj.id}
        end

        haml :'../plugins/MultiPhaseEngagements/views/phase_findings', :encode_html => true
end

post '/MultiPhase/findings/add' do
        redirect to("/") unless valid_session?

        data = request.POST
      	report_id = data['report_id']
        phase_id = data['phase_id']
        finding_id = data['finding_id']

        # Query for the first report matching the id
        report = get_report(report_id)
        return 'No Such Report' if report.nil?

      	DataMapper.repository(:phases) {
          @report_phase = ReportPhase.first(:report_id => report_id, :phase_id => phase_id)
          @phase_findings = ReportPhaseFinding.create(:report_phase_id => @report_phase.id, :finding_id => finding_id)
        }

        @findings = Findings.all(report_id: report_id)

        redirect to("/MultiPhase/edit?report_id=" + report_id + "&phase_id=" + phase_id)
end

get '/MultiPhase/findings/delete' do
        return "TODO !"
end

# Phases administration
get '/MultiPhase/admin' do
        redirect to("/") unless valid_session?
        redirect to("/no_access") if not is_administrator?

      	DataMapper.repository(:phases) {
          @phases = EngagementPhase.all()
        }

        haml :'../plugins/MultiPhaseEngagements/views/manage_phases', :encode_html => true
end

post '/MultiPhase/admin/add' do
        redirect to("/") unless valid_session?
        redirect to("/no_access") if not is_administrator?

        data = request.POST
        new_phase_title = data['phase_title']

      	DataMapper.repository(:phases) {
          @phase = EngagementPhase.create(:title => new_phase_title)
        }

        redirect to("/MultiPhase/admin")
end

get '/MultiPhase/admin/delete' do
        return "TODO !"
end
