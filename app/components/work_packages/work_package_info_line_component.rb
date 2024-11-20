# frozen_string_literal: true

class WorkPackages::WorkPackageInfoLineComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(id:)
    super

    @work_package = WorkPackage.visible.find_by(id:)
  end
end
