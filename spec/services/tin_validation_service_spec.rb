require 'rails_helper'
require 'webmock/rspec'

RSpec.describe TinValidationService, type: :service do
  describe '#valid?' do
    context 'when the tin and country_code are valid' do
      let(:valid_tin_au_abn) { '10120000004' }
      let(:valid_tin_au_acn) { '123 456 789' }
      let(:valid_tin_ca_gst) { '123456789RT0001' }
      let(:valid_tin_ca_gst_2) { '123456789' }
      let(:valid_tin_in_gst) { '12ABCDEFGHI01N1' }

      it 'validates AU ABN correctly' do
        stub_request(:get, "http://localhost:8080/queryABN?abn=#{valid_tin_au_abn}")
          .to_return(body: '<response><goodsAndServicesTax>true</goodsAndServicesTax><organisationName>Valid Business</organisationName><address><stateCode>NSW</stateCode><postcode>2000</postcode></address></response>', status: 200)

        service = TinValidationService.new(valid_tin_au_abn, 'AU')
        response = service.valid?

        expect(response[:valid]).to eq(true)
        expect(response[:errors]).to eq(nil)
        expect(response[:formatted_tin]).to eq('10 120 000 004')
        expect(response[:tin_type]).to eq(:au_abn)
      end

      it 'validates AU ACN correctly' do
        service = TinValidationService.new(valid_tin_au_acn, 'AU')
        response = service.valid?

        expect(response[:valid]).to eq(true)
        expect(response[:errors]).to eq(nil)
        expect(response[:formatted_tin]).to eq('123 456 789')
        expect(response[:tin_type]).to eq(:au_acn)
      end

      it 'validates CA GST correctly' do
        service = TinValidationService.new(valid_tin_ca_gst, 'CA')
        response = service.valid?

        expect(response[:valid]).to eq(true)
        expect(response[:errors]).to eq(nil)
        expect(response[:formatted_tin]).to eq('123456789RT0001')
        expect(response[:tin_type]).to eq(:ca_gst)
      end

      it 'validates CA GST correctly (alternate format)' do
        service = TinValidationService.new(valid_tin_ca_gst_2, 'CA')
        response = service.valid?

        expect(response[:valid]).to eq(true)
        expect(response[:errors]).to eq(nil)
        expect(response[:formatted_tin]).to eq('123456789RT0001')
        expect(response[:tin_type]).to eq(:ca_gst)
      end

      it 'validates IN GST correctly' do
        service = TinValidationService.new(valid_tin_in_gst, 'IN')
        response = service.valid?

        expect(response[:valid]).to eq(true)
        expect(response[:errors]).to eq(nil)
        expect(response[:formatted_tin]).to eq('12ABCDEFGHI01N1')
        expect(response[:tin_type]).to eq(:in_gst)
      end
    end

    context 'when the tin is invalid' do
      let(:invalid_tin_au_abn) { '12345 67890 1234' }
      let(:invalid_tin_ca_gst) { '123456789RT000' }
      let(:invalid_tin_in_gst) { '1234ABCDEFGH01Z' }

      it 'returns false for AU ABN when format is invalid' do
        service = TinValidationService.new(invalid_tin_au_abn, 'AU')
        response = service.valid?

        expect(response[:valid]).to eq(false)
        expect(response[:errors]).to include('TIN format does not match')
        expect(response[:formatted_tin]).to eq(nil)
        expect(response[:tin_type]).to eq(nil)
      end

      it 'returns false for CA GST when format is invalid' do
        service = TinValidationService.new(invalid_tin_ca_gst, 'CA')
        response = service.valid?

        expect(response[:valid]).to eq(false)
        expect(response[:errors]).to include('TIN format does not match')
        expect(response[:formatted_tin]).to eq(nil)
        expect(response[:tin_type]).to eq(nil)
      end

      it 'returns false for IN GST when format is invalid' do
        service = TinValidationService.new(invalid_tin_in_gst, 'IN')
        response = service.valid?

        expect(response[:valid]).to eq(false)
        expect(response[:errors]).to include('TIN format does not match')
        expect(response[:formatted_tin]).to eq(nil)
        expect(response[:tin_type]).to eq(nil)
      end
    end

    context 'when the tin and country_code are valid' do
      let(:valid_tin_au_abn) { '10120000004' } # TIN válido

      it 'validates AU ABN correctly (valid TIN)' do
        stub_request(:get, "http://localhost:8080/queryABN?abn=#{valid_tin_au_abn}")
          .to_return(body: '<response><goodsAndServicesTax>true</goodsAndServicesTax><organisationName>Valid Business</organisationName><address><stateCode>NSW</stateCode><postcode>2000</postcode></address></response>', status: 200)

        service = TinValidationService.new(valid_tin_au_abn, 'AU')
        response = service.valid?

        expect(response[:valid]).to eq(true)
        expect(response[:errors]).to eq(nil)
        expect(response[:formatted_tin]).to eq('10 120 000 004')
        expect(response[:tin_type]).to eq(:au_abn)
      end
    end

    context 'when the tin is invalid' do
      let(:invalid_tin_au_abn) { '10000000000' } # TIN no registrado
      let(:invalid_tin_au_abn_server_error) { '53004085616' } # Error 500
      let(:invalid_tin_au_abn_not_registered) { '51824753556' } # Error 404

      it 'returns false for AU ABN when business is not GST registered' do
        stub_request(:get, "http://localhost:8080/queryABN?abn=#{invalid_tin_au_abn}")
          .to_return(body: '<response><goodsAndServicesTax>false</goodsAndServicesTax><organisationName>Invalid Business</organisationName><address><stateCode>NSW</stateCode><postcode>2000</postcode></address></response>', status: 200)

        service = TinValidationService.new(invalid_tin_au_abn, 'AU')
        response = service.valid?

        expect(response[:valid]).to eq(false)
        expect(response[:errors]).to include('Business is not GST registered')
        expect(response[:formatted_tin]).to eq(nil)
        expect(response[:tin_type]).to eq(nil)
      end

      it 'returns false for AU ABN when server returns error 500' do
        stub_request(:get, "http://localhost:8080/queryABN?abn=#{invalid_tin_au_abn_server_error}")
          .to_return(body: '<response><errorMessage>registration API could not be reached</errorMessage></response>', status: 500)

        service = TinValidationService.new(invalid_tin_au_abn_server_error, 'AU')
        response = service.valid?

        expect(response[:valid]).to eq(false)
        expect(response[:errors]).to include('Registration API could not be reached')
        expect(response[:formatted_tin]).to eq(nil)
        expect(response[:tin_type]).to eq(nil)
      end

      it 'returns false for AU ABN when server returns error 404' do
        stub_request(:get, "http://localhost:8080/queryABN?abn=#{invalid_tin_au_abn_not_registered}")
          .to_return(body: '<response><errorMessage>Business is not registered</errorMessage></response>', status: 404)

        service = TinValidationService.new(invalid_tin_au_abn_not_registered, 'AU')
        response = service.valid?

        expect(response[:valid]).to eq(false)
        expect(response[:errors]).to include('Business is not registered')
        expect(response[:formatted_tin]).to eq(nil)
        expect(response[:tin_type]).to eq(nil)
      end
    end

    context 'when the country_code does not exist' do
      let(:invalid_country_code) { 'XX' }
      let(:valid_tin) { '123456789' }

      it 'returns false when country code is missing' do
        service = TinValidationService.new(valid_tin, invalid_country_code)
        response = service.valid?

        expect(response[:valid]).to eq(false)
        expect(response[:errors]).to include('Country code does not exist')
      end
    end
  end
end
