require 'rails_helper'

RSpec.describe TinValidationService, type: :service do
  describe '#valid?' do
    context 'when the tin and country_code are valid' do
      let(:valid_tin_au_abn) { '12 456 789 012' }
      let(:valid_tin_au_acn) { '123 456 789' }
      let(:valid_tin_ca_gst) { '123456789RT0001' }
      let(:valid_tin_ca_gst_2) { '123456789' }
      let(:valid_tin_in_gst) { '12ABCDEFGHI01N1' }

      it 'validates AU ABN correctly' do
        service = TinValidationService.new(valid_tin_au_abn, 'AU')
        result, error, formatted_tin, type = service.valid?

        expect(result).to eq(true)
        expect(error).to eq('')
        expect(formatted_tin).to eq('12 456 789 012')
        expect(type).to eq(:au_abn)
      end

      it 'validates AU ACN correctly' do
        service = TinValidationService.new(valid_tin_au_acn, 'AU')
        result, error, formatted_tin, type = service.valid?

        expect(result).to eq(true)
        expect(error).to eq('')
        expect(formatted_tin).to eq('123 456 789')
        expect(type).to eq(:au_acn)
      end

      it 'validates CA GST correctly' do
        service = TinValidationService.new(valid_tin_ca_gst, 'CA')
        result, error, formatted_tin, type = service.valid?

        expect(result).to eq(true)
        expect(error).to eq('')
        expect(formatted_tin).to eq('123456789RT0001')
        expect(type).to eq(:ca_gst)
      end

      it 'validates CA GST correctly' do
        service = TinValidationService.new(valid_tin_ca_gst_2, 'CA')
        result, error, formatted_tin, type = service.valid?

        expect(result).to eq(true)
        expect(error).to eq('')
        expect(formatted_tin).to eq('123456789RT0001')
        expect(type).to eq(:ca_gst)
      end

      it 'validates IN GST correctly' do
        service = TinValidationService.new(valid_tin_in_gst, 'IN')
        result, error, formatted_tin, type = service.valid?

        expect(result).to eq(true)
        expect(error).to eq('')
        expect(formatted_tin).to eq('12ABCDEFGHI01N1')
        expect(type).to eq(:in_gst)
      end
    end

    context 'when the tin is invalid' do
      let(:invalid_tin_au_abn) { '12345 67890 1234' }
      let(:invalid_tin_ca_gst) { '123456789RT000' }
      let(:invalid_tin_in_gst) { '1234ABCDEFGH01Z' }

      it 'returns false for AU ABN when format is invalid' do
        service = TinValidationService.new(invalid_tin_au_abn, 'AU')
        result, error, formatted_tin, type = service.valid?

        expect(result).to eq(false)
        expect(error).to eq('TIN format does not match')
        expect(formatted_tin).to eq('')
        expect(type).to eq('')
      end

      it 'returns false for CA GST when format is invalid' do
        service = TinValidationService.new(invalid_tin_ca_gst, 'CA')
        result, error, formatted_tin, type = service.valid?

        expect(result).to eq(false)
        expect(error).to eq('TIN format does not match')
        expect(formatted_tin).to eq('')
        expect(type).to eq('')
      end

      it 'returns false for IN GST when format is invalid' do
        service = TinValidationService.new(invalid_tin_in_gst, 'IN')
        result, error, formatted_tin, type = service.valid?

        expect(result).to eq(false)
        expect(error).to eq('TIN format does not match')
        expect(formatted_tin).to eq('')
        expect(type).to eq('')
      end
    end

    context 'when the country_code does not exist' do
      let(:invalid_country_code) { 'XX' }
      let(:valid_tin) { '123456789' }

      it 'returns false when country code is missing' do
        service = TinValidationService.new(valid_tin, invalid_country_code)
        result, error, formatted_tin, type = service.valid?

        expect(result).to eq(false)
        expect(error).to eq('Country code does not exist')
        expect(formatted_tin).to eq('')
        expect(type).to eq('')
      end
    end
  end
end
