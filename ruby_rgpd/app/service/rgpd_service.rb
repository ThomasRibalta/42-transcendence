require_relative '../repository/rgpd_repository'
require 'csv'

class RGPDService
  def initialize(rgpd_repository = RGPDRepository.new)
    @rgpd_repository = rgpd_repository
  end

  # Restrict user processing
  def restrict_user(user_id)
    user = @rgpd_repository.get_user_by_id(user_id)

    return { code: 404, error: "User not found" } if user.nil?

    success = @rgpd_repository.update_user_restrict_status(user_id, true)

    if success
      { code: 200, success: "User restriction updated successfully" }
    else
      { code: 500, error: "Failed to update user restriction" }
    end
  end

  # Check if user is restricted
  def is_restricted(user_id)
    user = @rgpd_repository.get_user_by_id(user_id)

    return { code: 404, error: "User not found" } if user.nil?

    { code: 200, restricted: user['restrict'] }
  end

  # Generate data portability CSV
  def portability(user_id)
    user = @rgpd_repository.get_user_by_id(user_id)

    return { code: 404, error: "User not found" } if user.nil?

    csv_data = CSV.generate do |csv|
      csv << user.keys
      csv << user.values
    end

    { code: 200, csv: csv_data }
  end
end
