require File.expand_path("../spec_helper", __FILE__)

module Danger
  describe Danger::DangerJira do
    it "should be a plugin" do
      expect(Danger::DangerJira.new(nil)).to be_a Danger::Plugin
    end

    #
    # You should test your custom attributes and methods here
    #
    describe "with Dangerfile" do
      before do
        @jira = testing_dangerfile.jira
        DangerJira.send(:public, *DangerJira.private_instance_methods)
        github = Danger::RequestSources::GitHub.new({}, testing_env)
      end

      it "can find jira issues via title" do
        allow(@jira).to receive_message_chain("github.pr_title").and_return("Ticket [WEB-123] and WEB-124")
        issues = @jira.find_jira_issues(key: "WEB")
        expect(issues).to eq(["WEB-123", "WEB-124"])
      end

      it "can find jira issues in commits" do
        single_commit = Object.new
        def single_commit.message
          "WIP [WEB-125]"
        end
        commits = [single_commit]
        allow(@jira).to receive_message_chain("git.commits").and_return(commits)
        issues = @jira.find_jira_issues(
          key: "WEB",
          search_title: false,
          search_commits: true
        )
        expect(issues).to eq(["WEB-125"])
      end

      it "can find jira issues via branch name" do
        allow(@jira).to receive_message_chain("github.branch_for_head").and_return("bugfix/WEB-126")
        issues = @jira.find_jira_issues(
          key: "WEB",
          search_title: false,
          search_commits: false,
          search_branch: true
        )
        expect(issues).to eq(["WEB-126"])
      end

      it "can find jira issues in pr body" do
        allow(@jira).to receive_message_chain("github.pr_body").and_return("[WEB-126]")
        issues = @jira.find_jira_issues(
          key: "WEB",
          search_title: false,
          search_commits: false,
          search_branch: false,
          search_body: true
        )
        expect(issues).to eq(["WEB-126"])
      end

      it "outputs error message for title" do
        error_string = @jira.error_message_for(true, false, false, false)
        expect(error_string).to eq("This PR does not contain any JIRA issue keys in the PR title (e.g. KEY-123)")
      end

      it "outputs error message for title, commits" do
        error_string = @jira.error_message_for(true, true, false, false)
        expect(error_string).to eq("This PR does not contain any JIRA issue keys in the PR title, commit messages (e.g. KEY-123)")
      end

      it "outputs error message for title, commits, branch" do
        error_string = @jira.error_message_for(true, true, true, false)
        expect(error_string).to eq("This PR does not contain any JIRA issue keys in the PR title, commit messages, branch name (e.g. KEY-123)")
      end

      it "outputs error message for title, commits, branch, body" do
        error_string = @jira.error_message_for(true, true, true, true)
        expect(error_string).to eq("This PR does not contain any JIRA issue keys in the PR title, commit messages, branch name, body (e.g. KEY-123)")
      end

      it "outputs error message for title, branch" do
        error_string = @jira.error_message_for(true, false, true, false)
        expect(error_string).to eq("This PR does not contain any JIRA issue keys in the PR title, branch name (e.g. KEY-123)")
      end

      it "can find no-jira in pr body" do
        allow(@jira).to receive_message_chain("github.pr_body").and_return("[no-jira] Ticket doesn't need a jira but [WEB-123] WEB-123")
        result = @jira.should_skip_jira?(search_title: false)
        expect(result).to be(true)
      end

      it "can find no-jira in title" do
        allow(@jira).to receive_message_chain("github.pr_title").and_return("[no-jira] Ticket doesn't need jira but [WEB-123] and WEB-123")
        result = @jira.should_skip_jira?
        expect(result).to be(true)
      end

      it "can find no-jira in branch name" do
        allow(@jira).to receive_message_chain("github.pr_body").and_return("")
        allow(@jira).to receive_message_chain("github.branch_for_head").and_return("feat/no-jira/somefeature")
        result = @jira.should_skip_jira?(search_title: false)
        expect(result).to be(true)
      end

      it "can find NOJIRA in branch name" do
        allow(@jira).to receive_message_chain("github.pr_body").and_return("")
        allow(@jira).to receive_message_chain("github.branch_for_head").and_return("feat/NOJIRA/somefeature")
        result = @jira.should_skip_jira?(search_title: false)
        expect(result).to be(true)
      end

      it "can find nojira in pr body" do
        allow(@jira).to receive_message_chain("github.pr_body").and_return("[nojira] Ticket doesn't need a jira but [WEB-123] WEB-123")
        result = @jira.should_skip_jira?(search_title: false)
        expect(result).to be(true)
      end

      it "can find nojira in title" do
        allow(@jira).to receive_message_chain("github.pr_title").and_return("[nojira] Ticket doesn't need jira but [WEB-123] and WEB-123")
        result = @jira.should_skip_jira?
        expect(result).to be(true)
      end

      it "can find nojira in branch name" do
        allow(@jira).to receive_message_chain("github.pr_body").and_return("")
        allow(@jira).to receive_message_chain("github.branch_for_head").and_return("feat/nojira/somefeature")
        result = @jira.should_skip_jira?(search_title: false)
        expect(result).to be(true)
      end

      it "can remove duplicates" do
        allow(@jira).to receive_message_chain("github.pr_title").and_return("Ticket [WEB-123] and WEB-123")
        issues = @jira.find_jira_issues(key: "WEB")
        expect(issues).to eq(["WEB-123"])
      end
    end
  end
end
