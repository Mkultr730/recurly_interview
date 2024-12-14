class TinsController < ApplicationController

  def validate
    result, error, formatted_tin, format_type = TinValidationService.new(tin_params[:tin], tin_params[:country_code]).valid?

    if result
      render json: { valid: true, formatted_tin:, format_type: }, status: :ok
    else
      render json: { valid: false, message: error }, status: :bad_request
    end
  end

  private

  def tin_params
    params.permit(:tin, :country_code)
  end
end
