class Inventory < ApplicationRecord
  def self.update_stock(sku, quantity)
    record = find_by(sku: sku)
    record.update!(quantity: record.quantity - quantity) if record && record.quantity > quantity
  end
end
