class TinValidationService
  attr_accessor :tin, :country_code

  FORMATS = {
    'AU' => { au_abn: 'NN NNN NNN NNN', au_acn: 'NNN NNN NNN' },
    'CA' => { ca_gst: 'NNNNNNNNN[RT0001]' },
    'IN' => { in_gst: 'NNXXXXXXXXXXNAN' }
  }.freeze

  REGEX_MAP = {
    'N' => '\\d',
    'A' => '[^\\d]',
    'X' => '[a-zA-Z\\d]',
    '[' => '(?:',
    ']' => ')?'
  }.freeze

  ERROR_MESSAGES = {
    missing_country: 'Country code does not exist',
    invalid_format: 'TIN format does not match'
  }.freeze

  def initialize(tin, country_code)
    @tin = tin.gsub(/\s+/, "")
    @country_code = country_code
  end

  def valid?
    formats = FORMATS[country_code]
    return { valid: false, errors: [ERROR_MESSAGES[:missing_country]] } unless formats

    response, format, type = find_format(formats)
    return { valid: false, errors: [ERROR_MESSAGES[:invalid_format]] } unless format || !(response[:errors].nil? || response[:errors].empty?)

    if (format)
      response[:formatted_tin] = format_tin(format)
      response[:tin_type] = type
    end 

    response
  end

  private

  def find_format(formats)
    response = {}
    formats.each do |type, format|
      next unless tin.match?(to_regex(format))

      if country_code == 'AU' && tin.length == 11
        abn_service = AbnService.new(tin)
        response[:valid] = abn_service.local_valid_abn?
        response.merge!(abn_service.external_valid_abn?)
        next if response[:valid].blank?
      end

      response[:valid] = true

      return response, format, type
      break
    end
    response
  end

  def to_regex(format)
    regex_str = format.gsub(/\s+/, "").chars.map { |char| REGEX_MAP[char] || Regexp.escape(char) }.join
    /\A#{regex_str}\z/
  end

  def format_tin(format)
    format = format.tr("[]", "")
    formatted = ''
    tin_idx = 0

    format.chars.each do |char|
      if %w[N A X].include?(char)
        if tin[tin_idx]
          formatted << tin[tin_idx]
          tin_idx += 1
        else
          formatted << char
        end
      else
        formatted << char
      end
    end

    formatted
  end
end