module VisitProcessor
  FIELD_MODEL_HASH = {
    DeviceId => ["device_id", "tmx_device_id"],
    PhoneNumber => ["phone_number","customer_phone_number"],
    Email => ["email", "customer_email"],
    DriversLicense => ["customer_drivers_license_hash"],
    CreditCard => ["credit_card_hash"],
    UserId => ["user_id"]
  }

  def add_visit_nodes(nodes)
    while nodes.count > 1
      top = nodes.first
      nodes[1..-1].each do |n|
        top.visited_withs << n
      end
      nodes.shift
    end
  end

  # As of right now, visit can be action_log_entry or mall_transaction and is represented as a dict
  # of fields:values.
  def process_raw_visit(visit)
    nodes = []
    FIELD_MODEL_HASH.each do |model,fields|
      fields.each do |field|
        if visit[field].present?
          if model.where(value: visit[field]).nil?
            nodes << model.create(value: visit[field])
          else
            nodes << model.where(value: visit[field])
          end
        end
      end
    end
  end

end
