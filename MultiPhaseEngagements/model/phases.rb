require 'data_mapper'
require 'dm-migrations'

# /plugins/MultiPhaseEngagements/db/phases.db

# Initialize the Master DB
DataMapper.setup(:phases, "sqlite://#{Dir.pwd}/plugins/MultiPhaseEngagements/db/phases.db")

class EngagementPhase
    include DataMapper::Resource

    property :id, Serial
    property :title, String, required: true, length: 250
    property :description, String, required: false, length: 500
    property :sample_objective, String, required: false, length: 2500
end

class ReportPhase
    include DataMapper::Resource

    property :id, Serial
    property :report_id, Integer, required: true
    property :phase_id, Integer, required: true
    property :phase_order, Integer, required: true
    property :scope, String, required: true, length: 1500
    property :timeframe, String, required: true, length: 250
end

class ReportPhaseFinding
    include DataMapper::Resource

    property :id, Serial
    property :report_phase_id, Integer, required: true
    property :finding_id, Integer, required: true
end

DataMapper.repository(:phases) {
  EngagementPhase.auto_upgrade!
  ReportPhase.auto_upgrade!
  ReportPhaseFinding.auto_upgrade!
}
