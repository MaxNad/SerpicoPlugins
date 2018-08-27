require 'sinatra'

# Entry point, will redirect to admin if we want to manage the phases
get '/MultiPhase' do
        redirect to("/") unless valid_session?

        if request.referrer =~ /admin/ or params[:admin_view] == "true"
                redirect to("/MultiPhase/admin") if is_administrator?
        end

        haml :'../plugins/MultiPhaseEngagements/views/report_phases', :encode_html => true
end

# List current reports
get '/MultiPhase/admin' do
        redirect to("/") unless valid_session?
        redirect to("/no_access") if not is_administrator?

        haml :'../plugins/MultiPhaseEngagements/views/manage_phases', :encode_html => true
end
