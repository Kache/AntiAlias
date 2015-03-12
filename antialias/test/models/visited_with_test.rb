require 'test_helper'

class VisitedWithTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "matching" do
    phone     = PhoneNumber.new.tap { |p| p.value = "1234567890";         p.save! }
    email     = Email.new.tap       { |e| e.value = "kevin@cardpool.com"; e.save! }
    device_id = DeviceId.new.tap    { |d| d.value = "1234";               d.save! }

    nodes = [phone, email, device_id]

    existing_rels = nodes.map(&:rels).flatten.uniq

    rel1 = VisitedWith.new(from_node: email, to_node: phone)
    rel2 = VisitedWith.new(to_node: email, from_node: phone)
    existing_rels.map { |r| r == rel1 || r == rel2 }

    assert existing_rels.map { |r| r.matches?(rel1) }.first
    assert existing_rels.map { |r| r.matches?(rel2) }.first
  end
end
