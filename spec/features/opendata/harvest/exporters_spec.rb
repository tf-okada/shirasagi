require 'spec_helper'

describe "opendata_harvest_exporter", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :opendata_node_dataset, name: "opendata_dataset" }
  let(:item) { create :opendata_harvest_exporter, cur_node: node }
  let(:index_path) { opendata_harvest_exporters_path site.id, node }
  let(:new_path) { new_opendata_harvest_exporter_path site.id, node }
  let(:show_path) { opendata_harvest_exporter_path site.id, node, item }
  let(:edit_path) { edit_opendata_harvest_exporter_path site.id, node, item }
  let(:delete_path) { delete_opendata_harvest_exporter_path site.id, node, item }
  let(:export_path) { export_opendata_harvest_exporter_path site.id, node, item }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[url]", with: "http://sample.example.jp"
        select "Ckan API", from: 'item[api_type]'
        fill_in "item[api_key]", with: SecureRandom.uuid
      end
      click_on I18n.t("ss.buttons.save")
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
      end
      click_on I18n.t("ss.buttons.save")
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end

    it "#export" do
      visit export_path
      page.accept_confirm do
        click_on I18n.t("ss.buttons.run")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.started_export'))
      expect(enqueued_jobs.size).to eq 1
    end
  end
end
