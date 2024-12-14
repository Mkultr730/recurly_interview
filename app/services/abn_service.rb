class AbnService
  attr_accessor :abn

  WEIGHTING = [10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19].freeze

  def initialize(abn)
    @abn = abn
  end

  def valid_abn?
    new_abn = (abn[0].to_i - 1).to_s + abn[1..]
    sum = 0
    new_abn.chars.each_with_index do |digit, index|
      sum += (digit.to_i * WEIGHTING[index])
    end
    (sum % 89).zero?
  end
end