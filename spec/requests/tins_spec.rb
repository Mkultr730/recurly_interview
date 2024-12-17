require 'rails_helper'

RSpec.describe TinsController, type: :controller do
  describe 'POST #validate' do
    context 'when the tin and country_code are valid' do
      let(:valid_params) { { tin: '123456789', country_code: 'CA' } }

      before do
        allow(TinValidationService).to receive(:new).and_return(double(valid?: { valid: true, errors: [], formatted_tin: '123456789RT0001', tin_type: :ca_gst }))
        post :validate, params: valid_params
      end

      it 'returns a 200 status code' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the formatted tin' do
        json_response = JSON.parse(response.body)
        expect(json_response['formatted_tin']).to eq('123456789RT0001')
      end

      it 'returns the correct format type' do
        json_response = JSON.parse(response.body)
        expect(json_response['tin_type']).to eq('ca_gst')
      end

      it 'returns valid true' do
        json_response = JSON.parse(response.body)
        expect(json_response['valid']).to eq(true)
      end
    end

    context 'when the tin is invalid' do
      let(:invalid_params) { { tin: '123', country_code: 'CA' } }

      before do
        allow(TinValidationService).to receive(:new).and_return(double(valid?: { valid: false, errors: ['Invalid format'], formatted_tin: '', type: '' }))
        post :validate, params: invalid_params
      end

      it 'returns a 422 status code' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the error message' do
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('Invalid format')
      end

      it 'returns valid false' do
        json_response = JSON.parse(response.body)
        expect(json_response['valid']).to eq(false)
      end
    end

    context 'when the country_code does not exist' do
      let(:invalid_country_code) { { tin: '123456789', country_code: 'XX' } }

      before do
        allow(TinValidationService).to receive(:new).and_return(double(valid?: { valid: false, errors: ['Country code does not exist'], formatted_tin: '', type: '' }))
        post :validate, params: invalid_country_code
      end

      it 'returns a 422 status code' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the error message for unknown country code' do
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('Country code does not exist')
      end
    end
  end
end
