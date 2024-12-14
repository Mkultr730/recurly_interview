require 'rails_helper'

RSpec.describe AbnService do
  describe '#valid_abn?' do
    subject { described_class.new(abn).valid_abn? }

    context 'when the ABN is valid' do
      let(:abn) { '10120000004' }

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'when the ABN is invalid' do
      let(:abn) { '10120000005' }

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when the ABN has an incorrect length' do
      let(:abn) { '123456789' }

      it 'returns false' do
        expect(subject).to be false
      end
    end
  end
end