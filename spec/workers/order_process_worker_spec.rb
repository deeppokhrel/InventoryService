# spec/workers/order_process_worker_spec.rb
require 'rails_helper'

RSpec.describe OrderProcessWorker do
  let(:kafka_consumer) { instance_double('KafkaConsumer') }
  let(:message) { instance_double('Kafka::FetchedMessage', value: payload.to_json) }
  let(:inventory) { Inventory.create!(sku: 'TEST123', quantity: 100) }

  before do
    allow(KafkaConsumer).to receive(:new).with("order-events").and_return(kafka_consumer)
    allow(kafka_consumer).to receive(:consume).and_yield(message)
  end

  describe '.start' do
    context 'when receiving a valid "order.placed" event' do
      let(:payload) do
        {
          event: "order.placed",
          data: {
            items: {
              sku: inventory.sku,
              quantity: "10" # Testing string conversion
            }
          }
        }
      end

      it 'processes the order and updates inventory' do
        expect(Inventory).to receive(:update_stock).with(inventory.sku, 10)
        described_class.start
      end

      it 'parses the JSON message correctly' do
        expect(JSON).to receive(:parse).with(payload.to_json).and_call_original
        described_class.start
      end
    end

    context 'when receiving a non-order event' do
      let(:payload) { { event: "payment.processed" } }

      it 'does not attempt to update inventory' do
        expect(Inventory).not_to receive(:update_stock)
        described_class.start
      end
    end

    context 'when inventory update fails' do
      let(:payload) do
        {
          event: "order.placed",
          data: {
            items: {
              sku: 'NON_EXISTENT',
              quantity: "10"
            }
          }
        }
      end

      it 'handles the error gracefully' do
        expect { described_class.start }.not_to raise_error
      end
    end

    context 'when quantity is missing' do
      let(:payload) do
        {
          event: "order.placed",
          data: {
            items: {
              sku: inventory.sku
              # quantity is missing
            }
          }
        }
      end

      it 'handles nil quantity safely' do
        expect(Inventory).to receive(:update_stock).with(inventory.sku, nil)
        described_class.start
      end
    end
  end
end
