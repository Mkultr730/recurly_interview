require 'net/http'
require 'nokogiri'

class AbnService
  attr_accessor :abn

  WEIGHTING = [10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19].freeze
  ABN_SERVER_URL = 'http://localhost:8080/queryABN'.freeze

  def initialize(abn)
    @abn = abn
  end

  def local_valid_abn?
    new_abn = (abn[0].to_i - 1).to_s + abn[1..]
    sum = new_abn.chars.each_with_index.sum { |digit, index| digit.to_i * WEIGHTING[index] }
    (sum % 89).zero?
  end

  def external_valid_abn?
    uri = URI("#{ABN_SERVER_URL}?abn=#{@abn}")
    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPSuccess
      parse_response(response.body)
    when Net::HTTPNotFound
      { valid: false, errors: ['Business is not registered'] }
    when Net::HTTPInternalServerError
      { valid: false, errors: ['Registration API could not be reached'] }
    else
      { valid: false, errors: ['Unexpected error during validation'] }
    end
  end

  private

  def valid_format?
    @abn.match?(/^\d{11}$/)
  end

  def parse_response(xml_response)
    doc = Nokogiri::XML(xml_response)
    gst_registered = doc.at_xpath('//goodsAndServicesTax')&.text == 'true'
    return { valid: false, errors: ['Business is not GST registered'] } unless gst_registered

    business_name = doc.at_xpath('//organisationName')&.text
    address = [
      doc.at_xpath('//address/stateCode')&.text,
      doc.at_xpath('//address/postcode')&.text
    ].compact.join(', ')

    { valid: true, business_registration: { name: business_name, address: address } }
  end
end