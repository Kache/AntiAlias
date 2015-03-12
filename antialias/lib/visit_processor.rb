require 'csv'

module VisitProcessor
  FIELD_MODEL_HASH = {
    DeviceId => ["device_id", "tmx_device_id"],
    PhoneNumber => ["phone_number","customer_phone_number"],
    Email => ["email", "customer_email"],
    DriversLicense => ["customer_drivers_license_hash"],
    CreditCard => ["credit_card_hash"],
    UserId => ["user_id"]
  }

  TYPE_TO_CLASS = Hash[VisitProcessor::FIELD_MODEL_HASH.map do |model, fields|
    fields.map { |f| [f, model] }
  end.flatten(1)]

  # As of right now, visit can be action_log_entry or mall_transaction and is represented as a dict
  # of fields:values.
  def self.process_raw_visit(visit)
    visit_hash = visit.to_h
    new_nodes = 0
    nodes = []
    visit_hash.each do |type, value|
      model = TYPE_TO_CLASS[type]
      if model.nil? || value.blank? then next end

      node = model.find_by(value: value)

      if node.blank?
        node = model.create(value: value)
        new_nodes += 1
      end
      nodes << node
    end

    VisitedWith.completely_connect(nodes)
    return new_nodes, nodes.count
  end


  def self.import_mt_csv_dump(filename="mt_dump.csv", limit=nil)
    count = 0
    new_nodes = 0
    processed_fields = 0
    CSV.foreach(filename, headers: true) do |row|
      if limit && count > limit then break end
      STDOUT.write("\rcreated #{new_nodes} new nodes --- processed #{processed_fields} fields")
      row.delete("updated_at")
      row.delete("created_at")
      row.delete("user_id")
      n = VisitProcessor.process_raw_visit(row)
      new_nodes += n.first
      processed_fields += n.last
      STDOUT.flush
      count += 1
    end
  end

  def self.import_ale_csv_dump(filename="ales_dump.csv")
    new_nodes = 0
    processed_fields = 0
    CSV.foreach(filename, headers: true) do |row|
      STDOUT.write("\rcreated #{new_nodes} new nodes --- processed #{processed_fields} fields")
      n = VisitProcessor.process_raw_visit(row)
      new_nodes += n.first
      processed_fields += n.last
      STDOUT.flush
    end
  end
end
