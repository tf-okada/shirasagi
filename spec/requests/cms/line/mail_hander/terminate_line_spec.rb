require 'spec_helper'

describe "Cms::Agents::Nodes::LineHubController", type: :request, dbscope: :example do
  let!(:site)   { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node)   { create :cms_node_line_hub, layout_id: layout.id, filename: "receiver" }

  let(:from_conditions) { %w(sample@example.jp) }
  let(:to_conditions) { %w(example.jp) }
  let(:terminate_line) { "暴風警報が発表されました。" }

  let(:decoded) { "【緊急メールサービス】\nシラサギ役場よりお知らせします。" }
  let(:message) { Cms::Line::Message.site(site).last }

  context "public" do
    before do
      site.line_channel_secret = unique_id
      site.line_channel_access_token = unique_id
      site.save!

      Capybara.app_host = "http://#{site.domain}"
    end

    context "with api_token" do
      let!(:api_token) { create :cms_api_token }
      let!(:headers) { { SS::ApiToken::API_KEY_HEADER => api_token.to_jwt } }

      context "deliver handler" do
        let!(:mail_handler) do
          create(:cms_line_mail_handler, handle_state: "deliver", deliver_condition_state: "broadcast",
            from_conditions: from_conditions, to_conditions: to_conditions, terminate_line: terminate_line)
        end
        let!(:url) { "http://#{site.domain}/#{node.url}mail/#{mail_handler.filename}" }

        context "post utf-8 mail" do
          let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/UTF-8.eml") }

          it "#mail" do
            capture_line_bot_client do |capture|
              perform_enqueued_jobs do
                post url, params: { data: data }, headers: headers
                expect(Cms::Line::Message.count).to eq 1
                expect(message.name).to include("[#{mail_handler.name}]")
                expect(message.templates.first.text).to eq decoded
              end
              expect(message.deliver_state).to eq "completed"
              expect(capture.broadcast.count).to eq 1
              expect(Cms::SnsPostLog::LineDeliver.count).to eq 1
            end
          end
        end

        context "post iso-2022-jp mail" do
          let(:data) { Fs.binread("#{Rails.root}/spec/fixtures/mail_page/ISO-2022-JP.eml") }

          it "#mail" do
            capture_line_bot_client do |capture|
              perform_enqueued_jobs do
                post url, params: { data: data }, headers: headers
                expect(Cms::Line::Message.count).to eq 1
                expect(message.name).to include("[#{mail_handler.name}]")
                expect(message.templates.first.text).to eq decoded
              end
              expect(message.deliver_state).to eq "completed"
              expect(capture.broadcast.count).to eq 1
              expect(Cms::SnsPostLog::LineDeliver.count).to eq 1
            end
          end
        end
      end
    end
  end
end