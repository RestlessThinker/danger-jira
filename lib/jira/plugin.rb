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
    # @param [Boolean] fail_on_warning
    #         Option to fail danger if no JIRA issue found in PR title
    #
    # @return [void]
    #
    def check(key: nil, url: nil, emoji: ":link:", fail_on_warning: false)
      throw Error("'key' missing - must supply JIRA issue key") if key.nil?
      throw Error("'url' missing - must supply JIRA installation URL") if url.nil?

      # Support multiple JIRA projects
      keys = key.kind_of?(Array) ? key.join("|") : key
      jira_key_regex_string = "((#{keys})-[0-9]+)"
      regexp = Regexp.new(/#{jira_key_regex_string}/)

      jira_issues = []
      github.pr_title.gsub(regexp) do |match|
        jira_issues << match
      end

      if jira_issues.empty?
        github.pr_body.gsub(regexp) do |match|
          jira_issues << match
        end
      end

      if !jira_issues.empty?
        jira_urls = jira_issues.map { |issue| link(href: ensure_url_ends_with_slash(url), issue: issue) }.join(", ")
        message("#{emoji} #{jira_urls}")
      else
        msg = "This PR does not contain a JIRA issue key in the PR title (e.g. KEY-123)"
        if fail_on_warning
          fail(msg)
        else
          warn(msg)
        end
      end
    end

    private

    def ensure_url_ends_with_slash(url)
      return "#{url}/" unless url.end_with?("/")
      return url
    end

    def link(href: nil, issue: nil)
      return "<a href='#{href}#{issue}'>#{issue}</a>"
    end
  end
end
