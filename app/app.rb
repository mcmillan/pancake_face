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

    def public_upload_path(path)
      absolute_path("public/uploads/#{path}")
    end

    def public_face_path(path)
      absolute_path("public/faces/#{path}")
    end

    def error(message)
      status 422
      { error: message }.to_json
    end

    def gallery_api(method, endpoint, data)
      key    = 'josh'
      secret = 'dfnsdkjfhsky48ry4oh34ry398h'
      epoch  = Time.now.to_i.to_s

      json = {
        APIKEY: key,
        APISECRET: secret,
        data: data.to_json,
        epoch: epoch
      }.to_json
      hash = Digest::SHA256.hexdigest(json)

      entry = HTTParty.send(method, "#{ENV['API_URL']}/api#{endpoint}", {
        query: {
          APIKEY: key,
          hash: hash,
          epoch: epoch
        },
        body: data.to_json,
        headers: {
          'Content-Type' => 'application/json'
        }
      })

      raise entry.parsed_response['message'].to_s if entry.code < 200 or entry.code > 299

      entry.parsed_response
    end

    get '/' do
      erb :index
    end

    get '/detected/:id' do
      id = params[:id].to_i
      
      return pass unless defined?(session[:faces][id]) and defined?(session[:image_id])

      face = session[:faces][id]

      image = MiniMagick::Image.open(public_upload_path("#{session[:image_id]}.jpg"))
      image.combine_options do |i|
        i.crop "#{face.width}x#{face.height}+#{face.coordinates[:top_left][:x]}+#{face.coordinates[:top_left][:y]}"
        i.resize "^200x200"
      end
      content_type :jpeg
      image.to_blob
    end

    post '/detect' do
      image_id           = SecureRandom.uuid
      session[:image_id] = image_id
      path               = tmp_path(image_id)
      public_path        = public_upload_path("#{image_id}.jpg")

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
        Cocaine::CommandLine.new('convert', ':in -resize 1500x1500> :out').run(in: path, out: public_path)
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
      source   = public_upload_path("#{image_id}.jpg")
      sway     = params[:sway].to_i
      pan      = ['jamie', 'superior', 'ingenio'].include?(params[:pan]) ? params[:pan] : 'jamie'

      return error('Unable to find image') if image_id.nil?

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

    post '/gallery' do
      content_type :json

      image_id = session[:image_id]

      return error('An error occurred uploading your selfie. Please try again later.') unless image_id

      begin
        entry = gallery_api(:post, '/entry', {
          content: Base64.encode64(File.read(public_face_path("#{image_id}.jpg")))
        })
      rescue => e
        return error(e.to_s)
      end

      gallery_id           = entry['data']['Id']
      session[:gallery_id] = gallery_id

      { shareURL: "#{ENV['API_URL']}/en/competition/details/#{gallery_id}" }.to_json
    end

    post '/gallery/competition' do
      content_type :json

      name       = params[:name].to_s.strip
      email      = params[:email].to_s.strip
      tos_agreed = params[:tos].to_s == '1'
      image_id   = session[:image_id]
      gallery_id = session[:gallery_id]

      return error('You must supply a name and email.') if name.empty? or email.empty?
      return error('Your name is an invalid format.') unless name =~ /\A([\w\- ]+)\z/ and name.length <= 20
      return error('You must agree to the terms and conditions.') unless tos_agreed
      return error('Invalid email address supplied.') unless email =~ /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/
      return error('An error occurred uploading your selfie. Please try again later.') unless image_id and gallery_id

      begin
        gallery_api(:put, "/entry/#{gallery_id}", {
          name: name,
          email: email
        })
      rescue => e
        return error(e.to_s)
      end

      status 204
    end
  end
end