require 'octokit'
require 'sinatra'
require 'sinatra_auth_github'
require 'dotenv'
require 'securerandom'
require 'json'

Dotenv.load

module CommentCard
  class App < Sinatra::Base

    enable :sessions

    set :github_options, {
      :scopes    => "public_repo",
      :secret    => ENV['GITHUB_CLIENT_SECRET'],
      :client_id => ENV['GITHUB_CLIENT_ID'],
    }

    register Sinatra::Auth::Github

    use Rack::Session::Cookie, {
      :http_only => true,
      :secret => ENV['SESSION_SECRET'] || SecureRandom.hex
    }

    configure :production do
      require 'rack-ssl-enforcer'
      use Rack::SslEnforcer
    end

    def user
      env['warden'].user unless env['warden'].nil?
    end

    def guest_token
      ENV['GITHUB_TOKEN']
    end

    def guest_submissions_enabled?
      !guest_token.nil?
    end

    def token
      if user
        user.token
      elsif guest_submissions_enabled?
        guest_token
      end
    end

    def client
      @client ||= Octokit::Client.new :access_token => token
    end

    def render_template(template, locals)
      halt erb template, :layout => :layout, :locals => locals.merge({ :template => template })
    end

    def cache_comment(hash)
      session[:comment] = hash
    end

    def cached_comment
      session[:comment]
    end

    def uncache_comment
      session[:comment] = nil
    end

    def create_issue(owner, repo, title, body, name = nil)
      body += "\n\n(Submitted "
      body += "by **#{name}** " if name
      body += "via [Comment Card](https://github.com/benbalter/comment-card))"
      client.create_issue "#{owner}/#{repo}", title, body
    end

    get '/:owner/:repo/issues/new' do
      if cached_comment #post oauth redirect back to GET route, submit commment
        begin
          issue = create_issue(
            cached_comment[:owner],
            cached_comment[:repo],
            cached_comment[:title],
            cached_comment[:body]
          )
        ensure
          uncache_comment
        end
        render_template :confirmation, {
          :owner => params[:owner],
          :repo  => params[:repo],
          :issue => issue
        }
      end
      render_template :new, {
        :owner                     => params['owner'],
        :repo                      => params["repo"],
        :guest_submissions_enabled => guest_submissions_enabled?
      }
    end

    post '/:owner/:repo/issues/new' do
      if params["type"] == "github"
        cache_comment({
          :repo  => params["repo"],
          :owner => params["owner"],
          :title => params["title"],
          :body  => params["body"]
        })
        authenticate!
      elsif params["type"] == "guest" && guest_submissions_enabled?
        issue = create_issue params["owner"], params["repo"], params["title"], params["body"], params["name"]
        render_template :confirmation, {
          :owner => params[:owner],
          :repo  => params[:repo],
          :issue => issue
        }
      end
    end
  end
end
