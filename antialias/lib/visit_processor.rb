module VisitProcessor
  FIELD_MODEL_HASH = {
    DeviceId: ["device_id", "tmx_device_id"],
    PhoneNumber: ["phone_number","customer_phone_number"],
    Email: ["email", "customer_email"],
    DriversLicense: ["customer_drivers_license_hash"],
    CreditCard: ["credit_card_hash"],
    UserId: ["user_id"]
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
end