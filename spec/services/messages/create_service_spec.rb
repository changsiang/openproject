#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Messages::CreateService, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:contract_class) do
    double('contract_class', '<=': true)
  end
  let(:message_valid) { true }
  let(:instance) do
    described_class.new(user: user,
                        contract_class: contract_class)
  end
  let(:call_attributes) { { name: 'Some name', identifier: 'Some identifier' } }
  let(:set_attributes_success) do
    true
  end
  let(:set_attributes_errors) do
    double('set_attributes_errors')
  end
  let(:set_attributes_result) do
    ServiceResult.new result: created_message,
                      success: set_attributes_success,
                      errors: set_attributes_errors
  end
  let!(:created_message) do
    message = FactoryBot.build_stubbed(:message)

    allow(Message)
      .to receive(:new)
      .and_return(message)

    allow(message)
      .to receive(:save)
      .and_return(message_valid)

    message
  end
  let!(:set_attributes_service) do
    service = double('set_attributes_service_instance')

    allow(Messages::SetAttributesService)
      .to receive(:new)
      .with(user: user,
            model: created_message,
            contract_class: contract_class,
            contract_options: {})
      .and_return(service)

    allow(service)
      .to receive(:call)
      .and_return(set_attributes_result)
  end
  let(:new_project_role) { FactoryBot.build_stubbed(:role) }

  describe 'call' do
    subject { instance.call(call_attributes) }

    it 'is successful' do
      expect(subject.success?).to be_truthy
    end

    it 'returns the result of the SetAttributesService' do
      expect(subject)
        .to eql set_attributes_result
    end

    it 'persists the message' do
      expect(created_message)
        .to receive(:save)
        .and_return(message_valid)

      subject
    end

    it 'creates a message' do
      expect(subject.result)
        .to eql created_message
    end

    context 'if the SetAttributeService is unsuccessful' do
      let(:set_attributes_success) { false }

      it 'is unsuccessful' do
        expect(subject.success?).to be_falsey
      end

      it 'returns the result of the SetAttributesService' do
        expect(subject)
          .to eql set_attributes_result
      end

      it 'does not persist the changes' do
        expect(created_message)
          .to_not receive(:save)

        subject
      end

      it "exposes the contract's errors" do
        subject

        expect(subject.errors).to eql set_attributes_errors
      end
    end

    context 'when the message is invalid' do
      let(:message_valid) { false }

      it 'is unsuccessful' do
        expect(subject.success?).to be_falsey
      end

      it "exposes the message's errors" do
        subject

        expect(subject.errors).to eql created_message.errors
      end
    end
  end
end
