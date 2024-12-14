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
    return [false, ERROR_MESSAGES[:missing_country], '', ''] unless formats

    type, format = find_format(formats)
    return [false, ERROR_MESSAGES[:invalid_format], '', ''] unless format

    [true, '', format_tin(format), type]
  end

  private

  def find_format(formats)
    formats.each do |type, format|
      return [type, format] if tin.match?(to_regex(format))
    end
    [nil, nil]
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