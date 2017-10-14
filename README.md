# danger-jira

[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](LICENSE.txt)
[![Gem](https://img.shields.io/gem/v/danger-jira.svg?style=flat)](https://rubygems.org/gems/danger-jira)

A [Danger](https://github.com/danger/danger) plugin for that links JIRA issues to pull requests. Inspired by [danger-plugin-jira-issue](https://github.com/macklinu/danger-plugin-jira-issue)

## Installation

Add this line to your Gemfile:

```rb
gem 'danger-jira'
```

## Usage

```ruby
jira.check(
  key: ["KEY", "PM"],
  url: "https://myjira.atlassian.net/browse"
  fail_on_warning: true
)
```

## License

MIT
