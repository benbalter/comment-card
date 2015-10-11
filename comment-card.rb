require 'html/pipeline'
require 'problem_child'
require 'securerandom'
require 'json'
require 'uri'

Dotenv.load

module CommentCard
  class App < Sinatra::Base

    include ProblemChild::Helpers

    configure do
      use Rack::Session::Dalli, cache: ProblemChild::Memcache.client
    end

    set :github_options, {
      :scopes => "public_repo,read:org"
    }

    ENV['WARDEN_GITHUB_VERIFIER_SECRET'] ||= SecureRandom.hex
    register Sinatra::Auth::Github

    enable :sessions
    use Rack::Session::Cookie, {
      :http_only => true,
      :secret => ENV['SESSION_SECRET'] || SecureRandom.hex
    }

    configure :production do
      require 'rack-ssl-enforcer'
      use Rack::SslEnforcer
    end

    configure do
      Octokit.auto_paginate = true
    end

    def host
      @host ||= Addressable::URI.new({
       :scheme => request.scheme,
       :host => request.host,
       :port => (request.port if settings.development?)
      })
    end

    def asset_root
      @asset_root ||= URI.join(host.to_s, "images").to_s
    end

    def pipeline_context
      {
        :gfm => true,
        :asset_root => asset_root
      }
    end

    def pipeline
      @pipeline ||= HTML::Pipeline.new [
        HTML::Pipeline::MarkdownFilter,
        HTML::Pipeline::MentionFilter,
        HTML::Pipeline::AutolinkFilter,
        HTML::Pipeline::EmojiFilter,
        HTML::Pipeline::SyntaxHighlightFilter,
        HTML::Pipeline::SanitizationFilter
      ], pipeline_context
    end

    helpers do
      def render_md(md)
        pipeline.call(md)[:output]
      end
    end

    get '/:owner/:repo/issues/new' do
      if form_data["title"]  #post oauth redirect back to GET route, submit commment
        repo = "#{form_data["owner"]}/#{form_data["repo"]}"
        session["form_data"] = form_data.reject { |k,v| ["owner", "repo"].include?(k) }.to_json
        issue = client.create_issue(repo,form_data["title"],issue_body)
        session[:form_data] = nil
        render_template :confirmation, {
          :owner => params[:owner],
          :repo  => params[:repo],
          :issue => issue
        }
      else
        render_template :new, {
          :owner                     => params['owner'],
          :repo                      => params["repo"],
          :guest_submissions_enabled => anonymous_submissions?,
          :title                     => params["title"],
          :body                      => params["body"],
          :name                      => params["name"]
        }
      end
    end

    post '/:owner/:repo/issues/new' do
      session[:form_data] = params.reject { |k,v| ["type", "captures"].include?(k) }.to_json
      authenticate! if params["type"] == "github"
      halt redirect "#{params["owner"]}/#{params["repo"]}/issues/new"
    end

    get '/:owner/:repo/issues/:issue' do
      repo = "#{params["owner"]}/#{params["repo"]}"
      issue = client.issue repo, params["issue"]
      comments = client.issue_comments repo, params["issue"]
      render_template :issue, {
        :owner    => params["owner"],
        :repo     => params["repo"],
        :issue    => issue,
        :comments => comments,
        :host     => host
      }
    end
  end
end
