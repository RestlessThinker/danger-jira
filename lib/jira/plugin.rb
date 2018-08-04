module Danger
  # Links JIRA issues to a pull request.
  #
  # @example Check PR for the following JIRA project keys and links them
  #
  #          jira.check(key: "KEY", url: "https://myjira.atlassian.net/browse")
  #
  # @see  RestlessThinker/danger-jira
  # @tags jira
  #
  class DangerJira < Plugin
    # Checks PR for JIRA keys and links them
    #
    # @param [Array] key
    #         An array of JIRA project keys KEY-123, JIRA-125 etc.
    #
    # @param [String] url
    #         The JIRA url hosted instance.
    #
    # @param [String] emoji
    #         The emoji you want to display in the message.
    #
    # @param [Boolean] search_title
    #         Option to search JIRA issues from PR title
    #
    # @param [Boolean] search_commits
    #         Option to search JIRA issues from commit messages
    #
    # @param [Boolean] fail_on_warning
    #         Option to fail danger if no JIRA issue found
    #
    # @param [Boolean] report_missing
    #         Option to report if no JIRA issue was found
    #
    # @return [void]
    #
    def check(key: nil, url: nil, emoji: ":link:", search_title: true, search_commits: false, fail_on_warning: false, report_missing: true)
      throw Error("'key' missing - must supply JIRA issue key") if key.nil?
      throw Error("'url' missing - must supply JIRA installation URL") if url.nil?

      jira_issues = find_jira_issues(
        key: key,
        search_title: search_title,
        search_commits: search_commits
      )

      if !jira_issues.empty?
        jira_urls = jira_issues.map { |issue| link(href: ensure_url_ends_with_slash(url), issue: issue) }.join(", ")
        message("#{emoji} #{jira_urls}")
      elsif report_missing
        msg = "This PR does not contain any JIRA issue keys in the PR title or commit messages (e.g. KEY-123)"
        if fail_on_warning
          fail(msg)
        else
          warn(msg)
        end
      end
    end

    private

    def find_jira_issues(key: nil, search_title: true, search_commits: false)
      # Support multiple JIRA projects
      keys = key.kind_of?(Array) ? key.join("|") : key
      jira_key_regex_string = "((?:#{keys})-[0-9]+)"
      regexp = Regexp.new(/#{jira_key_regex_string}/)

      jira_issues = []

      if search_title
        github.pr_title.gsub(regexp) do |match|
          jira_issues << match
        end
      end

      if search_commits
        git.commits.map do |commit|
          commit.message.gsub(regexp) do |match|
            jira_issues << match
          end
        end
      end

      if jira_issues.empty?
        github.pr_body.gsub(regexp) do |match|
          jira_issues << match
        end
      end
      return jira_issues
    end

    def ensure_url_ends_with_slash(url)
      return "#{url}/" unless url.end_with?("/")
      return url
    end

    def link(href: nil, issue: nil)
      return "<a href='#{href}#{issue}'>#{issue}</a>"
    end
  end
end
