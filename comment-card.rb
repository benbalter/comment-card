require 'problem_child'
require 'securerandom'
require 'json'

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
  end
end
