#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Queries::Schemas::QueryFilterInstanceSchemaRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:filter) { Queries::WorkPackages::Filter::StatusFilter.new }
  let(:assigned_to_filter) { Queries::WorkPackages::Filter::AssignedToFilter.new }
  let(:custom_field_filter) do
    filter = Queries::WorkPackages::Filter::CustomFieldFilter.new

    allow(WorkPackageCustomField)
      .to receive(:find_by_id)
      .with(custom_field.id)
      .and_return(custom_field)

    filter.name = "cf_#{custom_field.id}"

    filter
  end
  let(:custom_field) { FactoryGirl.build_stubbed(:list_wp_custom_field) }
  let(:instance) do
    described_class.new(filter,
                        self_link,
                        current_user: user,
                        form_embedded: form_embedded)
  end
  let(:form_embedded) { false }
  let(:self_link) { 'bogus_self_path' }
  let(:project) { nil }
  let(:user) { FactoryGirl.build_stubbed(:user) }

  context 'generation' do
    before do
      filter.available_operators.each do |operator|
        allow(::API::V3::Queries::Schemas::FilterDependencyRepresenterFactory)
          .to receive(:create)
          .with(filter,
                operator,
                form_embedded: form_embedded)
          .and_return("lorem": "ipsum")
      end
    end

    subject(:generated) { instance.to_json }

    context '_links' do
      describe 'self' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'self' }
          let(:href) { self_link }
        end
      end

      describe 'filter' do
        it_behaves_like 'has a titled link' do
          let(:link) { 'filter' }
          let(:href) { api_v3_paths.query_filter 'status' }
          let(:title) { 'Status' }
        end
      end

      context 'for an assigned_to filter' do
        let(:filter) { assigned_to_filter }

        it_behaves_like 'has a titled link' do
          let(:link) { 'filter' }
          let(:href) { api_v3_paths.query_filter 'assignee' }
          let(:title) { 'Assignee' }
        end
      end

      context 'for a custom field filter' do
        let(:filter) { custom_field_filter }

        it_behaves_like 'has a titled link' do
          let(:link) { 'filter' }
          let(:href) { api_v3_paths.query_filter "customField#{custom_field.id}" }
          let(:title) { custom_field.name }
        end
      end
    end

    context 'properties' do
      describe '_type' do
        it 'QueryFilterInstanceSchema' do
          expect(subject)
            .to be_json_eql('QueryFilterInstanceSchema'.to_json)
            .at_path('_type')
        end
      end

      describe 'name' do
        let(:path) { 'name' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'String' }
          let(:name) { 'Name' }
          let(:required) { true }
          let(:writable) { false }
          let(:has_default) { true }
        end

        it_behaves_like 'has no visibility property'
      end

      describe 'filter' do
        let(:path) { 'filter' }

        it_behaves_like 'has basic schema properties' do
          let(:type) { 'QueryFilter' }
          let(:name) { Query.human_attribute_name('filter') }
          let(:required) { true }
          let(:writable) { true }
        end

        it_behaves_like 'has no visibility property'

        it_behaves_like 'does not link to allowed values'

        context 'when embedding' do
          let(:form_embedded) { true }

          it_behaves_like 'links to allowed values via collection link' do
            let(:href) { api_v3_paths.query_filter('status') }
          end

          context 'with a custom field filter' do
            let(:filter) { custom_field_filter }

            it_behaves_like 'links to allowed values via collection link' do
              let(:href) { api_v3_paths.query_filter("customField#{custom_field.id}") }
            end
          end
        end
      end

      describe '_dependencies/0 (we only have one)' do
        describe '_type' do
          it 'is SchemaDependency' do
            expect(subject)
              .to be_json_eql('SchemaDependency'.to_json)
              .at_path('_dependencies/0/_type')
          end
        end

        describe 'on' do
          it 'is "operator"' do
            expect(subject)
              .to be_json_eql('operator'.to_json)
              .at_path('_dependencies/0/on')
          end
        end

        describe 'dependencies' do
          it 'is the hash' do
            expected = {
              api_v3_paths.query_operator('=') => { "lorem": "ipsum" },
              api_v3_paths.query_operator('!') => { "lorem": "ipsum" },
              api_v3_paths.query_operator('*') => { "lorem": "ipsum" },
              api_v3_paths.query_operator('c') => { "lorem": "ipsum" },
              api_v3_paths.query_operator('o') => { "lorem": "ipsum" }
            }

            expect(subject)
              .to be_json_eql(expected.to_json)
              .at_path('_dependencies/0/dependencies')
          end

          context 'when filter is a list filter' do
            let(:filter) { Queries::WorkPackages::Filter::AuthorFilter.new }

            it 'is the hash' do
              expected = {
                api_v3_paths.query_operator('=') => { "lorem": "ipsum" },
                api_v3_paths.query_operator('!') => { "lorem": "ipsum" }
              }

              expect(subject)
                .to be_json_eql(expected.to_json)
                .at_path('_dependencies/0/dependencies')
            end
          end
        end
      end
    end
  end
end
