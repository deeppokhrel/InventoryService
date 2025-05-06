# spec/models/inventory_spec.rb
require 'rails_helper'

RSpec.describe Inventory, type: :model do
  describe '.update_stock' do
    let(:sku) { 'ABC123' }
    let(:initial_quantity) { 100 }

    context 'when inventory item exists' do
      let!(:inventory) { Inventory.create!(sku: sku, quantity: initial_quantity) }

      context 'with sufficient quantity' do
        let(:deduction) { 30 }

        it 'decreases the quantity' do
          expect {
            Inventory.update_stock(sku, deduction)
          }.to change { inventory.reload.quantity }.by(-deduction)
        end

        it 'does not raise an error' do
          expect {
            Inventory.update_stock(sku, deduction)
          }.not_to raise_error
        end
      end

      context 'with quantity exactly matching stock' do
        it 'does not change the quantity' do
          expect {
            Inventory.update_stock(sku, initial_quantity)
          }.not_to change { inventory.reload.quantity }
        end
      end

      context 'with insufficient quantity' do
        let(:deduction) { initial_quantity + 1 }

        it 'does not change the quantity' do
          expect {
            Inventory.update_stock(sku, deduction)
          }.not_to change { inventory.reload.quantity }
        end

        it 'does not raise an error' do
          expect {
            Inventory.update_stock(sku, deduction)
          }.not_to raise_error
        end
      end
    end

    context 'when inventory item does not exist' do
      it 'does not raise an error' do
        expect {
          Inventory.update_stock('NON_EXISTENT_SKU', 10)
        }.not_to raise_error
      end

      it 'does not create a new inventory record' do
        expect {
          Inventory.update_stock('NON_EXISTENT_SKU', 10)
        }.not_to change(Inventory, :count)
      end
    end
  end
end
