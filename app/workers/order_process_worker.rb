class OrderProcessWorker
  def self.start
    consumer = KafkaConsumer.new("order-events")
    consumer.consume do |message|
      event = JSON.parse(message.value)
      next unless event["event"] == "order.placed"

      item = event["data"]["items"]
      Inventory.update_stock(item["sku"], item["quantity"]&.to_i)
    end
  end
end
