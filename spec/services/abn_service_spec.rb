require 'rails_helper'
require 'webmock/rspec'

RSpec.describe AbnService do
  describe '#local_valid_abn?' do
    subject { described_class.new(abn).local_valid_abn? }

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

  describe '#external_valid_abn?' do
    subject { described_class.new(abn).external_valid_abn? }

    context 'when the ABN is valid and GST registered' do
      let(:abn) { '10120000004' }
      let(:response_body) { '<response><goodsAndServicesTax>true</goodsAndServicesTax><organisationName>Test Business</organisationName><address><stateCode>NSW</stateCode><postcode>2000</postcode></address></response>' }

      before do
        # Simulamos la respuesta de la API utilizando WebMock
        stub_request(:get, "http://localhost:8080/queryABN?abn=#{abn}")
          .to_return(body: response_body, status: 200)
      end

      it 'returns valid information' do
        result = subject
        expect(result[:valid]).to be true
        expect(result[:business_registration][:name]).to eq 'Test Business'
        expect(result[:business_registration][:address]).to eq 'NSW, 2000'
      end
    end

    context 'when the ABN is valid but not GST registered' do
      let(:abn) { '10120000004' }
      let(:response_body) { '<response><goodsAndServicesTax>false</goodsAndServicesTax></response>' }

      before do
        # Simulamos la respuesta de la API utilizando WebMock
        stub_request(:get, "http://localhost:8080/queryABN?abn=#{abn}")
          .to_return(body: response_body, status: 200)
      end

      it 'returns an error message' do
        result = subject
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Business is not GST registered')
      end
    end

    context 'when the ABN is not registered' do
      let(:abn) { '10120000004' }

      before do
        # Simulamos una respuesta 404 para indicar que no está registrado
        stub_request(:get, "http://localhost:8080/queryABN?abn=#{abn}")
          .to_return(body: '', status: 404)
      end

      it 'returns an error message' do
        result = subject
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Business is not registered')
      end
    end

    context 'when the API is down' do
      let(:abn) { '10120000004' }

      before do
        # Simulamos una respuesta 500 para indicar que la API está caída
        stub_request(:get, "http://localhost:8080/queryABN?abn=#{abn}")
          .to_return(body: '', status: 500)
      end

      it 'returns an error message' do
        result = subject
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Registration API could not be reached')
      end
    end

    context 'when there is an unexpected error' do
      let(:abn) { '10120000004' }

      before do
        # Simulamos una respuesta 502 para un error inesperado
        stub_request(:get, "http://localhost:8080/queryABN?abn=#{abn}")
          .to_return(body: '', status: 502)
      end

      it 'returns an error message' do
        result = subject
        expect(result[:valid]).to be false
        expect(result[:errors]).to include('Unexpected error during validation')
      end
    end
  end
end
