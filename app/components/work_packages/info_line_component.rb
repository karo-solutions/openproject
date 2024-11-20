# frozen_string_literal: true

class WorkPackages::InfoLineComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(id:)
    super

    @work_package = WorkPackage.visible.find_by(id:)
  end
end
