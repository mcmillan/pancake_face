module Pancaker
  class App < Sinatra::Base
    # Configure sessions
    enable :sessions
    set :session_secret, ENV['SESSION_SECRET']
    # Ensure we use Puma where available
    set :server, :puma

    # Configure Instagram
    Instagram.configure do |config|
      config.client_id     = ENV['INSTAGRAM_APP_ID']
      config.client_secret = ENV['INSTAGRAM_APP_SECRET']
    end

    configure :development do
      register Sinatra::Reloader
    end

    def absolute_path(path)
      File.expand_path(path)
    end

    def tmp_path(path)
      absolute_path("tmp/uploads/#{path}")
    end

    def public_path(path)
      absolute_path("public/uploads/#{path}")
    end

    get '/' do
      puts absolute_path("ffff")
      erb :index
    end

    post '/detect' do
      image_id           = SecureRandom.uuid
      session[:image_id] = image_id
      path               = tmp_path(image_id)
      public_path        = public_path("#{image_id}.jpg")

      case params[:type]
      when 'facebook', 'instagram'
        Cocaine::CommandLine.new('wget', '-O :out :in').run(out: path, in: params[:url])
      when 'webcam'
        url = Base64.decode64(params[:url].split('data:image/png;base64,').last)
        File.open(path, 'wb') { |f| f.write(url) }
      when 'computer'
        File.open(path, 'wb') { |f| f.write(params[:file][:tempfile].read)}
      end

      begin
        Cocaine::CommandLine.new('convert', ':in :out').run(in: path, out: public_path)
      ensure
        FileUtils.rm_rf(path)
      end

      faces = Detector.new(public_path).detect

      session[:faces] = faces

      content_type :json
      { faces: faces, url: url("/uploads/#{image_id}.jpg") }.to_json
    end

    post '/generate' do
      image_id = session[:image_id]
      face_id  = params[:face].to_i
      face     = session[:faces][face_id]
      source   = public_path("#{image_id}.jpg")
      sway     = params[:sway].to_i
      pan      = ['jamie', 'superior', 'ingenio'].include?(params[:pan]) ? params[:pan] : 'jamie'

      composite = Compositor.new(source, face, pan, sway)

      content_type :json
      {
        file: "/faces/#{image_id}.jpg?#{Time.now.to_i}",
        canDarken: composite.can_darken?,
        canLighten: composite.can_lighten?,
        pan: pan
      }.to_json
    end

    get '/auth/instagram' do
      redirect Instagram.authorize_url(redirect_uri: url('/auth/instagram/callback'))
    end

    get '/auth/instagram/callback' do
      code_response = Instagram.get_access_token(params[:code], redirect_uri: url('/auth/instagram/callback'))
      client        = Instagram.client(access_token: code_response.access_token)
      media         = client.user_recent_media.map { |m| m['images']['standard_resolution']['url'] }

      "<script>window.opener.Pancake.InstagramPicker.popupCallback(#{media.to_json}); window.close();</script>"
    end
  end
end