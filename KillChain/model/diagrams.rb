require 'data_mapper'
require 'dm-migrations'

# /plugins/KillChain/db/diagrams.db

# Initialize the Master DB
DataMapper.setup(:diagrams, "sqlite://#{Dir.pwd}/plugins/KillChain/db/diagrams.db")

class Diagram
    include DataMapper::Resource

    property :id, Serial
    property :report_id, Integer, :required => false
    property :attachment_id, Integer, :required => false

end

class Element
    include DataMapper::Resource

    property :id, Serial
    property :name, String, :required => true, :length => 500
    property :key_name, String, :required => true, :length => 25
    property :is_start, Boolean, :required => false, :default => false
    property :class_id, Integer, :required => false
    property :diagram_id, Integer, :required => true

end

class Relationship
    include DataMapper::Resource

    property :id, Serial
    property :from_key, String, :required => true
    property :to_key, String, :required => true
    property :diagram_id, Integer, :required => true

end

class ClassDefinitions
    include DataMapper::Resource

    property :id, Serial
    property :diagram_id, Integer, :required => true
    property :name, String, :required => true, :length => 50
    property :css, String, :required => true, :length => 500

end

DataMapper.repository(:diagrams) {
  Diagram.auto_migrate!
  Element.auto_migrate!
  Relationship.auto_migrate!
  ClassDefinitions.auto_migrate!
}
