#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"
require "support/shared/project_life_cycle_helpers"

RSpec.describe Project::Gate do
  it_behaves_like "a Project::LifeCycleStep event"

  describe "validations" do
    it { is_expected.to validate_presence_of(:date) }

    it "is invalid if `end_date` is present" do
      gate_with_end_date = build(:project_gate, end_date: Time.zone.today)

      expect(gate_with_end_date).not_to be_valid
      expect(gate_with_end_date.errors[:base])
        .to include("Cannot assign `end_date` to a Project::Gate")
    end

    it "is valid if `end_date` is not present" do
      valid_gate = build(:project_gate)
      expect(valid_gate).to be_valid
    end
  end
end
