# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', 'spec_helper'), __FILE__)

describe 'when displaying actions that can be taken with regard to a request' do
  let(:info_request) { FactoryBot.create(:info_request) }
  let(:track_thing) do
    FactoryBot.create(:request_update_track, info_request: info_request)
  end
  let(:user) { info_request.user }
  let(:admin_user) { FactoryBot.create("admin_user") }

  before do
    assign :info_request, info_request
    assign :track_thing, track_thing
  end

  context 'if @show_owner_update_status_action is true' do
    before do
      assign :show_owner_update_status_action, false
    end

    it 'should display a link for the request owner to update the status of the request' do
      render :partial => 'request/after_actions'
      expect(response.body).to have_css('ul.owner_actions') do |div|
        expect(div).to have_css('a', :text => 'Update the status of this request')
      end
    end
  end

  context 'if @show_owner_update_status_action is false' do
    before do
      assign :show_owner_update_status_action, false
    end

    it 'should not display a link for the request owner to update the status of the request' do
      render :partial => 'request/after_actions'
      expect(response.body).to have_css('ul.owner_actions') do |div|
        expect(div).not_to have_css('a', :text => 'Update the status of this request')
      end
    end
  end

  context 'if @show_other_user_update_status_action is true' do
    before do
      assign :show_other_user_update_status_action, false
    end

    it 'should display a link for anyone to update the status of the request' do
      render :partial => 'request/after_actions'
      expect(response.body).to have_css('ul.anyone_actions') do |div|
        expect(div).to have_css('a', :text => 'Update the status of this request')
      end
    end
  end

  context 'if @show_other_user_update_status_action is false' do
    before do
      assign :show_other_user_update_status_action, false
    end

    it 'should not display a link for anyone to update the status of the request' do
      render :partial => 'request/after_actions'
      expect(response.body).to have_css('ul.anyone_actions') do |div|
        expect(div).not_to have_css('a', :text => 'Update the status of this request')
      end
    end
  end

  it 'should display a link for the request owner to request a review' do
    render :partial => 'request/after_actions'
    expect(response.body).to have_css('ul.owner_actions') do |div|
      expect(div).to have_css('a', :text => 'Request an internal review')
    end
  end


  it 'should display the link to download the entire request' do
    render :partial => 'request/after_actions'
    expect(response.body).to have_css('ul.anyone_actions') do |div|
      expect(div).to have_css('a', :text => 'Download a zip file of all correspondence')
    end
  end

  it "should display a link to annotate the request" do
    with_feature_enabled(:annotations) do
      render :partial => 'request/after_actions'
      expect(response.body).to have_css('ul.anyone_actions') do |div|
          expect(div).to have_css('a', :text => 'Add an annotation (to help the requester or others)')
      end
    end
  end

  it "should not display a link to annotate the request if comments are disabled on it" do
    with_feature_enabled(:annotations) do
      info_request.comments_allowed = false
      render :partial => 'request/after_actions'
      expect(response.body).to have_css('ul.anyone_actions') do |div|
          expect(div).not_to have_css('a', :text => 'Add an annotation (to help the requester or others)')
      end
    end
  end

  it "should not display a link to annotate the request if comments are disabled globally" do
    with_feature_disabled(:annotations) do
      render :partial => 'request/after_actions'
      expect(response.body).to have_css('ul.anyone_actions') do |div|
        expect(div).not_to have_css('a', :text => 'Add an annotation (to help the requester or others)')
      end
    end
  end

  context "when the request has not been reported" do
    it "should display a link to report it" do
      render :partial => 'request/after_actions'
      expect(response).to have_css("a", text: "Report this request")
    end
  end

  context "when the request has been reported" do
    it "should display a link to the help page about why reporting is disabled" do
      info_request.report!("", "", nil)
      render :partial => 'request/after_actions'
      expect(response).not_to have_css("a", text: "Report this request")
      expect(response).to have_link(
        "Unavailable",
        :href => help_about_path(:anchor => "reporting_unavailable"))
    end
  end
end
